import UIKit
import Flutter
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Handle Universal Links
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if let url = userActivity.webpageURL {
            print("Received universal link: \(url.absoluteString)")

            // Send the link to Flutter via MethodChannel
            if let flutterViewController = window?.rootViewController as? FlutterViewController {
                let methodChannel = FlutterMethodChannel(name: "app_links", binaryMessenger: flutterViewController.binaryMessenger)
                methodChannel.invokeMethod("onLinkReceived", arguments: url.absoluteString)
            }
        }
        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
}
