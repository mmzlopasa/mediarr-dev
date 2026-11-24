import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // iOS requires this before launching finishes, also when it starts the app in the background.
    BackupEngine.shared.registerBackgroundTasks()
    BackupEngine.shared.activate()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    // Only the backup's own transfers; any other session belongs to a plugin.
    guard identifier == BackupEngine.sessionID else {
      super.application(
        application, handleEventsForBackgroundURLSession: identifier,
        completionHandler: completionHandler)
      return
    }
    BackupEngine.shared.backgroundCompletion = completionHandler
    BackupEngine.shared.activate()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MediarrBackup") {
      BackupChannel.register(messenger: registrar.messenger())
      SharedFiles.shared.register(messenger: registrar.messenger())
      WidgetChannel.register(messenger: registrar.messenger())
      AwakeChannel.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MediarrAirPlay") {
      AirPlayChannel.register(registrar: registrar)
    }
  }
}
