package com.minimal.launcher

import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class MyAccessibilityService : AccessibilityService() {

    companion object {
        @Volatile
        var instance: MyAccessibilityService? = null
            private set

        @Volatile
        private var expiredPackage: String? = null

        @Volatile
        var lastForegroundPackage: String? = null

        @Volatile
        var distractionPackages: Set<String> = emptySet()

        fun isRunning(): Boolean = instance != null

        fun setExpiredPackage(packageName: String?) {
            expiredPackage = packageName
            if (!packageName.isNullOrEmpty()) {
                goHome()
            }
        }

        fun clearExpiredPackage() {
            expiredPackage = null
        }

        fun getExpiredPackage(): String? = expiredPackage

        fun goHome(): Boolean {
            val service = instance ?: return false
            return service.performGlobalAction(GLOBAL_ACTION_HOME)
        }

        fun pressBack(): Boolean {
            val service = instance ?: return false
            return service.performGlobalAction(GLOBAL_ACTION_BACK)
        }

        fun dismissPipIfActive(packageName: String?) {
            val service = instance ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try {
                    for (window in service.windows) {
                        val isPip = try {
                            val method = window.javaClass.getMethod("isInPictureInPicture")
                            (method.invoke(window) as? Boolean) == true
                        } catch (_: Exception) {
                            false
                        }
                        if (isPip) {
                            val root = window.root
                            if (root != null) {
                                val pkg = root.packageName?.toString() ?: ""
                                if (packageName.isNullOrEmpty() || pkg == packageName) {
                                    root.performAction(AccessibilityNodeInfo.ACTION_DISMISS)
                                    val closeIds = listOf(
                                        "com.android.systemui:id/close",
                                        "com.android.systemui:id/dismiss",
                                        "com.google.android.youtube:id/close_button",
                                        "com.google.android.youtube:id/player_close_button"
                                    )
                                    for (id in closeIds) {
                                        val nodes = root.findAccessibilityNodeInfosByViewId(id)
                                        for (node in nodes) {
                                            node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                                        }
                                    }
                                    service.performGlobalAction(GLOBAL_ACTION_BACK)
                                }
                            }
                        }
                    }
                } catch (_: Exception) {}
            }
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
        if (event == null) return
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val currentPkg = event.packageName?.toString() ?: return
            lastForegroundPackage = currentPkg

            // 1. Notify overlay manager to display or hide timer based on active app
            UsageTimerOverlayManager.onForegroundPackageChanged(currentPkg)

            // 2. Strict enforcement: if expired package attempts foreground, immediately go home and dismiss PiP
            val expired = expiredPackage
            if (expired != null && expired.isNotEmpty() && currentPkg == expired) {
                goHome()
                dismissPipIfActive(currentPkg)
                return
            }

            // 3. Notification & direct launch interception:
            // If a configured distraction app is launched (e.g. from notification shade) without an active session,
            // immediately go home and bring up Unclutter to show the Timed Access duration prompt.
            if (distractionPackages.contains(currentPkg)) {
                val hasSession = UsageTimerOverlayManager.isSessionOpenFor(currentPkg)
                if (!hasSession) {
                    goHome()
                    dismissPipIfActive(currentPkg)
                    MainActivity.instance?.let { activity ->
                        activity.runOnUiThread {
                            activity.bringLauncherToForegroundAndPrompt(currentPkg)
                        }
                    }
                }
            }
        }
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
