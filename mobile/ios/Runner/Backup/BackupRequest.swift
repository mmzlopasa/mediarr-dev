import Foundation

/// What a finished transfer means for the file.
enum BackupOutcome: Equatable {
  case verified(remoteID: String?)
  /// The server had a temporary problem.
  case retry(String)
  /// The server refused this file. Trying again would not help.
  case rejected(String)
  /// The device key no longer works, so nothing else can upload either.
  case unauthorized
}

enum BackupRequest {
  /// A whole file in one request (tus creation-with-upload), the only form a background transfer
  /// can send. The server compares the checksum and refuses a damaged file.
  static func make(
    server: String,
    key: String,
    fileName: String,
    size: Int64,
    checksum: String,
    created: Date?,
    allowsCellular: Bool
  ) -> URLRequest? {
    guard let url = URL(string: server + "/api/uploads") else { return nil }
    var metadata = [("filename", fileName), ("checksum", checksum)]
    if let created {
      metadata.append(("lastModified", String(Int64(created.timeIntervalSince1970 * 1000))))
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.allowsCellularAccess = allowsCellular
    request.setValue(key, forHTTPHeaderField: "X-Api-Key")
    request.setValue("1.0.0", forHTTPHeaderField: "Tus-Resumable")
    request.setValue(String(size), forHTTPHeaderField: "Upload-Length")
    request.setValue("application/offset+octet-stream", forHTTPHeaderField: "Content-Type")
    request.setValue(encode(metadata), forHTTPHeaderField: "Upload-Metadata")
    return request
  }

  /// Asks whether the server already has a file, so nothing is sent twice.
  static func check(
    server: String, key: String, checksum: String, allowsCellular: Bool
  ) -> URLRequest? {
    guard let url = URL(string: server + "/api/assets/check"),
      let body = try? JSONSerialization.data(withJSONObject: ["checksums": [checksum]])
    else { return nil }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 20
    request.allowsCellularAccess = allowsCellular
    request.setValue(key, forHTTPHeaderField: "X-Api-Key")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = body
    return request
  }

  /// False also when the answer cannot be read: the upload then goes ahead, and the server still
  /// stores no duplicate. Only the data is spent.
  static func serverHasFile(status: Int, body: Data?, checksum: String) -> Bool {
    guard status == 200, let body,
      let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
      let existing = json["existing"] as? [String]
    else { return false }
    return existing.contains(checksum)
  }

  static func encode(_ metadata: [(String, String)]) -> String {
    metadata
      .map { "\($0.0) \(Data($0.1.utf8).base64EncodedString())" }
      .joined(separator: ",")
  }

  static func outcome(status: Int, assetID: String?) -> BackupOutcome {
    switch status {
    case 201, 204: return .verified(remoteID: assetID)
    case 401, 403: return .unauthorized
    case 460: return .rejected("The file was damaged on the way to the server.")
    case 408, 429, 500...599: return .retry("The server answered \(status).")
    default: return .rejected("The server refused this file (\(status)).")
    }
  }
}
