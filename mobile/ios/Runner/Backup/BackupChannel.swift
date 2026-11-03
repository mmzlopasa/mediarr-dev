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
        guard let server = arguments["server"] as? String, let key = arguments["key"] as? String
        else {
          result(FlutterError(code: "arguments", message: "server and key are required", details: nil))
          return
        }
        engine.enable(
          server: server,
          key: key,
          wifiOnly: arguments["wifiOnly"] as? Bool ?? true,
          onlyNew: arguments["onlyNew"] as? Bool ?? false)
        result(nil)
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
