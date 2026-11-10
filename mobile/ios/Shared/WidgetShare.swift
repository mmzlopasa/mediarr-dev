import Foundation
import Security

/// What the app gives its home screen widget: where the server is, a key that can only read, and the
/// album to show. A sideloaded app has no App Group, so they meet in the keychain.
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

  /// The keychain group this bundle's own items go to when none is named: the first one its signing
  /// allows. Found from an item only this bundle writes.
  static var defaultGroup: String? {
    let probe: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "app.mediarr.prefix." + (Bundle.main.bundleIdentifier ?? ""),
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
    guard status == errSecSuccess, let attributes = found as? [String: Any] else { return nil }
    return attributes[kSecAttrAccessGroup as String] as? String
  }

  /// The app writes into the group its signing gives it first, and the widget looks in every group
  /// it may read. A sideloading app is signed with a profile of its own, whose groups cannot be known
  /// ahead, and this works whenever the two share one.
  private static var query: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: appBundleID + ".widget",
      kSecAttrAccount as String: account,
    ]
  }

  /// What the keychain answered the last time the widget looked, for the note it shows without one.
  static var lastStatus: OSStatus = errSecSuccess

  static func load() -> WidgetShare? {
    var search = query
    search[kSecReturnData as String] = true
    var found: CFTypeRef?
    var status = SecItemCopyMatching(search as CFDictionary, &found)
    // Looked for by name too, for a keychain that does not search every group it may read.
    if status != errSecSuccess, let group = defaultGroup {
      search[kSecAttrAccessGroup as String] = group
      status = SecItemCopyMatching(search as CFDictionary, &found)
    }
    lastStatus = status
    guard status == errSecSuccess, let data = found as? Data else { return nil }
    return try? JSONDecoder().decode(WidgetShare.self, from: data)
  }

  /// False when the signing does not allow sharing with the widget.
  @discardableResult
  static func save(_ share: WidgetShare?) -> Bool {
    let base = query
    SecItemDelete(base as CFDictionary)
    guard let share, let data = try? JSONEncoder().encode(share) else { return true }
    var add = base
    add[kSecValueData as String] = data
    add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
    return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
  }
}
