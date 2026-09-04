package com.minimal.launcher

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat

class SessionExpiryReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_SESSION_EXPIRED = "com.minimal.launcher.ACTION_SESSION_EXPIRED"
        const val ACTION_END_SESSION = "com.minimal.launcher.ACTION_END_SESSION"
        const val EXTRA_PACKAGE_NAME = "extra_package_name"
        const val EXTRA_APP_NAME = "extra_app_name"

        const val CHANNEL_ID_TIMER = "unclutter_timed_detox"
        const val CHANNEL_ID_ALARM = "unclutter_time_up"
        const val NOTIFICATION_ID_COUNTDOWN = 9991
        const val NOTIFICATION_ID_TIME_UP = 9992
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""
        val appName = intent.getStringExtra(EXTRA_APP_NAME) ?: packageName

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        // Always cancel countdown notification
        nm?.cancel(NOTIFICATION_ID_COUNTDOWN)

        when (action) {
            ACTION_SESSION_EXPIRED -> {
                if (UsageTimerOverlayManager.isSessionOpenFor(packageName)) {
                    UsageTimerOverlayManager.showExpiredCard()
                } else {
                    terminateDistractionApp(context, packageName)
                }
                MainActivity.instance?.notifySessionExpired(packageName)
            }
            ACTION_END_SESSION -> {
                // User explicitly clicked "End Session" in notification
                UsageTimerOverlayManager.stopSession()
                MyAccessibilityService.clearExpiredPackage()
                terminateDistractionApp(context, packageName)

                MainActivity.instance?.cancelActiveTimedSession()
            }
        }
    }

    private fun terminateDistractionApp(context: Context, packageName: String) {
        // 1. Steal audio focus to immediately pause video/audio playback in YouTube/media apps.
        // Paused media prevents Android from automatically entering Picture-in-Picture mode!
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    .build()
                audioManager?.requestAudioFocus(focusRequest)
            } else {
                @Suppress("DEPRECATION")
                audioManager?.requestAudioFocus(null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN)
            }
        } catch (_: Exception) {}

        // 2. Accessibility enforcement: lock package, dismiss any active PiP, press Back then Home
        if (packageName.isNotEmpty()) {
            MyAccessibilityService.setExpiredPackage(packageName)
            MyAccessibilityService.dismissPipIfActive(packageName)
            MyAccessibilityService.pressBack()
        }
        MyAccessibilityService.goHome()

        // 3. Kill background/PiP processes for the target distraction package
        if (packageName.isNotEmpty()) {
            try {
                val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                am?.killBackgroundProcesses(packageName)
            } catch (_: Exception) {}
        }

        // 4. Force return to launcher via Category Home / MainActivity intent
        try {
            val homeIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                putExtra("timed_session_expired", true)
                putExtra("expired_package", packageName)
            }
            context.startActivity(homeIntent)
        } catch (_: Exception) {
            val fallbackHome = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            try {
                context.startActivity(fallbackHome)
            } catch (_: Exception) {}
        }

        // 5. Post-check after 350ms to kill any asynchronously spawned PiP windows
        if (packageName.isNotEmpty()) {
            Handler(Looper.getMainLooper()).postDelayed({
                MyAccessibilityService.dismissPipIfActive(packageName)
                try {
                    val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                    am?.killBackgroundProcesses(packageName)
                } catch (_: Exception) {}
            }, 350L)
        }
    }

    private fun showTimesUpNotification(context: Context, packageName: String, appName: String) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID_ALARM,
                "Detox Time's Up",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts when timed app access expires"
                enableVibration(true)
            }
            nm.createNotificationChannel(channel)
        }

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("timed_session_expired", true)
            putExtra("expired_package", packageName)
            putExtra("expired_app_name", appName)
        }

        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID_TIME_UP,
            launchIntent,
            piFlags
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID_ALARM)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("Time's up: $appName")
            .setContentText("Your session on $appName has ended.")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setContentIntent(fullScreenPendingIntent)
            .setAutoCancel(true)
            .setOngoing(false)

        nm.notify(NOTIFICATION_ID_TIME_UP, builder.build())
    }
}
