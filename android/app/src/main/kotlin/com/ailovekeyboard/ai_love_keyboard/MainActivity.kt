package com.ailovekeyboard.ai_love_keyboard

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.ailovekeyboard.app/subscription"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "setSubscriptionStatus") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val arguments = call.arguments as? Map<*, *>
                val isSubscribed = arguments?.get("isSubscribed") as? Boolean ?: false
                val appUserId = arguments?.get("revenueCatAppUserID") as? String
                val accessToken = arguments?.get("accountAccessToken") as? String
                val prefs = getSharedPreferences(
                    "FlutterSharedPreferences",
                    Context.MODE_PRIVATE,
                )
                val editor = prefs.edit().putBoolean("lovekey_is_subscribed", isSubscribed)
                if (arguments?.containsKey("revenueCatAppUserID") == true) {
                    if (!appUserId.isNullOrBlank()) {
                        editor.putString("lovekey_revenuecat_app_user_id", appUserId)
                    } else {
                        editor.remove("lovekey_revenuecat_app_user_id")
                    }
                }
                if (accessToken != null) {
                    if (accessToken.isBlank()) {
                        editor.remove("lovekey_account_access_token")
                    } else {
                        editor.putString("lovekey_account_access_token", accessToken)
                    }
                }
                editor.apply()
                result.success(null)
            }
    }
}
