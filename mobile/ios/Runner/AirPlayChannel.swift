import AVKit
import Flutter
import UIKit

/// The system's AirPlay button, for choosing an Apple TV. A video the app plays then goes there.
/// Photos have no AirPlay of their own for apps: they reach the TV through Screen Mirroring.
final class AirPlayButtonFactory: NSObject, FlutterPlatformViewFactory {
  func create(
    withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?
  ) -> FlutterPlatformView {
    let tint = (args as? [String: Any])?["tint"] as? Int
    return AirPlayButton(frame: frame, tint: tint)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

final class AirPlayButton: NSObject, FlutterPlatformView {
  private let picker: AVRoutePickerView

  init(frame: CGRect, tint: Int?) {
    picker = AVRoutePickerView(frame: frame)
    picker.prioritizesVideoDevices = true
    picker.backgroundColor = .clear
    if let tint {
      picker.tintColor = UIColor(
        red: CGFloat((tint >> 16) & 0xFF) / 255, green: CGFloat((tint >> 8) & 0xFF) / 255,
        blue: CGFloat(tint & 0xFF) / 255, alpha: 1)
    }
    super.init()
  }

  func view() -> UIView { picker }
}

enum AirPlayChannel {
  static func register(registrar: FlutterPluginRegistrar) {
    registrar.register(AirPlayButtonFactory(), withId: "app.mediarr/airplay-button")
    let channel = FlutterMethodChannel(
      name: "app.mediarr/airplay", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "active" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
      result(outputs.contains { $0.portType == .airPlay })
    }
  }
}
