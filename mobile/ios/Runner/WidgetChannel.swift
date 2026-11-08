import Flutter
import WidgetKit

/// Lets the app choose what the home screen widget shows.
enum WidgetChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "app.mediarr/widget", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "configure":
        guard let args = call.arguments as? [String: Any],
          let server = args["server"] as? String, let key = args["key"] as? String,
          let album = args["albumId"] as? String
        else {
          result(FlutterError(code: "args", message: "server, key and albumId are needed", details: nil))
          return
        }
        let saved = WidgetShare.save(
          WidgetShare(server: server, key: key, albumId: album, albumTitle: args["albumTitle"] as? String ?? ""))
        WidgetCenter.shared.reloadAllTimelines()
        if saved {
          result(nil)
        } else {
          result(FlutterError(code: "keychain", message: "This installation does not let the app share with its widget.", details: nil))
        }
      case "clear":
        WidgetShare.save(nil)
        WidgetCenter.shared.reloadAllTimelines()
        result(nil)
      case "status":
        let share = WidgetShare.load()
        // The widget fetches its own pictures, so the app does not know how many it keeps.
        result(["albumId": share?.albumId as Any, "albumTitle": share?.albumTitle ?? "", "pictures": -1])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
