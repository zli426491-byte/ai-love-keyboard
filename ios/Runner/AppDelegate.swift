import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let appGroupID = "group.com.ailovekeyboard.app"
  private static let subscriptionKey = "is_subscribed"
  private static let revenueCatAppUserIDKey = "revenuecat_app_user_id"
  private static let accountAccessTokenKey = "lovekey_account_access_token"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.ailovekeyboard.app/subscription",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "setSubscriptionStatus" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard
          let arguments = call.arguments as? [String: Any],
          let isSubscribed = arguments["isSubscribed"] as? Bool,
          let defaults = UserDefaults(suiteName: AppDelegate.appGroupID)
        else {
          result(
            FlutterError(
              code: "subscription_sync_failed",
              message: "Unable to open the LoveKey App Group.",
              details: nil
            )
          )
          return
        }

        defaults.set(isSubscribed, forKey: AppDelegate.subscriptionKey)
        if arguments.keys.contains("revenueCatAppUserID") {
          if let appUserID = arguments["revenueCatAppUserID"] as? String,
             !appUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            defaults.set(
              appUserID.trimmingCharacters(in: .whitespacesAndNewlines),
              forKey: AppDelegate.revenueCatAppUserIDKey
            )
          } else {
            defaults.removeObject(forKey: AppDelegate.revenueCatAppUserIDKey)
          }
        }
        if let token = arguments["accountAccessToken"] as? String {
          let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
          if normalizedToken.isEmpty {
            defaults.removeObject(forKey: AppDelegate.accountAccessTokenKey)
          } else {
            defaults.set(normalizedToken, forKey: AppDelegate.accountAccessTokenKey)
          }
        }
        result(nil)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
