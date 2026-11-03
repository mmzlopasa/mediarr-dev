import Foundation
import SQLite3

/// What happened to one file on its way to the server.
enum BackupStatus: String {
  case pending, exporting, uploading, verified, failed
  /// Was already in the album when backup started with "only new". Never sent.
  case skipped
}

/// One file to back up. A Live Photo has two: the photo and its paired video.
struct BackupItem: Equatable {
  let assetID: String
  let part: String
  var attempts: Int
}

enum BackupPart {
  static let main = "main"
  static let paired = "paired"
}

/// The state of every file, so a backup survives the app being stopped at any moment.
/// Not thread-safe: BackupEngine calls it from one serial queue.
final class BackupStore {
  private var db: OpaquePointer?
  private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

  init(path: String) throws {
    guard sqlite3_open(path, &db) == SQLITE_OK else {
      throw BackupStoreError.open(String(cString: sqlite3_errmsg(db)))
    }
    try execute(
      """
      CREATE TABLE IF NOT EXISTS items (
        asset_id TEXT NOT NULL,
        part TEXT NOT NULL,
        status TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        created REAL NOT NULL,
        error TEXT,
        remote_id TEXT,
        finished REAL,
        PRIMARY KEY (asset_id, part)
      );
      CREATE INDEX IF NOT EXISTS items_status ON items (status, created DESC);
      """)
  }

  deinit {
    sqlite3_close(db)
  }

  private func execute(_ sql: String) throws {
    guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
      throw BackupStoreError.query(String(cString: sqlite3_errmsg(db)))
    }
  }

  private enum Value {
    case text(String)
    case int(Int)
    case double(Double)
    case null
  }

  private func prepare(_ sql: String, _ values: [Value]) -> OpaquePointer? {
    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
    for (offset, value) in values.enumerated() {
      let index = Int32(offset + 1)
      switch value {
      case .text(let text): sqlite3_bind_text(statement, index, text, -1, transient)
      case .int(let number): sqlite3_bind_int64(statement, index, Int64(number))
      case .double(let number): sqlite3_bind_double(statement, index, number)
      case .null: sqlite3_bind_null(statement, index)
      }
    }
    return statement
  }

  private func run(_ sql: String, _ values: [Value] = []) {
    guard let statement = prepare(sql, values) else { return }
    sqlite3_step(statement)
    sqlite3_finalize(statement)
  }

  private func text(_ statement: OpaquePointer?, _ column: Int32) -> String? {
    guard let raw = sqlite3_column_text(statement, column) else { return nil }
    return String(cString: raw)
  }

  /// Adds files not seen before. Files already known keep their state.
  func add(_ assets: [(id: String, created: Date)], part: String = BackupPart.main) {
    guard !assets.isEmpty else { return }
    run("BEGIN")
    for asset in assets {
      run(
        "INSERT OR IGNORE INTO items (asset_id, part, status, created) VALUES (?, ?, ?, ?)",
        [
          .text(asset.id), .text(part), .text(BackupStatus.pending.rawValue),
          .double(asset.created.timeIntervalSince1970),
        ])
    }
    run("COMMIT")
  }

  /// Marks files as already handled, so they are never sent. Files with a state keep it.
  func addSkipped(_ assetIDs: [String]) {
    guard !assetIDs.isEmpty else { return }
    run("BEGIN")
    for id in assetIDs {
      run(
        "INSERT OR IGNORE INTO items (asset_id, part, status, created) VALUES (?, ?, ?, 0)",
        [.text(id), .text(BackupPart.main), .text(BackupStatus.skipped.rawValue)])
    }
    run("COMMIT")
  }

  /// Forgets everything not yet sent, so changing the album can never send the old album's files.
  /// Verified files stay: they are on the server and must not be sent again.
  /// A Live Photo whose video was not sent is forgotten whole, so the video is found again later.
  /// Its photo is then only checked with the server, not sent twice.
  func forgetUnfinished() {
    let verified = BackupStatus.verified.rawValue
    run(
      """
      DELETE FROM items WHERE asset_id IN (
        SELECT asset_id FROM items WHERE status <> ?
      )
      """, [.text(verified)])
  }

  /// True while this file is still meant to be sent. False once its album was changed or backup
  /// was turned off, and whatever was still on its way must then be dropped.
  func isExporting(assetID: String, part: String) -> Bool {
    guard
      let statement = prepare(
        "SELECT 1 FROM items WHERE asset_id = ? AND part = ? AND status = ?",
        [.text(assetID), .text(part), .text(BackupStatus.exporting.rawValue)])
    else { return false }
    defer { sqlite3_finalize(statement) }
    return sqlite3_step(statement) == SQLITE_ROW
  }

  /// A cancelled transfer: the whole asset is forgotten, for the same reason as in forgetUnfinished.
  func forgetCancelled(assetID: String, part: String) {
    run(
      """
      DELETE FROM items WHERE asset_id = ? AND EXISTS (
        SELECT 1 FROM items WHERE asset_id = ? AND part = ? AND status IN (?, ?, ?)
      )
      """,
      [
        .text(assetID), .text(assetID), .text(part), .text(BackupStatus.pending.rawValue),
        .text(BackupStatus.exporting.rawValue), .text(BackupStatus.uploading.rawValue),
      ])
  }

  /// Forgets waiting files that are no longer in the album.
  func forgetPending(notIn keep: Set<String>) {
    var gone: [String] = []
    if let statement = prepare(
      "SELECT asset_id FROM items WHERE status IN (?, ?)",
      [.text(BackupStatus.pending.rawValue), .text(BackupStatus.failed.rawValue)])
    {
      while sqlite3_step(statement) == SQLITE_ROW {
        if let id = text(statement, 0), !keep.contains(id) { gone.append(id) }
      }
      sqlite3_finalize(statement)
    }
    run("BEGIN")
    for id in gone {
      run("DELETE FROM items WHERE asset_id = ?", [.text(id)])
    }
    run("COMMIT")
  }

  /// The newest file waiting, excluding the ones already taken.
  func nextPending() -> BackupItem? {
    guard
      let statement = prepare(
        "SELECT asset_id, part, attempts FROM items WHERE status = ? ORDER BY created DESC LIMIT 1",
        [.text(BackupStatus.pending.rawValue)])
    else { return nil }
    defer { sqlite3_finalize(statement) }
    guard sqlite3_step(statement) == SQLITE_ROW, let id = text(statement, 0),
      let part = text(statement, 1)
    else { return nil }
    return BackupItem(assetID: id, part: part, attempts: Int(sqlite3_column_int(statement, 2)))
  }

  func setStatus(_ status: BackupStatus, assetID: String, part: String, error: String? = nil) {
    run(
      "UPDATE items SET status = ?, error = ? WHERE asset_id = ? AND part = ?",
      [.text(status.rawValue), error.map(Value.text) ?? .null, .text(assetID), .text(part)])
  }

  func markVerified(assetID: String, part: String, remoteID: String?, at date: Date = Date()) {
    run(
      """
      UPDATE items SET status = ?, error = NULL, remote_id = ?, finished = ?
      WHERE asset_id = ? AND part = ?
      """,
      [
        .text(BackupStatus.verified.rawValue), remoteID.map(Value.text) ?? .null,
        .double(date.timeIntervalSince1970), .text(assetID), .text(part),
      ])
  }

  /// Records a failed attempt. Returns true when the file should be tried again.
  @discardableResult
  func recordFailure(assetID: String, part: String, error: String, limit: Int) -> Bool {
    run(
      "UPDATE items SET attempts = attempts + 1 WHERE asset_id = ? AND part = ?",
      [.text(assetID), .text(part)])
    guard
      let statement = prepare(
        "SELECT attempts FROM items WHERE asset_id = ? AND part = ?",
        [.text(assetID), .text(part)])
    else { return false }
    defer { sqlite3_finalize(statement) }
    let attempts = sqlite3_step(statement) == SQLITE_ROW ? Int(sqlite3_column_int(statement, 0)) : limit
    let again = attempts < limit
    setStatus(again ? .pending : .failed, assetID: assetID, part: part, error: error)
    return again
  }

  /// After a restart: work that has no transfer running anymore goes back to the queue.
  func recoverInterrupted(activeKeys: Set<String>) {
    var interrupted: [(String, String)] = []
    if let statement = prepare(
      "SELECT asset_id, part FROM items WHERE status IN (?, ?)",
      [.text(BackupStatus.exporting.rawValue), .text(BackupStatus.uploading.rawValue)])
    {
      while sqlite3_step(statement) == SQLITE_ROW {
        if let id = text(statement, 0), let part = text(statement, 1),
          !activeKeys.contains(BackupStore.key(id, part))
        {
          interrupted.append((id, part))
        }
      }
      sqlite3_finalize(statement)
    }
    for (id, part) in interrupted {
      setStatus(.pending, assetID: id, part: part)
    }
  }

  static func key(_ assetID: String, _ part: String) -> String { "\(assetID)\n\(part)" }

  func retryFailed() {
    run(
      "UPDATE items SET status = ?, attempts = 0, error = NULL WHERE status = ?",
      [.text(BackupStatus.pending.rawValue), .text(BackupStatus.failed.rawValue)])
  }

  func counts() -> [String: Int] {
    var out: [String: Int] = [:]
    guard let statement = prepare("SELECT status, count(*) FROM items GROUP BY status", []) else {
      return out
    }
    defer { sqlite3_finalize(statement) }
    while sqlite3_step(statement) == SQLITE_ROW {
      if let status = text(statement, 0) {
        out[status] = Int(sqlite3_column_int(statement, 1))
      }
    }
    return out
  }

  func lastFinished() -> Double? {
    guard let statement = prepare("SELECT max(finished) FROM items", []) else { return nil }
    defer { sqlite3_finalize(statement) }
    guard sqlite3_step(statement) == SQLITE_ROW, sqlite3_column_type(statement, 0) != SQLITE_NULL
    else { return nil }
    return sqlite3_column_double(statement, 0)
  }

  /// The worst state per asset: a Live Photo is verified only when both of its files are.
  func statuses(assetIDs: [String]) -> [String: String] {
    var out: [String: String] = [:]
    let rank: [String: Int] = ["verified": 0, "pending": 1, "exporting": 2, "uploading": 2, "failed": 3]
    let hidden = BackupStatus.skipped.rawValue
    for id in assetIDs {
      guard let statement = prepare("SELECT status FROM items WHERE asset_id = ?", [.text(id)]) else {
        continue
      }
      while sqlite3_step(statement) == SQLITE_ROW {
        if let status = text(statement, 0), status != hidden,
          rank[status, default: 0] >= rank[out[id] ?? "verified", default: 0]
        {
          out[id] = status
        }
      }
      sqlite3_finalize(statement)
    }
    return out
  }

  func failures(limit: Int) -> [[String: String]] {
    var out: [[String: String]] = []
    guard
      let statement = prepare(
        "SELECT asset_id, error FROM items WHERE status = ? ORDER BY created DESC LIMIT ?",
        [.text(BackupStatus.failed.rawValue), .int(limit)])
    else { return out }
    defer { sqlite3_finalize(statement) }
    while sqlite3_step(statement) == SQLITE_ROW {
      out.append(["id": text(statement, 0) ?? "", "error": text(statement, 1) ?? ""])
    }
    return out
  }
}

enum BackupStoreError: Error {
  case open(String)
  case query(String)
}
