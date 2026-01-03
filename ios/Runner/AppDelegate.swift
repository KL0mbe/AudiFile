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
        name: "now_playing_override",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        switch call.method {

        case "apply":
          guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "BAD_ARGS", message: "Expected args map", details: nil))
            return
          }

          // Title / artist
          let title = args["title"] as? String
          let artist = args["artist"] as? String

          // Skip mode
          let isSkip = args["isSkip"] as? Bool ?? false

          // Intervals (seconds)
          let ffSeconds = args["ffSeconds"] as? Double
          let rwSeconds = args["rwSeconds"] as? Double

          // Artwork bytes
          let artworkTyped = args["artworkBytes"] as? FlutterStandardTypedData
          let image = artworkTyped.flatMap { UIImage(data: $0.data) }

          DispatchQueue.main.async {

            // 1) Control Center / lock screen button intervals (old behavior + isSkip)
            let cc = MPRemoteCommandCenter.shared()

            // If isSkip is true, force the same behavior as your 1000 sentinel mode:
            // do NOT configure interval skip buttons at all.
            let forwardIsInterval = !isSkip && (ffSeconds != nil) && (ffSeconds! != 1000)
            let backwardIsInterval = !isSkip && (rwSeconds != nil) && (rwSeconds! != 1000)

            // IMPORTANT: prevent iOS from preferring >>/<< (track skip) over interval buttons
            cc.nextTrackCommand.isEnabled = !forwardIsInterval
            cc.previousTrackCommand.isEnabled = !backwardIsInterval


            // Forward
            cc.skipForwardCommand.isEnabled = forwardIsInterval
            if forwardIsInterval {
              cc.skipForwardCommand.preferredIntervals = [NSNumber(value: ffSeconds!)]
            } else {
              cc.skipForwardCommand.preferredIntervals = []
            }

            // Backward
            cc.skipBackwardCommand.isEnabled = backwardIsInterval
            if backwardIsInterval {
              cc.skipBackwardCommand.preferredIntervals = [NSNumber(value: rwSeconds!)]
            } else {
              cc.skipBackwardCommand.preferredIntervals = []
            }


            // 2) Now Playing metadata (lock screen + control center)
            var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]

            if let t = title { info[MPMediaItemPropertyTitle] = t }
            if let a = artist { info[MPMediaItemPropertyArtist] = a }

            if let img = image {
              let artwork = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
              info[MPMediaItemPropertyArtwork] = artwork
            }

            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            result(true)
          }

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
