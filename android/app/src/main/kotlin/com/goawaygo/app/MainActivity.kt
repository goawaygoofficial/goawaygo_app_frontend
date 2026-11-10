package com.goawaygo.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The channel push messages arrive on (the backend sends channel_id "goawaygo"); creating it again is a no-op.
        val channel = NotificationChannel(
            "goawaygo",
            "GoAwayGo notifications",
            NotificationManager.IMPORTANCE_DEFAULT,
        )
        channel.description = "Wanderbook activity, trip reminders, shared plans and news"
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Opens this app's page in the phone's notification settings (after the permission was refused).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "goawaygo/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method == "openSettings") {
                    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    startActivity(intent)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
