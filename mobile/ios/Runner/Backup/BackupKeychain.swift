import Foundation
import Security

/// Keeps the device key available to background work after the first unlock.
enum BackupKeychain {
  private static let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "app.mediarr.backup",
    kSecAttrAccount as String: "device-key",
  ]

  static func save(_ value: String) {
    SecItemDelete(query as CFDictionary)
    var attributes = query
    attributes[kSecValueData as String] = Data(value.utf8)
    attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    SecItemAdd(attributes as CFDictionary, nil)
  }

  static func read() -> String? {
    var search = query
    search[kSecReturnData as String] = true
    search[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: AnyObject?
    guard SecItemCopyMatching(search as CFDictionary, &result) == errSecSuccess,
      let data = result as? Data
    else { return nil }
    return String(data: data, encoding: .utf8)
  }

  static func delete() {
    SecItemDelete(query as CFDictionary)
  }
}
