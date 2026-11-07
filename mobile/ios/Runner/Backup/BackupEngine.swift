import BackgroundTasks
import CryptoKit
import Foundation
import Network
import Photos
import UIKit

/// Backs up the photo library through a background URLSession, which iOS keeps running after the
/// app is suspended. Exporting files and starting transfers needs the app to be awake, so it runs
/// whenever iOS wakes it: when a transfer ends, or through background tasks.
/// A photo album on the device.
struct BackupAlbum: Equatable {
  let id: String
  let title: String
  let count: Int
}

enum BackupAlbumFinder {
  /// The chosen album, or the one with the typed name if it was renamed or recreated.
  /// Nil means no album: nothing is sent, and it never falls back to the whole library.
  static func find(id: String?, name: String?, in albums: [BackupAlbum]) -> BackupAlbum? {
    if let id, let match = albums.first(where: { $0.id == id }) { return match }
    guard let wanted = normalize(name), !wanted.isEmpty else { return nil }
    return albums.first { normalize($0.title) == wanted }
  }

  private static func normalize(_ value: String?) -> String? {
    value?.trimmingCharacters(in: .whitespacesAndNewlines)
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
  }
}

final class BackupEngine: NSObject {
  static let shared = BackupEngine()

  static let refreshTaskID = "app.mediarr.backup.refresh"
  static let processingTaskID = "app.mediarr.backup.processing"
  private static let sessionID = "app.mediarr.backup"
  private static let maxQueued = 6
  private static let maxAttempts = 5
  private static let checkInterval: TimeInterval = 60

  private enum Keys {
    static let enabled = "backup.enabled"
    static let server = "backup.server"
    static let wifiOnly = "backup.wifiOnly"
    static let chargingOnly = "backup.chargingOnly"
    static let albumID = "backup.albumID"
    static let albumName = "backup.albumName"
    static let moreAlbums = "backup.moreAlbums"
    static let excludedAlbums = "backup.excludedAlbums"
    static let onlyNewPending = "backup.onlyNewPending"
    static let unauthorized = "backup.unauthorized"
    static let deviceID = "backup.deviceID"
    static let deviceName = "backup.deviceName"
    static let lastReport = "backup.lastReport"
  }

  private let queue = DispatchQueue(label: "app.mediarr.backup")
  private let defaults = UserDefaults.standard
  private let pathMonitor = NWPathMonitor()
  private var networkIsCheap = true
  private var exporting = 0
  private var pendingChecks = 0
  private var observing = false
  private var recovered = false
  private var idleHandlers: [() -> Void] = []
  private var store: BackupStore?
  private var timer: DispatchSourceTimer?
  private let checkSession = URLSession(configuration: .ephemeral)

  var backgroundCompletion: (() -> Void)?

  private lazy var session: URLSession = {
    let configuration = URLSessionConfiguration.background(withIdentifier: BackupEngine.sessionID)
    configuration.sessionSendsLaunchEvents = true
    configuration.isDiscretionary = false
    configuration.allowsCellularAccess = true
    configuration.timeoutIntervalForResource = 7 * 24 * 60 * 60
    return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
  }()

  private override init() {
    super.init()
    pathMonitor.pathUpdateHandler = { [weak self] path in
      self?.queue.async { self?.networkIsCheap = !path.isExpensive }
    }
    pathMonitor.start(queue: queue)
  }

  private var folder: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let url = base.appendingPathComponent("backup", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  private var temporaryFolder: URL {
    let url = folder.appendingPathComponent("transfers", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  private func openStore() -> BackupStore? {
    if let store { return store }
    store = try? BackupStore(path: folder.appendingPathComponent("state.sqlite").path)
    return store
  }

  private var enabled: Bool { defaults.bool(forKey: Keys.enabled) }
  private var wifiOnly: Bool { defaults.object(forKey: Keys.wifiOnly) as? Bool ?? true }
  private var moreAlbums: [String] { defaults.stringArray(forKey: Keys.moreAlbums) ?? [] }
  private var excludedAlbums: [String] { defaults.stringArray(forKey: Keys.excludedAlbums) ?? [] }
  private var chargingOnly: Bool { defaults.bool(forKey: Keys.chargingOnly) }
  private var pluggedIn = false
  private var paused: Bool { defaults.bool(forKey: Keys.unauthorized) }

  /// This phone among the devices the server lists. Made up once, and kept when backup is off.
  private var deviceID: String {
    if let id = defaults.string(forKey: Keys.deviceID) { return id }
    let id = UUID().uuidString.lowercased()
    defaults.set(id, forKey: Keys.deviceID)
    return id
  }

  private var deviceName: String { defaults.string(forKey: Keys.deviceName) ?? "iPhone" }
  private static let reportEvery: TimeInterval = 60 * 60

  // MARK: Starting and stopping

  /// Called at launch, including when iOS launches the app in the background.
  func activate() {
    _ = session
    watchBattery()
    queue.async { [self] in
      guard enabled else { return }
      // An older version could back up everything. Without a chosen album, nothing may be sent.
      guard
        defaults.string(forKey: Keys.albumID) != nil || defaults.string(forKey: Keys.albumName) != nil
          || !moreAlbums.isEmpty
      else {
        stopSending()
        return
      }
      startObserving()
      startTimer()
      recoverThenWork()
    }
    scheduleBackgroundWork()
  }

  /// Looks for new photos every minute, for as long as iOS lets the app run.
  private func startTimer() {
    guard timer == nil else { return }
    let source = DispatchSource.makeTimerSource(queue: queue)
    source.schedule(
      deadline: .now() + BackupEngine.checkInterval, repeating: BackupEngine.checkInterval, leeway: .seconds(5))
    source.setEventHandler { [weak self] in
      self?.scan()
      self?.pump()
    }
    source.resume()
    timer = source
  }

  private func stopSending() {
    timer?.cancel()
    timer = nil
    defaults.set(false, forKey: Keys.enabled)
    openStore()?.forgetUnfinished()
    if observing {
      PHPhotoLibrary.shared().unregisterChangeObserver(self)
      observing = false
    }
    session.getAllTasks { tasks in tasks.forEach { $0.cancel() } }
    BGTaskScheduler.shared.cancelAllTaskRequests()
    BackupKeychain.delete()
  }

  func enable(
    server: String, key: String, wifiOnly: Bool, onlyNew: Bool, albumID: String?, albumName: String
  ) {
    BackupKeychain.save(key)
    queue.async { [self] in
      defaults.set(server, forKey: Keys.server)
      defaults.set(wifiOnly, forKey: Keys.wifiOnly)
      defaults.set(true, forKey: Keys.enabled)
      defaults.set(false, forKey: Keys.unauthorized)
      startObserving()
      startTimer()
      choose(albumID: albumID, albumName: albumName, onlyNew: onlyNew)
    }
    scheduleBackgroundWork()
  }

  /// Switching album stops whatever the old album had queued, before anything new starts.
  func setAlbum(albumID: String?, albumName: String, onlyNew: Bool) {
    queue.async { [self] in choose(albumID: albumID, albumName: albumName, onlyNew: onlyNew) }
  }

  private func choose(albumID: String?, albumName: String, onlyNew: Bool) {
    defaults.set(albumID, forKey: Keys.albumID)
    defaults.set(albumName, forKey: Keys.albumName)
    defaults.set(onlyNew, forKey: Keys.onlyNewPending)
    openStore()?.forgetUnfinished()
    session.getAllTasks { [self] tasks in
      tasks.forEach { $0.cancel() }
      queue.async { [self] in recoverThenWork() }
    }
  }

  /// For each chosen album, the checksums of its photos that are safely on the server.
  func albumChecksums(reply: @escaping ([[String: Any]]) -> Void) {
    queue.async { [self] in
      guard let store = openStore() else { return reply([]) }
      let verified = store.verifiedChecksums()
      let all = loadAlbums()
      let excluded = excludedAlbums
      let chosen = ([currentAlbum()?.id].compactMap { $0 } + moreAlbums).filter {
        !excluded.contains($0)
      }
      reply(
        Array(Set(chosen)).compactMap { id in
          guard let album = all.first(where: { $0.id == id }) else { return nil }
          return [
            "title": album.title,
            "checksums": assets(inAlbums: [id]).flatMap { verified[$0.id] ?? [] },
          ]
        })
    }
  }

  /// More albums beside the chosen one, and albums whose photos are never sent.
  func setAlbumLists(more: [String], excluded: [String], onlyNew: Bool) {
    queue.async { [self] in
      let added = Set(more).subtracting(moreAlbums)
      defaults.set(more, forKey: Keys.moreAlbums)
      defaults.set(excluded, forKey: Keys.excludedAlbums)
      if onlyNew, let store = openStore() {
        store.addSkipped(assets(inAlbums: Array(added)).map(\.id))
      }
      openStore()?.forgetUnfinished()
      session.getAllTasks { [self] tasks in
        tasks.forEach { $0.cancel() }
        queue.async { [self] in recoverThenWork() }
      }
    }
  }

  private func assets(inAlbums ids: [String]) -> [(id: String, created: Date)] {
    guard !ids.isEmpty else { return [] }
    var found: [(id: String, created: Date)] = []
    var seen = Set<String>()
    PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: ids, options: nil)
      .enumerateObjects { collection, _, _ in
        PHAsset.fetchAssets(in: collection, options: nil).enumerateObjects { asset, _, _ in
          guard asset.mediaType == .image || asset.mediaType == .video,
            seen.insert(asset.localIdentifier).inserted
          else { return }
          found.append((asset.localIdentifier, asset.creationDate ?? Date(timeIntervalSince1970: 0)))
        }
      }
    return found
  }

  func disable() {
    queue.async { [self] in
      defaults.removeObject(forKey: Keys.albumID)
      defaults.removeObject(forKey: Keys.albumName)
      defaults.removeObject(forKey: Keys.moreAlbums)
      defaults.removeObject(forKey: Keys.excludedAlbums)
      defaults.removeObject(forKey: Keys.onlyNewPending)
      stopSending()
    }
  }

  /// The user's own albums.
  private func loadAlbums(counting: Bool = false) -> [BackupAlbum] {
    let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
    var albums: [BackupAlbum] = []
    collections.enumerateObjects { collection, _, _ in
      guard let title = collection.localizedTitle else { return }
      albums.append(
        BackupAlbum(
          id: collection.localIdentifier, title: title,
          count: counting ? PHAsset.fetchAssets(in: collection, options: nil).count : 0))
    }
    return albums.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
  }

  func albums(reply: @escaping ([[String: Any]]) -> Void) {
    queue.async { [self] in
      reply(loadAlbums(counting: true).map { ["id": $0.id, "title": $0.title, "count": $0.count] })
    }
  }

  /// UIDevice belongs to the main thread, so the engine keeps its own copy of the answer.
  private func watchBattery() {
    DispatchQueue.main.async { [self] in
      UIDevice.current.isBatteryMonitoringEnabled = true
      self.defaults.set(UIDevice.current.name, forKey: Keys.deviceName)
      NotificationCenter.default.addObserver(
        forName: UIDevice.batteryStateDidChangeNotification, object: nil, queue: .main
      ) { [weak self] _ in self?.readBattery() }
      readBattery()
    }
  }

  private func readBattery() {
    let state = UIDevice.current.batteryState
    let plugged = state == .charging || state == .full
    queue.async { [self] in
      pluggedIn = plugged
      pump()
    }
  }

  func setServer(_ value: String) {
    queue.async { [self] in
      defaults.set(value, forKey: Keys.server)
      pump()
    }
  }

  func setChargingOnly(_ value: Bool) {
    queue.async { [self] in
      defaults.set(value, forKey: Keys.chargingOnly)
      scheduleBackgroundWork()
      pump()
    }
  }

  func setWifiOnly(_ value: Bool) {
    queue.async { [self] in
      defaults.set(value, forKey: Keys.wifiOnly)
      pump()
    }
  }

  func retryFailed() {
    queue.async { [self] in
      openStore()?.retryFailed()
      pump()
    }
  }

  private func startObserving() {
    guard !observing, PHPhotoLibrary.authorizationStatus(for: .readWrite) != .notDetermined else {
      return
    }
    PHPhotoLibrary.shared().register(self)
    observing = true
  }

  /// Reattaches to the transfers iOS kept running, then continues with the rest.
  private func recoverThenWork() {
    session.getAllTasks { [self] tasks in
      queue.async { [self] in
        let active = Set(tasks.compactMap { TaskInfo(description: $0.taskDescription)?.key })
        openStore()?.recoverInterrupted(activeKeys: active)
        if !recovered {
          removeStrayFiles(tasks: tasks)
          recovered = true
        }
        scan()
        pump()
      }
    }
  }

  private func removeStrayFiles(tasks: [URLSessionTask]) {
    let inUse = Set(tasks.compactMap { TaskInfo(description: $0.taskDescription)?.path })
    let files =
      (try? FileManager.default.contentsOfDirectory(at: temporaryFolder, includingPropertiesForKeys: nil))
      ?? []
    for file in files where !inUse.contains(file.path) {
      try? FileManager.default.removeItem(at: file)
    }
  }

  // MARK: Finding photos

  private func currentAlbum() -> BackupAlbum? {
    BackupAlbumFinder.find(
      id: defaults.string(forKey: Keys.albumID),
      name: defaults.string(forKey: Keys.albumName),
      in: loadAlbums())
  }

  /// Only the chosen album. Without one there is nothing to scan, ever.
  private func scan() {
    guard enabled, let store = openStore() else { return }
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    guard status == .authorized || status == .limited else { return }
    let album = currentAlbum()
    if let album { defaults.set(album.id, forKey: Keys.albumID) }
    let excluded = excludedAlbums
    let chosen = ([album?.id].compactMap { $0 } + moreAlbums).filter { !excluded.contains($0) }
    guard !chosen.isEmpty else {
      store.forgetPending(notIn: [])
      return
    }
    let never = Set(assets(inAlbums: excluded).map(\.id))
    let found = assets(inAlbums: chosen).filter { !never.contains($0.id) }
    if defaults.bool(forKey: Keys.onlyNewPending) {
      // What is in the album right now stays on the device. Only what is added later is sent.
      store.addSkipped(found.map(\.id))
      defaults.set(false, forKey: Keys.onlyNewPending)
    }
    store.forgetPending(notIn: Set(found.map(\.id)))
    store.add(found)
  }

  // MARK: Sending

  /// Starts more transfers, while the queue has room. Called whenever anything finishes.
  private func pump() {
    guard enabled, !paused, !chargingOnly || pluggedIn else {
      finishIfIdle()
      return
    }
    session.getAllTasks { [self] tasks in
      queue.async { [self] in
        guard let store = openStore() else { return }
        var room = BackupEngine.maxQueued - tasks.count - exporting - pendingChecks
        while room > 0, let item = store.nextPending() {
          store.setStatus(.exporting, assetID: item.assetID, part: item.part)
          exporting += 1
          room -= 1
          export(item)
        }
        checkInIfDue()
        finishIfIdle()
      }
    }
  }

  /// Tells the server how this phone's backup is doing, at most once an hour, also when there is
  /// nothing to send: a phone that stops doing so is the one its owner is warned about. The
  /// checksums of what is safe are given by the app when it is open; this keeps them as they are.
  private func checkInIfDue() {
    guard enabled, !paused,
      Date().timeIntervalSince1970 - defaults.double(forKey: Keys.lastReport)
        >= BackupEngine.reportEvery,
      let server = defaults.string(forKey: Keys.server),
      let key = BackupKeychain.read(),
      let url = URL(string: server + "/api/me/backup-devices/" + deviceID)
    else { return }
    let counts = openStore()?.counts() ?? [:]
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let body: [String: Any] = [
      "name": deviceName, "platform": "ios", "appVersion": version,
      "pending": counts["pending"] ?? 0,
      "working": (counts["exporting"] ?? 0) + (counts["uploading"] ?? 0),
      "verified": counts["verified"] ?? 0,
      "failed": counts["failed"] ?? 0,
    ]
    guard let data = try? JSONSerialization.data(withJSONObject: body) else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.timeoutInterval = 20
    request.allowsCellularAccess = !wifiOnly
    request.setValue(key, forHTTPHeaderField: "X-Api-Key")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = data
    // Marked first, so that a slow answer does not start a second report.
    let started = Date().timeIntervalSince1970
    defaults.set(started, forKey: Keys.lastReport)
    checkSession.dataTask(with: request) { [weak self] _, response, _ in
      guard (response as? HTTPURLResponse)?.statusCode != 200 else { return }
      // Not taken: the next pump tries again.
      self?.queue.async { self?.defaults.set(0, forKey: Keys.lastReport) }
    }.resume()
  }

  private func finishIfIdle() {
    guard exporting == 0, pendingChecks == 0, !idleHandlers.isEmpty else { return }
    let handlers = idleHandlers
    idleHandlers = []
    handlers.forEach { $0() }
  }

  private func export(_ item: BackupItem) {
    let finish = { [self] in
      exporting -= 1
      finishIfIdle()
    }
    var keepAwake = UIBackgroundTaskIdentifier.invalid
    keepAwake = UIApplication.backgroundTaskStart(name: "backup-export") {
      UIApplication.backgroundTaskEnd(keepAwake)
    }
    let done = { [self] in
      queue.async {
        finish()
        self.pump()
        UIApplication.backgroundTaskEnd(keepAwake)
      }
    }

    guard
      let asset = PHAsset.fetchAssets(withLocalIdentifiers: [item.assetID], options: nil).firstObject
    else {
      openStore()?.setStatus(
        .failed, assetID: item.assetID, part: item.part, error: "This item is no longer on the device.")
      done()
      return
    }

    let resources = PHAssetResource.assetResources(for: asset)
    guard let resource = BackupEngine.resource(in: resources, part: item.part, asset: asset) else {
      openStore()?.setStatus(
        .failed, assetID: item.assetID, part: item.part, error: "This item has no original file.")
      done()
      return
    }
    // A Live Photo also sends its video, as a separate file on the server.
    if item.part == BackupPart.main, resources.contains(where: { $0.type == .pairedVideo }) {
      openStore()?.add(
        [(item.assetID, asset.creationDate ?? Date(timeIntervalSince1970: 0))],
        part: BackupPart.paired)
    }

    let file = temporaryFolder.appendingPathComponent(
      UUID().uuidString + "." + (resource.originalFilename as NSString).pathExtension)
    let options = PHAssetResourceRequestOptions()
    // Downloading from iCloud counts as using the network, so it obeys the Wi-Fi setting.
    options.isNetworkAccessAllowed = !wifiOnly || networkIsCheap

    PHAssetResourceManager.default().writeData(for: resource, toFile: file, options: options) {
      [self] error in
      queue.async { [self] in
        if let error {
          try? FileManager.default.removeItem(at: file)
          openStore()?.recordFailure(
            assetID: item.assetID, part: item.part,
            error: "The file could not be read from the device: \(error.localizedDescription)",
            limit: BackupEngine.maxAttempts)
          done()
          return
        }
        send(item, file: file, name: resource.originalFilename, created: asset.creationDate)
        done()
      }
    }
  }

  private static func resource(
    in resources: [PHAssetResource], part: String, asset: PHAsset
  ) -> PHAssetResource? {
    if part == BackupPart.paired {
      return resources.first { $0.type == .pairedVideo }
    }
    // The original, not an edited copy: originals are never changed.
    let wanted: [PHAssetResourceType] =
      asset.mediaType == .video ? [.video, .fullSizeVideo] : [.photo, .fullSizePhoto, .alternatePhoto]
    for type in wanted {
      if let match = resources.first(where: { $0.type == type }) { return match }
    }
    return resources.first
  }

  private func send(_ item: BackupItem, file: URL, name: String, created: Date?) {
    // The album may have changed while the file was being read.
    guard openStore()?.isExporting(assetID: item.assetID, part: item.part) == true else {
      try? FileManager.default.removeItem(at: file)
      return
    }
    guard
      let server = defaults.string(forKey: Keys.server),
      let key = BackupKeychain.read(),
      let size = (try? FileManager.default.attributesOfItem(atPath: file.path)[.size]) as? NSNumber,
      let checksum = BackupEngine.sha256(of: file),
      let request = BackupRequest.make(
        server: server, key: key, fileName: name, size: size.int64Value, checksum: checksum,
        created: created, allowsCellular: !wifiOnly)
    else {
      try? FileManager.default.removeItem(at: file)
      openStore()?.recordFailure(
        assetID: item.assetID, part: item.part, error: "The upload could not be prepared.",
        limit: BackupEngine.maxAttempts)
      return
    }
    openStore()?.setChecksum(checksum, assetID: item.assetID, part: item.part)
    // A file already on the server is not sent again, which also saves the data.
    pendingChecks += 1
    let finishCheck: (Bool) -> Void = { [self] exists in
      queue.async { [self] in
        pendingChecks -= 1
        defer { finishIfIdle() }
        guard openStore()?.isExporting(assetID: item.assetID, part: item.part) == true else {
          try? FileManager.default.removeItem(at: file)
          return
        }
        if exists {
          try? FileManager.default.removeItem(at: file)
          openStore()?.markVerified(assetID: item.assetID, part: item.part, remoteID: nil)
          pump()
          return
        }
        let task = session.uploadTask(with: request, fromFile: file)
        task.taskDescription =
          TaskInfo(assetID: item.assetID, part: item.part, path: file.path).description
        openStore()?.setStatus(.uploading, assetID: item.assetID, part: item.part)
        task.resume()
      }
    }
    guard let check = BackupRequest.check(
      server: server, key: key, checksum: checksum, allowsCellular: !wifiOnly)
    else {
      finishCheck(false)
      return
    }
    checkSession.dataTask(with: check) { data, response, _ in
      finishCheck(
        BackupRequest.serverHasFile(
          status: (response as? HTTPURLResponse)?.statusCode ?? 0, body: data, checksum: checksum))
    }.resume()
  }

  /// Streams through the file, because a video can be far larger than the available memory.
  static func sha256(of file: URL) -> String? {
    guard let handle = try? FileHandle(forReadingFrom: file) else { return nil }
    defer { try? handle.close() }
    var hasher = SHA256()
    while true {
      // Reading at the end of a file returns nil or empty data, depending on the iOS version.
      let finished: Bool? = autoreleasepool {
        do {
          guard let chunk = try handle.read(upToCount: 1024 * 1024), !chunk.isEmpty else {
            return true
          }
          hasher.update(data: chunk)
          return false
        } catch {
          return nil
        }
      }
      guard let finished else { return nil }
      if finished { break }
    }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
  }

  // MARK: Status for the interface

  func status(reply: @escaping ([String: Any]) -> Void) {
    queue.async { [self] in
      let counts = openStore()?.counts() ?? [:]
      var out: [String: Any] = [
        "enabled": enabled,
        "wifiOnly": wifiOnly,
        "chargingOnly": chargingOnly,
        "unauthorized": paused,
        "pending": counts["pending"] ?? 0,
        "working": (counts["exporting"] ?? 0) + (counts["uploading"] ?? 0),
        "verified": counts["verified"] ?? 0,
        "failed": counts["failed"] ?? 0,
        "failures": openStore()?.failures(limit: 20) ?? [],
        "albumName": defaults.string(forKey: Keys.albumName) ?? "",
        "albumFound": currentAlbum() != nil || !moreAlbums.isEmpty,
        "moreAlbums": moreAlbums,
        "excludedAlbums": excludedAlbums,
        "limitedAccess": PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited,
        "deviceId": deviceID,
        "deviceName": deviceName,
      ]
      if let last = openStore()?.lastFinished() {
        out["lastFinished"] = last
      }
      reply(out)
    }
  }

  func verifiedChecksums(reply: @escaping ([String: [String]]) -> Void) {
    queue.async { [self] in
      reply(openStore()?.verifiedChecksums() ?? [:])
    }
  }

  func waiting(limit: Int, reply: @escaping ([[String: String]]) -> Void) {
    queue.async { [self] in
      reply(openStore()?.waiting(limit: limit) ?? [])
    }
  }

  func statuses(ids: [String], reply: @escaping ([String: String]) -> Void) {
    queue.async { [self] in
      reply(openStore()?.statuses(assetIDs: ids) ?? [:])
    }
  }

  // MARK: Background work

  func registerBackgroundTasks() {
    for id in [BackupEngine.refreshTaskID, BackupEngine.processingTaskID] {
      BGTaskScheduler.shared.register(forTaskWithIdentifier: id, using: nil) { [weak self] task in
        self?.handle(task)
      }
    }
  }

  func scheduleBackgroundWork() {
    guard defaults.bool(forKey: Keys.enabled) else { return }
    let refresh = BGAppRefreshTaskRequest(identifier: BackupEngine.refreshTaskID)
    // A request, not a promise: iOS decides the real time, usually much later.
    refresh.earliestBeginDate = Date(timeIntervalSinceNow: BackupEngine.checkInterval)
    try? BGTaskScheduler.shared.submit(refresh)

    let processing = BGProcessingTaskRequest(identifier: BackupEngine.processingTaskID)
    processing.requiresNetworkConnectivity = true
    processing.requiresExternalPower = chargingOnly
    processing.earliestBeginDate = Date(timeIntervalSinceNow: BackupEngine.checkInterval)
    try? BGTaskScheduler.shared.submit(processing)
  }

  private func handle(_ task: BGTask) {
    scheduleBackgroundWork()
    let state = TaskCompletion(task)
    task.expirationHandler = { state.finish(success: false) }
    queue.async { [self] in
      idleHandlers.append { state.finish(success: true) }
      startObserving()
      startTimer()
      recoverThenWork()
    }
  }
}

/// A background task must be completed exactly once.
private final class TaskCompletion {
  private let task: BGTask
  private let lock = NSLock()
  private var finished = false

  init(_ task: BGTask) {
    self.task = task
  }

  func finish(success: Bool) {
    lock.lock()
    defer { lock.unlock() }
    guard !finished else { return }
    finished = true
    task.setTaskCompleted(success: success)
  }
}

/// Stored on the transfer, which outlives the process.
struct TaskInfo {
  let assetID: String
  let part: String
  let path: String

  init(assetID: String, part: String, path: String) {
    self.assetID = assetID
    self.part = part
    self.path = path
  }

  init?(description: String?) {
    guard let parts = description?.components(separatedBy: "\n"), parts.count == 3 else {
      return nil
    }
    self.init(assetID: parts[0], part: parts[1], path: parts[2])
  }

  var description: String { [assetID, part, path].joined(separator: "\n") }
  var key: String { BackupStore.key(assetID, part) }
}

extension UIApplication {
  /// `UIApplication.shared` may only be touched on the main thread.
  fileprivate static func backgroundTaskStart(
    name: String, expired: @escaping () -> Void
  ) -> UIBackgroundTaskIdentifier {
    let start = { shared.beginBackgroundTask(withName: name, expirationHandler: expired) }
    return Thread.isMainThread ? start() : DispatchQueue.main.sync(execute: start)
  }

  fileprivate static func backgroundTaskEnd(_ id: UIBackgroundTaskIdentifier) {
    guard id != .invalid else { return }
    DispatchQueue.main.async { shared.endBackgroundTask(id) }
  }
}

extension BackupEngine: URLSessionDataDelegate {
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    queue.async { [self] in
      guard let info = TaskInfo(description: task.taskDescription), let store = openStore() else {
        return
      }
      try? FileManager.default.removeItem(atPath: info.path)

      if let error {
        let code = (error as? URLError)?.code
        // A cancelled transfer may belong to an album no longer chosen, so the next scan decides.
        if code == .cancelled {
          store.forgetCancelled(assetID: info.assetID, part: info.part)
          scan()
        } else if code == .networkConnectionLost || code == .notConnectedToInternet {
          // Not the file's fault: it simply goes back in the queue.
          store.setStatus(.pending, assetID: info.assetID, part: info.part)
        } else {
          store.recordFailure(
            assetID: info.assetID, part: info.part, error: error.localizedDescription,
            limit: BackupEngine.maxAttempts)
        }
        pump()
        return
      }

      let response = task.response as? HTTPURLResponse
      let outcome = BackupRequest.outcome(
        status: response?.statusCode ?? 0,
        assetID: response?.value(forHTTPHeaderField: "X-Asset-Id"))
      switch outcome {
      case .verified(let remoteID):
        store.markVerified(assetID: info.assetID, part: info.part, remoteID: remoteID)
      case .retry(let message):
        store.recordFailure(
          assetID: info.assetID, part: info.part, error: message, limit: BackupEngine.maxAttempts)
      case .rejected(let message):
        store.setStatus(.failed, assetID: info.assetID, part: info.part, error: message)
      case .unauthorized:
        defaults.set(true, forKey: Keys.unauthorized)
        store.setStatus(.pending, assetID: info.assetID, part: info.part)
      }
      pump()
    }
  }

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    DispatchQueue.main.async { [self] in
      backgroundCompletion?()
      backgroundCompletion = nil
    }
  }
}

extension BackupEngine: PHPhotoLibraryChangeObserver {
  func photoLibraryDidChange(_ changeInstance: PHChange) {
    queue.async { [self] in
      scan()
      pump()
    }
  }
}
