package com.minimal.launcher

import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.view.accessibility.AccessibilityEvent

class MyAccessibilityService : AccessibilityService() {

    companion object {
        @Volatile
        var instance: MyAccessibilityService? = null
            private set

        fun isRunning(): Boolean = instance != null

        fun goHome(): Boolean {
            val service = instance ?: return false
            return service.performGlobalAction(GLOBAL_ACTION_HOME)
        }

        fun pressBack(): Boolean {
            val service = instance ?: return false
            return service.performGlobalAction(GLOBAL_ACTION_BACK)
        }

        fun lock(): Boolean {
            val service = instance ?: return false
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                service.performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
            } else {
                false
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // No-op
    }

    override fun onInterrupt() {
        // No-op
    }

    override fun onDestroy() {
        if (instance === this) {
            instance = null
        }
        super.onDestroy()
    }
}
