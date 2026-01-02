import MediaPlayer
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
              name: "audio_intervals",
              binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        let cc = MPRemoteCommandCenter.shared()

        switch call.method {
          case "setForwardInterval":
            guard
              let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool,
              let seconds = args["seconds"] as? Double
            else{
              result(FlutterError(code: "BAD_ARGS", message: "Expected {enabled: Bool, seconds: Double}", details: nil))
              return
            }

            cc.skipForwardCommand.isEnabled = enabled
            if enabled{
              cc.skipForwardCommand.preferredIntervals = [NSNumber(value: seconds)]
            }
            result(true)

          case"setBackwardInterval":
            guard
              let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool,
              let seconds = args["seconds"] as? Double
            else {
              result(FlutterError(code: "BAD_ARGS", message: "Expected {enabled: Bool, seconds: Double}", details: nil))
              return
            }

            cc.skipBackwardCommand.isEnabled = enabled
            if enabled {
              cc.skipBackwardCommand.preferredIntervals = [NSNumber(value: seconds)]
            }
            result(true)

          default:
            result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
