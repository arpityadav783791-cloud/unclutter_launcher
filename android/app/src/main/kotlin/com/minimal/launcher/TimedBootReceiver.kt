package com.minimal.launcher

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class TimedBootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "TimedBootReceiver"
        private const val ALARM_REQUEST_CODE = 9090
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != Intent.ACTION_BOOT_COMPLETED && action != Intent.ACTION_MY_PACKAGE_REPLACED) {
            return
        }

        Log.d(TAG, "Device reboot or package replaced received ($action). Checking Timed Access session...")
        val session = TimedAccessStateStore.getActiveSession(context) ?: run {
            Log.d(TAG, "No persisted Timed Access session found.")
            return
        }

        val now = System.currentTimeMillis()
        if (session.expiresAt > now) {
            Log.d(TAG, "Restoring active Timed Access session for ${session.packageName} (expires in ${session.expiresAt - now}ms)")
            scheduleAlarm(context, session.sessionId, session.packageName, session.expiresAt)
        } else {
            Log.d(TAG, "Persisted Timed Access session has already expired. Stale active monitoring discarded.")
            // Never restore an expired session as active.
            cancelAlarm(context)
        }
    }

    private fun scheduleAlarm(context: Context, sessionId: String, packageName: String, expiresAt: Long) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(context, TimedExpiryReceiver::class.java).apply {
                putExtra("sessionId", sessionId)
                putExtra("packageName", packageName)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                ALARM_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, expiresAt, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, expiresAt, pendingIntent)
            }
            Log.d(TAG, "Successfully restored exact alarm for $sessionId")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to reschedule exact alarm on reboot: ${e.message}")
        }
    }

    private fun cancelAlarm(context: Context) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(context, TimedExpiryReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                ALARM_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to cancel alarm: ${e.message}")
        }
    }
}
