import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    SharedFiles.shared.receive(connectionOptions.urlContexts.map(\.url))
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    SharedFiles.shared.receive(URLContexts.map(\.url))
  }
}

/// Files other apps opened in Mediarr. iOS hands over a copy, which is removed after the upload.
final class SharedFiles {
  static let shared = SharedFiles()
  private var waiting: [String] = []
  private var channel: FlutterMethodChannel?

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "app.mediarr/share", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "take" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self?.waiting ?? [])
      self?.waiting = []
    }
    self.channel = channel
  }

  func receive(_ urls: [URL]) {
    let files = urls.filter { SharedFiles.mayReceive($0, home: NSHomeDirectory()) }
    guard !files.isEmpty else { return }
    waiting += files.map(\.path)
    channel?.invokeMethod("changed", arguments: nil)
  }

  /// Only the copy iOS hands over, which lands in this app's own folders, and only a plain file.
  /// Never a path elsewhere, which the app could otherwise be made to upload.
  static func mayReceive(_ url: URL, home: String) -> Bool {
    guard url.isFileURL else { return false }
    let path = url.standardizedFileURL.resolvingSymlinksInPath().path
    let root = URL(fileURLWithPath: home).standardizedFileURL.resolvingSymlinksInPath().path
    guard path.hasPrefix(root.hasSuffix("/") ? root : root + "/") else { return false }
    var directory: ObjCBool = false
    return FileManager.default.fileExists(atPath: path, isDirectory: &directory) && !directory.boolValue
  }
}
