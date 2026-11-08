import Foundation
import Security

/// What the app gives its home screen widget: where the server is, a key that can only read, and the
/// album to show. Feather signs the app with a profile that has no App Group, but it does let the app
/// and its extension share keychain items under the team, so this is where they meet.
struct WidgetShare: Codable, Equatable {
  var server: String
  var key: String
  var albumId: String
  var albumTitle: String

  private static let account = "widget"

  /// The app's own bundle identifier; the widget's is the same with ".widget" added.
  private static var appBundleID: String {
    let id = Bundle.main.bundleIdentifier ?? "app.mediarr.mediarr"
    return id.hasSuffix(".widget") ? String(id.dropLast(".widget".count)) : id
  }

  /// The team prefix the signing gave, found from an item only this app can see.
  private static var teamPrefix: String? {
    let probe: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "app.mediarr.prefix",
      kSecAttrAccount as String: "prefix",
      kSecReturnAttributes as String: true,
    ]
    var found: CFTypeRef?
    var status = SecItemCopyMatching(probe as CFDictionary, &found)
    if status == errSecItemNotFound {
      var add = probe
      add.removeValue(forKey: kSecReturnAttributes as String)
      add[kSecValueData as String] = Data()
      add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
      SecItemAdd(add as CFDictionary, nil)
      status = SecItemCopyMatching(probe as CFDictionary, &found)
    }
    guard status == errSecSuccess, let attributes = found as? [String: Any],
      let group = attributes[kSecAttrAccessGroup as String] as? String,
      let dot = group.firstIndex(of: ".")
    else { return nil }
    return String(group[...dot])
  }

  private static var query: [String: Any]? {
    guard let prefix = teamPrefix else { return nil }
    return [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: appBundleID + ".widget",
      kSecAttrAccount as String: account,
      kSecAttrAccessGroup as String: prefix + appBundleID + ".share",
    ]
  }

  static func load() -> WidgetShare? {
    guard var search = query else { return nil }
    search[kSecReturnData as String] = true
    var found: CFTypeRef?
    guard SecItemCopyMatching(search as CFDictionary, &found) == errSecSuccess,
      let data = found as? Data
    else { return nil }
    return try? JSONDecoder().decode(WidgetShare.self, from: data)
  }

  /// False when the signing does not allow sharing with the widget.
  @discardableResult
  static func save(_ share: WidgetShare?) -> Bool {
    guard let base = query else { return false }
    SecItemDelete(base as CFDictionary)
    guard let share, let data = try? JSONEncoder().encode(share) else { return true }
    var add = base
    add[kSecValueData as String] = data
    add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
    return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
  }
}
