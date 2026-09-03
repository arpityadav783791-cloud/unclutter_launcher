package com.minimal.launcher

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.UserManager
import android.provider.Settings

/**
 * Manages Protected Launcher Mode using Android DevicePolicyManager.
 * Enforces uninstall and management restrictions when the app is provisioned as Device Owner.
 */
class ProtectedModeManager private constructor(private val context: Context) {

    private val dpm: DevicePolicyManager =
        context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    private val adminComponent = ComponentName(context, ProtectedDeviceAdminReceiver::class.java)

    private val prefs = context.getSharedPreferences("protected_mode_prefs", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_PROTECTED_ENABLED = "protected_mode_enabled"
        private const val KEY_ENABLED_AT = "protected_mode_enabled_at"

        @Volatile
        private var instance: ProtectedModeManager? = null

        fun getInstance(context: Context): ProtectedModeManager {
            return instance ?: synchronized(this) {
                instance ?: ProtectedModeManager(context.applicationContext).also { instance = it }
            }
        }
    }

    fun isDeviceOwner(): Boolean {
        return try {
            dpm.isDeviceOwnerApp(context.packageName)
        } catch (e: Exception) {
            false
        }
    }

    fun isProtectedModeEnabled(): Boolean {
        // Must be device owner and marked enabled in storage
        return isDeviceOwner() && prefs.getBoolean(KEY_PROTECTED_ENABLED, false)
    }

    fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
        }
        val resolveInfo = context.packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return resolveInfo?.activityInfo?.packageName == context.packageName
    }

    fun requestDefaultLauncher() {
        try {
            val intent = Intent(Settings.ACTION_HOME_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            // fallback
        }
    }

    /**
     * Enables protected mode.
     * Enforces uninstall restrictions and sets default launcher via DevicePolicyManager.
     */
    fun enableProtection(): Boolean {
        if (!isDeviceOwner()) {
            return false
        }

        return try {
            // 1. Block uninstallation of this package
            dpm.setUninstallBlocked(adminComponent, context.packageName, true)

            // 2. Disallow uninstalling apps and apps control (force-stop / clear data)
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_UNINSTALL_APPS)
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_APPS_CONTROL)

            // 3. Configure as persistent preferred Home activity
            val filter = IntentFilter(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addCategory(Intent.CATEGORY_DEFAULT)
            }
            val activity = ComponentName(context, MainActivity::class.java)
            dpm.addPersistentPreferredActivity(adminComponent, filter, activity)

            prefs.edit()
                .putBoolean(KEY_PROTECTED_ENABLED, true)
                .putLong(KEY_ENABLED_AT, System.currentTimeMillis())
                .apply()
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Disables protected mode during recovery.
     * Clears restrictions and restores normal management.
     */
    fun disableProtection(): Boolean {
        return try {
            if (isDeviceOwner()) {
                // 1. Remove uninstall block
                dpm.setUninstallBlocked(adminComponent, context.packageName, false)

                // 2. Clear user restrictions
                dpm.clearUserRestriction(adminComponent, UserManager.DISALLOW_UNINSTALL_APPS)
                dpm.clearUserRestriction(adminComponent, UserManager.DISALLOW_APPS_CONTROL)

                // 3. Clear persistent preferred launcher activity
                dpm.clearPackagePersistentPreferredActivities(adminComponent, context.packageName)
            }

            prefs.edit()
                .putBoolean(KEY_PROTECTED_ENABLED, false)
                .apply()
            true
        } catch (e: Exception) {
            false
        }
    }

    fun onAdminDisabled() {
        prefs.edit()
            .putBoolean(KEY_PROTECTED_ENABLED, false)
            .apply()
    }

    fun getState(): Map<String, Any?> {
        val enabled = isProtectedModeEnabled()
        val enabledAt = if (enabled) prefs.getLong(KEY_ENABLED_AT, 0L) else null
        return mapOf(
            "enabled" to enabled,
            "enabledAt" to enabledAt,
            "deviceOwnerActive" to isDeviceOwner(),
            "defaultLauncherActive" to isDefaultLauncher()
        )
    }
}
