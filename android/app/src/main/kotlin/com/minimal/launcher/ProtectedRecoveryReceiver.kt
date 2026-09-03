package com.minimal.launcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receiver handling secret dialer recovery trigger.
 * Launches the launcher recovery confirmation flow without logging or exposing trigger codes.
 */
class ProtectedRecoveryReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("trigger_recovery", true)
        }
        context.startActivity(launchIntent)
    }
}
