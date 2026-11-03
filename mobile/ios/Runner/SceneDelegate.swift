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
    let files = urls.filter(\.isFileURL)
    guard !files.isEmpty else { return }
    waiting += files.map(\.path)
    channel?.invokeMethod("changed", arguments: nil)
  }
}
