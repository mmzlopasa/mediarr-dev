import Flutter
import UIKit
import WidgetKit

/// Keeps the screen on while a slideshow plays.
enum AwakeChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "app.mediarr/awake", binaryMessenger: messenger).setMethodCallHandler {
      call, result in
      guard call.method == "set" else { return result(FlutterMethodNotImplemented) }
      let on = (call.arguments as? [String: Any])?["on"] as? Bool ?? false
      DispatchQueue.main.async { UIApplication.shared.isIdleTimerDisabled = on }
      result(nil)
    }
  }
}

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
      case "install":
        result(WidgetInstall.check())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// Whether the signing kept the widget, signed it, and with a profile that lets iOS offer it. A
/// sideloading app signs everything again on the phone, and may drop or break the extension.
enum WidgetInstall {
  /// The plist a signed bundle carries in embedded.mobileprovision, between the signature's bytes.
  static func readProfile(in bundle: URL) -> [String: Any]? {
    guard let data = try? Data(contentsOf: bundle.appendingPathComponent("embedded.mobileprovision")),
      let start = data.range(of: Data("<?xml".utf8)),
      let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound..<data.endIndex)
    else { return nil }
    let plist = data.subdata(in: start.lowerBound..<end.upperBound)
    return (try? PropertyListSerialization.propertyList(from: plist, format: nil)) as? [String: Any]
  }

  static func appIdentifier(_ profile: [String: Any]?) -> String? {
    (profile?["Entitlements"] as? [String: Any])?["application-identifier"] as? String
  }

  static func check() -> [String: Any] {
    let app = Bundle.main.bundleIdentifier ?? ""
    var out: [String: Any] = ["appId": app]
    if let profile = readProfile(in: Bundle.main.bundleURL) {
      out["appProfile"] = appIdentifier(profile) ?? ""
      out["profileName"] = profile["Name"] as? String ?? ""
    }
    guard let plugins = Bundle.main.builtInPlugInsURL else {
      out["present"] = false
      return out
    }
    let widget = plugins.appendingPathComponent("MediarrWidget.appex")
    guard FileManager.default.fileExists(atPath: widget.path), let bundle = Bundle(url: widget) else {
      out["present"] = false
      return out
    }
    out["present"] = true
    out["widgetId"] = bundle.bundleIdentifier ?? ""
    out["signed"] = FileManager.default.fileExists(
      atPath: widget.appendingPathComponent("_CodeSignature/CodeResources").path)
    out["widgetProfile"] = appIdentifier(readProfile(in: widget)) ?? ""
    out["group"] = WidgetShare.group ?? ""
    return out
  }
}
