package com.example.logistics_toolkit

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // This function is called when the app starts to create all necessary notification channels
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // 1. Channel for the persistent tracking service (LOW importance)
            val trackingChannel = NotificationChannel(
                "location_channel",
                "Location Tracking Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Persistent notification for the location service."
            }

            // 2. NEW: Channel for high-priority alerts (HIGH importance)
            val alertsChannel = NotificationChannel(
                "alerts_channel",
                "Shipment Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for important shipment status updates."
            }

            // Register both channels with the system
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(trackingChannel)
            notificationManager.createNotificationChannel(alertsChannel) // Register the new channel
        }
    }
}