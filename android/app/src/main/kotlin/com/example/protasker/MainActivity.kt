package com.example.protasker

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.pusher.pushnotifications.PushNotifications

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.protasker/pusher"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        PushNotifications.start(applicationContext, "ae015999-12be-4b38-bdbc-15ad30dfd991")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setInterest" -> {
                    val interest = call.argument<String>("interest")
                    if (interest != null) {
                        PushNotifications.clearDeviceInterests()
                        PushNotifications.addDeviceInterest(interest)
                        result.success(true)
                    } else {
                        result.error("ERROR", "No interest provided", null)
                    }
                }
                "clearInterests" -> {
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
