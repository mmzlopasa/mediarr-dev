import BackgroundTasks
import CryptoKit
import Foundation
import Network
import Photos
import UIKit

/// Backs up the photo library through a background URLSession, which iOS keeps running after the
/// app is suspended. Exporting files and starting transfers needs the app to be awake, so it runs
/// whenever iOS wakes it: when a transfer ends, or through background tasks.
final class BackupEngine: NSObject {
  static let shared = BackupEngine()

  static let refreshTaskID = "app.mediarr.backup.refresh"
  static let processingTaskID = "app.mediarr.backup.processing"
  private static let sessionID = "app.mediarr.backup"
  private static let maxQueued = 6
  private static let maxAttempts = 5

  private enum Keys {
    static let enabled = "backup.enabled"
    static let server = "backup.server"
    static let wifiOnly = "backup.wifiOnly"
    static let since = "backup.since"
    static let unauthorized = "backup.unauthorized"
  }

  private let queue = DispatchQueue(label: "app.mediarr.backup")
  private let defaults = UserDefaults.standard
  private let pathMonitor = NWPathMonitor()
  private var networkIsCheap = true
  private var exporting = 0
  private var observing = false
  private var recovered = false
  private var idleHandlers: [() -> Void] = []
  private var store: BackupStore?

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
  private var paused: Bool { defaults.bool(forKey: Keys.unauthorized) }

  // MARK: Starting and stopping

  /// Called at launch, including when iOS launches the app in the background.
  func activate() {
    _ = session
    queue.async { [self] in
      guard enabled else { return }
      startObserving()
      recoverThenWork()
    }
    scheduleBackgroundWork()
  }

  func enable(server: String, key: String, wifiOnly: Bool, onlyNew: Bool) {
    BackupKeychain.save(key)
    queue.async { [self] in
      defaults.set(server, forKey: Keys.server)
      defaults.set(wifiOnly, forKey: Keys.wifiOnly)
      defaults.set(true, forKey: Keys.enabled)
      defaults.set(false, forKey: Keys.unauthorized)
      if defaults.object(forKey: Keys.since) == nil || onlyNew {
        defaults.set(onlyNew ? Date().timeIntervalSince1970 : 0, forKey: Keys.since)
      }
      startObserving()
      recoverThenWork()
    }
    scheduleBackgroundWork()
  }

  func disable() {
    BackupKeychain.delete()
    queue.async { [self] in
      defaults.set(false, forKey: Keys.enabled)
      defaults.removeObject(forKey: Keys.since)
      if observing {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        observing = false
      }
    }
    session.getAllTasks { tasks in tasks.forEach { $0.cancel() } }
    BGTaskScheduler.shared.cancelAllTaskRequests()
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

  private func scan() {
    guard enabled, let store = openStore() else { return }
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    guard status == .authorized || status == .limited else { return }

    let options = PHFetchOptions()
    options.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced]
    let since = defaults.double(forKey: Keys.since)
    if since > 0 {
      options.predicate = NSPredicate(
        format: "creationDate >= %@", Date(timeIntervalSince1970: since) as NSDate)
    }
    let result = PHAsset.fetchAssets(with: options)
    var found: [(id: String, created: Date)] = []
    found.reserveCapacity(result.count)
    result.enumerateObjects { asset, _, _ in
      if asset.mediaType == .image || asset.mediaType == .video {
        found.append((asset.localIdentifier, asset.creationDate ?? Date(timeIntervalSince1970: 0)))
      }
    }
    store.add(found)
  }

  // MARK: Sending

  /// Starts more transfers, while the queue has room. Called whenever anything finishes.
  private func pump() {
    guard enabled, !paused else {
      finishIfIdle()
      return
    }
    session.getAllTasks { [self] tasks in
      queue.async { [self] in
        guard let store = openStore() else { return }
        var room = BackupEngine.maxQueued - tasks.count - exporting
        while room > 0, let item = store.nextPending() {
          store.setStatus(.exporting, assetID: item.assetID, part: item.part)
          exporting += 1
          room -= 1
          export(item)
        }
        finishIfIdle()
      }
    }
  }

  private func finishIfIdle() {
    guard exporting == 0, !idleHandlers.isEmpty else { return }
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
    let task = session.uploadTask(with: request, fromFile: file)
    task.taskDescription = TaskInfo(assetID: item.assetID, part: item.part, path: file.path).description
    openStore()?.setStatus(.uploading, assetID: item.assetID, part: item.part)
    task.resume()
  }

  /// Streams through the file, because a video can be far larger than the available memory.
  static func sha256(of file: URL) -> String? {
    guard let handle = try? FileHandle(forReadingFrom: file) else { return nil }
    defer { try? handle.close() }
    var hasher = SHA256()
    while true {
      let done: Bool? = autoreleasepool {
        guard let chunk = try? handle.read(upToCount: 1024 * 1024) else { return nil }
        if chunk.isEmpty { return true }
        hasher.update(data: chunk)
        return false
      }
      guard let done else { return nil }
      if done { break }
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
        "unauthorized": paused,
        "pending": counts["pending"] ?? 0,
        "working": (counts["exporting"] ?? 0) + (counts["uploading"] ?? 0),
        "verified": counts["verified"] ?? 0,
        "failed": counts["failed"] ?? 0,
        "failures": openStore()?.failures(limit: 20) ?? [],
      ]
      if let last = openStore()?.lastFinished() {
        out["lastFinished"] = last
      }
      reply(out)
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
    refresh.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    try? BGTaskScheduler.shared.submit(refresh)

    let processing = BGProcessingTaskRequest(identifier: BackupEngine.processingTaskID)
    processing.requiresNetworkConnectivity = true
    processing.requiresExternalPower = false
    processing.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
    try? BGTaskScheduler.shared.submit(processing)
  }

  private func handle(_ task: BGTask) {
    scheduleBackgroundWork()
    let state = TaskCompletion(task)
    task.expirationHandler = { state.finish(success: false) }
    queue.async { [self] in
      idleHandlers.append { state.finish(success: true) }
      startObserving()
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
        if code == .cancelled || code == .networkConnectionLost || code == .notConnectedToInternet {
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
