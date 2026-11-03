import Flutter
import Foundation

/// Connects the native backup engine to the Flutter interface.
enum BackupChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "app.mediarr/backup", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let engine = BackupEngine.shared
      let arguments = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "enable":
        guard let server = arguments["server"] as? String, let key = arguments["key"] as? String,
          arguments["albumId"] is String || !(arguments["albumName"] as? String ?? "").isEmpty
        else {
          result(FlutterError(code: "arguments", message: "server, key and album are required", details: nil))
          return
        }
        engine.enable(
          server: server,
          key: key,
          wifiOnly: arguments["wifiOnly"] as? Bool ?? true,
          onlyNew: arguments["onlyNew"] as? Bool ?? false,
          albumID: arguments["albumId"] as? String,
          albumName: arguments["albumName"] as? String ?? "")
        result(nil)
      case "setAlbum":
        engine.setAlbum(
          albumID: arguments["albumId"] as? String,
          albumName: arguments["albumName"] as? String ?? "",
          onlyNew: arguments["onlyNew"] as? Bool ?? false)
        result(nil)
      case "albums":
        engine.albums { value in DispatchQueue.main.async { result(value) } }
      case "disable":
        engine.disable()
        result(nil)
      case "setWifiOnly":
        engine.setWifiOnly(arguments["value"] as? Bool ?? true)
        result(nil)
      case "retryFailed":
        engine.retryFailed()
        result(nil)
      case "status":
        engine.status { value in DispatchQueue.main.async { result(value) } }
      case "statuses":
        let ids = arguments["ids"] as? [String] ?? []
        engine.statuses(ids: ids) { value in DispatchQueue.main.async { result(value) } }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
