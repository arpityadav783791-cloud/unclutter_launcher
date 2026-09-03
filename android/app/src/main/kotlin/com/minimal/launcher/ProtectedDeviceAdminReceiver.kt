package com.minimal.launcher

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

/**
 * DeviceAdminReceiver for the Minimalist Digital Detox Launcher.
 * Enables Device Owner administrative policies including uninstall protection.
 */
class ProtectedDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence? {
        // Warning message if user attempts to remove admin while active
        return "Protected Mode is enabled. Please use the designated recovery flow."
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        val manager = ProtectedModeManager.getInstance(context)
        manager.onAdminDisabled()
    }
}
