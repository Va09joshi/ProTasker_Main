package com.example.protasker

import android.os.Bundle
import android.util.Log
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.pusher.pushnotifications.PushNotifications

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.protasker/pusher"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startPushNotificationsIfSupported()
    }

    private fun startPushNotificationsIfSupported() {
        val hasGooglePlayServices = try {
            packageManager.getPackageInfo("com.google.android.gms", 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }

        if (!hasGooglePlayServices) {
            Log.w(
                "ProTaskerPusher",
                "Google Play services unavailable. " +
                    "Pusher Beams/FCM registration will fail on this device."
            )
            return
        }

        Log.d("ProTaskerPusher", "Starting PushNotifications SDK")
        PushNotifications.start(applicationContext, "ae015999-12be-4b38-bdbc-15ad30dfd991")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setInterest" -> {
                    val interest = call.argument<String>("interest")
                    if (interest != null) {
                        Log.d("ProTaskerPusher", "Subscribing device to interest: $interest")
                        PushNotifications.clearDeviceInterests()
                        PushNotifications.addDeviceInterest(interest)
                        Log.d("ProTaskerPusher", "Subscribed to interest: $interest")
                        result.success(true)
                    } else {
                        result.error("ERROR", "No interest provided", null)
                    }
                }
                "clearInterests" -> {
                    Log.d("ProTaskerPusher", "Clearing device interests")
                    PushNotifications.clearDeviceInterests()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
