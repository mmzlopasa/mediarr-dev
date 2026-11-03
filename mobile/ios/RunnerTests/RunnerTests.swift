import XCTest

@testable import Runner

final class BackupStoreTests: XCTestCase {
  private var path = ""
  private var store: BackupStore!

  override func setUpWithError() throws {
    path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
    store = try BackupStore(path: path)
  }

  override func tearDown() {
    store = nil
    try? FileManager.default.removeItem(atPath: path)
  }

  private func date(_ seconds: TimeInterval) -> Date { Date(timeIntervalSince1970: seconds) }

  func testNewestFileGoesFirst() {
    store.add([("old", date(1)), ("new", date(2))])
    XCTAssertEqual(store.nextPending()?.assetID, "new")
  }

  func testKnownFileKeepsItsState() {
    store.add([("a", date(1))])
    store.markVerified(assetID: "a", part: BackupPart.main, remoteID: "r")
    store.add([("a", date(1))])
    XCTAssertNil(store.nextPending())
    XCTAssertEqual(store.counts()["verified"], 1)
  }

  func testAttemptsRunOutIntoFailed() {
    store.add([("a", date(1))])
    XCTAssertTrue(store.recordFailure(assetID: "a", part: BackupPart.main, error: "x", limit: 2))
    XCTAssertEqual(store.counts()["pending"], 1)
    XCTAssertFalse(store.recordFailure(assetID: "a", part: BackupPart.main, error: "x", limit: 2))
    XCTAssertEqual(store.counts()["failed"], 1)
    XCTAssertEqual(store.failures(limit: 5).first?["error"], "x")

    store.retryFailed()
    XCTAssertEqual(store.nextPending()?.attempts, 0)
  }

  func testRestartRecoversOnlyWorkWithoutATransfer() {
    store.add([("running", date(1)), ("lost", date(2)), ("exporting", date(3))])
    store.setStatus(.uploading, assetID: "running", part: BackupPart.main)
    store.setStatus(.uploading, assetID: "lost", part: BackupPart.main)
    store.setStatus(.exporting, assetID: "exporting", part: BackupPart.main)

    store.recoverInterrupted(activeKeys: [BackupStore.key("running", BackupPart.main)])

    XCTAssertEqual(store.counts()["uploading"], 1)
    XCTAssertEqual(store.counts()["pending"], 2)
  }

  func testStatePersistsAcrossReopening() throws {
    store.add([("a", date(1))])
    store.markVerified(assetID: "a", part: BackupPart.main, remoteID: nil, at: date(50))
    store = try BackupStore(path: path)
    XCTAssertEqual(store.counts()["verified"], 1)
    XCTAssertEqual(store.lastFinished(), 50)
  }

  func testOnlyNewSkipsWhatIsAlreadyInTheAlbum() {
    store.addSkipped(["old"])
    store.add([("old", date(1)), ("new", date(2))])
    XCTAssertEqual(store.nextPending()?.assetID, "new")
    store.markVerified(assetID: "new", part: BackupPart.main, remoteID: nil)
    XCTAssertNil(store.nextPending())
    XCTAssertEqual(store.counts()["skipped"], 1)
    XCTAssertNil(store.statuses(assetIDs: ["old"])["old"])
  }

  func testChangingAlbumForgetsWaitingFilesButNotSentOnes() {
    store.add([("sent", date(1)), ("waiting", date(2))])
    store.markVerified(assetID: "sent", part: BackupPart.main, remoteID: nil)
    store.forgetUnfinished()
    XCTAssertNil(store.nextPending())
    XCTAssertEqual(store.counts()["verified"], 1)
    store.add([("sent", date(1))])
    XCTAssertNil(store.nextPending(), "A file already sent must not be sent again")
  }

  func testLivePhotoWithUnsentVideoIsFoundAgainAfterChangingAlbum() {
    store.add([("live", date(1))])
    store.markVerified(assetID: "live", part: BackupPart.main, remoteID: nil)
    store.add([("live", date(1))], part: BackupPart.paired)
    store.forgetUnfinished()
    store.add([("live", date(1))])
    XCTAssertEqual(store.nextPending()?.part, BackupPart.main)
  }

  func testCancelledTransferIsForgottenButSkippedAndSentFilesAreNot() {
    store.add([("sent", date(1)), ("cancelled", date(2))])
    store.addSkipped(["old"])
    store.markVerified(assetID: "sent", part: BackupPart.main, remoteID: nil)
    store.setStatus(.uploading, assetID: "cancelled", part: BackupPart.main)
    for id in ["sent", "cancelled", "old"] {
      store.forgetCancelled(assetID: id, part: BackupPart.main)
    }
    XCTAssertEqual(store.counts(), ["verified": 1, "skipped": 1])
  }

  func testOnlyAFileStillExportingMayBeSent() {
    store.add([("a", date(1))])
    XCTAssertFalse(store.isExporting(assetID: "a", part: BackupPart.main))
    store.setStatus(.exporting, assetID: "a", part: BackupPart.main)
    XCTAssertTrue(store.isExporting(assetID: "a", part: BackupPart.main))
    store.forgetUnfinished()
    XCTAssertFalse(store.isExporting(assetID: "a", part: BackupPart.main))
  }

  func testFilesRemovedFromTheAlbumStopWaiting() {
    store.add([("stays", date(1)), ("removed", date(2))])
    store.forgetPending(notIn: ["stays"])
    XCTAssertEqual(store.nextPending()?.assetID, "stays")
    XCTAssertEqual(store.counts()["pending"], 1)
  }

  func testLivePhotoIsVerifiedOnlyWithBothFiles() {
    store.add([("live", date(1))])
    store.add([("live", date(1))], part: BackupPart.paired)
    store.markVerified(assetID: "live", part: BackupPart.main, remoteID: nil)
    XCTAssertEqual(store.statuses(assetIDs: ["live"])["live"], "pending")
    store.markVerified(assetID: "live", part: BackupPart.paired, remoteID: nil)
    XCTAssertEqual(store.statuses(assetIDs: ["live"])["live"], "verified")
  }
}

final class BackupAlbumTests: XCTestCase {
  private let albums = [
    BackupAlbum(id: "1", title: "Backup", count: 3),
    BackupAlbum(id: "2", title: "Šišmiš ", count: 1),
  ]

  func testFindsByIDOrTypedNameIgnoringCaseAndAccents() {
    XCTAssertEqual(BackupAlbumFinder.find(id: "2", name: nil, in: albums)?.id, "2")
    XCTAssertEqual(BackupAlbumFinder.find(id: nil, name: " backup ", in: albums)?.id, "1")
    XCTAssertEqual(BackupAlbumFinder.find(id: nil, name: "sismis", in: albums)?.id, "2")
    XCTAssertEqual(BackupAlbumFinder.find(id: "gone", name: "Backup", in: albums)?.id, "1")
  }

  /// Nothing found must mean nothing sent, never the whole library.
  func testNoMatchMeansNoAlbum() {
    XCTAssertNil(BackupAlbumFinder.find(id: nil, name: nil, in: albums))
    XCTAssertNil(BackupAlbumFinder.find(id: nil, name: "   ", in: albums))
    XCTAssertNil(BackupAlbumFinder.find(id: "gone", name: "Other", in: albums))
    XCTAssertNil(BackupAlbumFinder.find(id: "1", name: "Backup", in: []))
  }
}

final class BackupRequestTests: XCTestCase {
  func testServerAnswerAboutAnExistingFile() {
    let yes = Data(#"{"existing":["abc"]}"#.utf8)
    XCTAssertTrue(BackupRequest.serverHasFile(status: 200, body: yes, checksum: "abc"))
    XCTAssertFalse(BackupRequest.serverHasFile(status: 200, body: yes, checksum: "other"))
    XCTAssertFalse(BackupRequest.serverHasFile(status: 500, body: yes, checksum: "abc"))
    XCTAssertFalse(BackupRequest.serverHasFile(status: 200, body: Data("x".utf8), checksum: "abc"))
    XCTAssertFalse(BackupRequest.serverHasFile(status: 200, body: nil, checksum: "abc"))
  }

  func testCheckRequestAsksAboutOneFile() throws {
    let request = try XCTUnwrap(BackupRequest.check(server: "http://s", key: "k", checksum: "abc", allowsCellular: false))
    XCTAssertFalse(request.allowsCellularAccess)
    XCTAssertEqual(request.url?.absoluteString, "http://s/api/assets/check")
    XCTAssertEqual(request.value(forHTTPHeaderField: "X-Api-Key"), "k")
    let body = try XCTUnwrap(request.httpBody)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: [String]])
    XCTAssertEqual(json["checksums"], ["abc"])
  }

  func testRequestIsAWholeFileUpload() throws {
    let request = try XCTUnwrap(
      BackupRequest.make(
        server: "http://192.168.1.10:9851", key: "secret", fileName: "Šišmiš.HEIC", size: 42,
        checksum: "abc", created: Date(timeIntervalSince1970: 2), allowsCellular: false))
    XCTAssertEqual(request.url?.absoluteString, "http://192.168.1.10:9851/api/uploads")
    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertFalse(request.allowsCellularAccess)
    XCTAssertEqual(request.value(forHTTPHeaderField: "X-Api-Key"), "secret")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Upload-Length"), "42")
    XCTAssertEqual(
      request.value(forHTTPHeaderField: "Content-Type"), "application/offset+octet-stream")
    let metadata = try XCTUnwrap(request.value(forHTTPHeaderField: "Upload-Metadata"))
    XCTAssertTrue(metadata.contains("filename \(Data("Šišmiš.HEIC".utf8).base64EncodedString())"))
    XCTAssertTrue(metadata.contains("lastModified \(Data("2000".utf8).base64EncodedString())"))
  }

  func testOutcomes() {
    XCTAssertEqual(BackupRequest.outcome(status: 201, assetID: "x"), .verified(remoteID: "x"))
    XCTAssertEqual(BackupRequest.outcome(status: 401, assetID: nil), .unauthorized)
    if case .retry = BackupRequest.outcome(status: 503, assetID: nil) {} else { XCTFail("503") }
    if case .rejected = BackupRequest.outcome(status: 460, assetID: nil) {} else { XCTFail("460") }
    if case .rejected = BackupRequest.outcome(status: 400, assetID: nil) {} else { XCTFail("400") }
  }

  func testTaskInfoSurvivesARoundTrip() {
    let info = TaskInfo(assetID: "ABC/L0/001", part: "main", path: "/tmp/x.heic")
    let back = TaskInfo(description: info.description)
    XCTAssertEqual(back?.assetID, "ABC/L0/001")
    XCTAssertEqual(back?.path, "/tmp/x.heic")
    XCTAssertNil(TaskInfo(description: "garbage"))
    XCTAssertNil(TaskInfo(description: nil))
  }

  func testChecksumMatchesAKnownValue() throws {
    let file = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try Data("abc".utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }
    XCTAssertEqual(
      BackupEngine.sha256(of: file),
      "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
  }
}
