package com.minimal.launcher

import android.content.Context
import android.content.SharedPreferences

data class NativeTimedSession(
    val sessionId: String,
    val packageName: String,
    val expiresAt: Long,
    val state: String = TimedAccessStateStore.STATE_ACTIVE
)

object TimedAccessStateStore {
    const val STATE_NONE = "NONE"
    const val STATE_STARTING = "STARTING"
    const val STATE_ACTIVE = "ACTIVE"
    const val STATE_EXPIRED_WAITING = "EXPIRED_WAITING"
    const val STATE_TERMINATING = "TERMINATING"

    private const val PREFS_NAME = "timed_access_native_state"
    private const val KEY_SESSION_ID = "active_session_id"
    private const val KEY_PACKAGE_NAME = "active_package_name"
    private const val KEY_EXPIRES_AT = "active_expires_at"
    private const val KEY_STATE = "active_session_state"
    private const val KEY_DISTRACTION_PACKAGES = "distraction_packages"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    @Synchronized
    fun saveSession(context: Context, sessionId: String, packageName: String, expiresAt: Long, state: String = STATE_ACTIVE) {
        getPrefs(context).edit()
            .putString(KEY_SESSION_ID, sessionId)
            .putString(KEY_PACKAGE_NAME, packageName)
            .putLong(KEY_EXPIRES_AT, expiresAt)
            .putString(KEY_STATE, state)
            .apply()
    }

    @Synchronized
    fun setSessionState(context: Context, state: String) {
        getPrefs(context).edit()
            .putString(KEY_STATE, state)
            .apply()
    }

    @Synchronized
    fun getSessionState(context: Context): String {
        val prefs = getPrefs(context)
        val id = prefs.getString(KEY_SESSION_ID, null)
        if (id.isNullOrBlank()) return STATE_NONE
        return prefs.getString(KEY_STATE, STATE_ACTIVE) ?: STATE_ACTIVE
    }

    @Synchronized
    fun clearSession(context: Context, sessionId: String? = null) {
        val prefs = getPrefs(context)
        val currentId = prefs.getString(KEY_SESSION_ID, null)
        if (sessionId == null || currentId == sessionId) {
            prefs.edit()
                .remove(KEY_SESSION_ID)
                .remove(KEY_PACKAGE_NAME)
                .remove(KEY_EXPIRES_AT)
                .remove(KEY_STATE)
                .apply()
        }
    }

    @Synchronized
    fun getActiveSession(context: Context): NativeTimedSession? {
        val prefs = getPrefs(context)
        val id = prefs.getString(KEY_SESSION_ID, null) ?: return null
        val pkg = prefs.getString(KEY_PACKAGE_NAME, null) ?: return null
        val exp = prefs.getLong(KEY_EXPIRES_AT, 0L)
        val state = prefs.getString(KEY_STATE, STATE_ACTIVE) ?: STATE_ACTIVE
        if (id.isBlank() || pkg.isBlank() || exp <= 0L) {
            return null
        }
        return NativeTimedSession(id, pkg, exp, state)
    }

    @Synchronized
    fun isSessionValid(context: Context, packageName: String, now: Long = System.currentTimeMillis()): Boolean {
        val session = getActiveSession(context) ?: return false
        return session.packageName == packageName &&
               session.sessionId.isNotBlank() &&
               session.state == STATE_ACTIVE &&
               session.expiresAt > now
    }

    @Synchronized
    fun isSessionExpiredWaiting(context: Context, packageName: String): Boolean {
        val session = getActiveSession(context) ?: return false
        return session.packageName == packageName &&
               session.sessionId.isNotBlank() &&
               (session.state == STATE_EXPIRED_WAITING || (session.state == STATE_ACTIVE && session.expiresAt <= System.currentTimeMillis()))
    }

    @Synchronized
    fun isSessionExpired(context: Context, now: Long = System.currentTimeMillis()): Boolean {
        val session = getActiveSession(context) ?: return false
        return session.expiresAt <= now || session.state == STATE_EXPIRED_WAITING
    }

    @Synchronized
    fun setDistractionPackages(context: Context, packages: Set<String>) {
        getPrefs(context).edit()
            .putStringSet(KEY_DISTRACTION_PACKAGES, packages)
            .apply()
    }

    @Synchronized
    fun getDistractionPackages(context: Context): Set<String> {
        return getPrefs(context).getStringSet(KEY_DISTRACTION_PACKAGES, emptySet()) ?: emptySet()
    }

    @Synchronized
    fun isDistractionPackage(context: Context, packageName: String): Boolean {
        val distractions = getDistractionPackages(context)
        val active = getActiveSession(context)
        return distractions.contains(packageName) || active?.packageName == packageName
    }
}
