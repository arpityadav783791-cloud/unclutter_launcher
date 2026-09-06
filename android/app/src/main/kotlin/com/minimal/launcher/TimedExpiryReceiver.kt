package com.minimal.launcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class TimedExpiryReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "TimedExpiryReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val sessionId = intent.getStringExtra("sessionId") ?: return
        val packageName = intent.getStringExtra("packageName") ?: return

        Log.d(TAG, "Expiry alarm received for $packageName (sessionId=$sessionId)")

        // 1. Stale alarm protection: verify against authoritative native state
        val active = TimedAccessStateStore.getActiveSession(context)
        if (active == null || active.sessionId != sessionId || active.packageName != packageName) {
            Log.w(TAG, "Ignoring stale or mismatched expiry alarm. Active session: ${active?.sessionId} (${active?.packageName}), Alarm: $sessionId ($packageName)")
            return
        }

        // 2. If MainActivity is alive, dispatch expiry notification via method channel
        val activity = MainActivity.instance
        if (activity != null) {
            activity.notifyTimedAccessExpired(sessionId, packageName)
        } else {
            // 3. If MainActivity / Flutter process was killed, launch MainActivity to present Phase 5 DialogBox
            Log.d(TAG, "MainActivity is not active. Bringing launcher to front for expiry handling...")
            try {
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    putExtra("timed_access_expired_session_id", sessionId)
                    putExtra("timed_access_expired_package", packageName)
                }
                context.startActivity(launchIntent)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to launch MainActivity on background expiry: ${e.message}")
            }
        }
    }
}
