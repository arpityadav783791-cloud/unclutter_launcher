package com.minimal.launcher

import android.Manifest
import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.app.usage.UsageEvents
import android.content.Context
import android.content.Intent
import android.content.ComponentName
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.content.pm.LauncherApps
import android.content.pm.LauncherActivityInfo
import android.os.Build
import android.os.UserManager
import android.os.UserHandle
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.app.SearchManager
import android.app.admin.DevicePolicyManager
import android.net.Uri
import android.app.WallpaperManager
import android.graphics.BitmapFactory
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.content.pm.ShortcutInfo
import android.os.BatteryManager
import android.provider.AlarmClock
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.view.KeyEvent
import android.util.Log
import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AlarmManager
import android.app.PendingIntent
import java.util.Calendar

class MainActivity : FlutterActivity() {

    companion object {
        var instance: MainActivity? = null
            private set
    }

    private val CHANNEL = "com.minimal.launcher/native"
    private var methodChannel: MethodChannel? = null
    private lateinit var protectedModeManager: ProtectedModeManager
    private var pendingNotificationResult: MethodChannel.Result? = null
    private val NOTIFICATION_PERMISSION_REQUEST_CODE = 1001


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        instance = this
        protectedModeManager = ProtectedModeManager.getInstance(this)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDefaultLauncher" -> {
                        val isDefault = isDefaultLauncher()
                        if (isDefault) {
                            checkAndApplyBlackWallpaperOnHome()
                        }
                        result.success(isDefault)
                    }
                    "openDefaultLauncherSettings" -> {
                        openDefaultLauncherSettings()
                        result.success(null)
                    }
                    "getInstalledApps" -> {
                        result.success(getInstalledApps())
                    }
                    "launchApp" -> {
                        val packageName = call.argument<String>("packageName")
                        val userSerial = call.argument<Number>("userSerial")?.toLong()
                        val activityName = call.argument<String>("activityName")
                        if (packageName.isNullOrBlank()) {
                            result.error("INVALID_ARGUMENT", "packageName is required", null)
                        } else {
                            result.success(launchApp(packageName, userSerial, activityName))
                        }
                    }
                    "isAppInstalled" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName.isNullOrBlank()) {
                            result.error("INVALID_ARGUMENT", "packageName is required", null)
                        } else {
                            result.success(isAppInstalled(packageName))
                        }
                    }
                    // ── Usage Stats ──────────────────────────────
                    "hasUsagePermission" -> {
                        result.success(hasUsagePermission())
                    }
                    "openUsageAccessSettings" -> {
                        openUsageAccessSettings()
                        result.success(null)
                    }
                    "getTodayUsage" -> {
                        result.success(getTodayUsage())
                    }
                    "getAppUsage" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName.isNullOrBlank()) {
                            result.error("INVALID_ARGUMENT", "packageName is required", null)
                        } else {
                            result.success(getAppUsage(packageName))
                        }
                    }
                    "getWeeklyUsage" -> {
                        result.success(getWeeklyUsage())
                    }
                    "returnToLauncher" -> {
                        returnToLauncher()
                        result.success(null)
                    }
                    // ── Protected Mode ────────────────────────────
                    "isDeviceOwner" -> {
                        result.success(protectedModeManager.isDeviceOwner())
                    }
                    "isProtectedModeEnabled" -> {
                        result.success(protectedModeManager.isProtectedModeEnabled())
                    }
                    "enableProtectedMode" -> {
                        result.success(protectedModeManager.enableProtection())
                    }
                    "disableProtectedMode" -> {
                        result.success(protectedModeManager.disableProtection())
                    }
                    "getProtectedModeState" -> {
                        result.success(protectedModeManager.getState())
                    }
                    "requestDefaultLauncher" -> {
                        protectedModeManager.requestDefaultLauncher()
                        result.success(null)
                    }
                    // ── Notifications ─────────────────────────────
                    "hasNotificationPermission" -> {
                        result.success(hasNotificationPermission())
                    }
                    "requestNotificationPermission" -> {
                        requestNotificationPermission(result)
                    }
                    "isNotificationPermissionRequired" -> {
                        result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                    }
                    "openNotificationSettings" -> {
                        openNotificationSettings()
                        result.success(null)
                    }
                    // ── Enforcement ───────────────────────────────
                    "hasEnforcementPermission" -> {
                        result.success(true)
                    }
                    "isEnforcementPermissionRequired" -> {
                        result.success(false)
                    }
                    "openEnforcementSettings" -> {
                        result.success(null)
                    }
                    // ── Olauncher System & Gesture Actions ─────────
                    "expandStatusBar" -> {
                        expandStatusBar()
                        result.success(null)
                    }
                    "openAppDetails" -> {
                        val pkg = call.argument<String>("packageName")
                        if (pkg != null) {
                            openAppDetails(pkg)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGUMENT", "packageName is required", null)
                        }
                    }
                    "uninstallApp" -> {
                        val pkg = call.argument<String>("packageName")
                        if (pkg != null) {
                            uninstallApp(pkg)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGUMENT", "packageName is required", null)
                        }
                    }
                    "openClock" -> {
                        result.success(openClock())
                    }
                    "openCalendar" -> {
                        result.success(openCalendar())
                    }
                    "getBatteryLevel" -> {
                        result.success(getBatteryLevel())
                    }
                    "openWebSearch" -> {
                        val query = call.argument<String>("query") ?: ""
                        openWebSearch(query)
                        result.success(null)
                    }
                    "lockScreen" -> {
                        result.success(lockScreen())
                    }
                    "isAccessibilityServiceEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettings()
                        result.success(null)
                    }
                    "hasOverlayPermission" -> {
                        val canDraw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            Settings.canDrawOverlays(this)
                        } else {
                            true
                        }
                        val accessEnabled = isAccessibilityServiceEnabled()
                        result.success(canDraw || accessEnabled)
                    }
                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                            try {
                                val intent = Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName")
                                ).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(intent)
                            } catch (_: Exception) {
                                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(intent)
                            }
                        } else if (!isAccessibilityServiceEnabled()) {
                            openAccessibilitySettings()
                        }
                        result.success(null)
                    }
                    "openScreenTimeApp" -> {
                        val customPkg = call.argument<String>("customPackage")
                        result.success(openScreenTimeApp(customPkg))
                    }
                    // ── E-Ink Subsystem ───────────────────────────
                    "isEinkDevice" -> {
                        result.success(isEinkDevice())
                    }
                    // ── Pinned Shortcuts Subsystem ────────────────
                    "getPinnedShortcuts" -> {
                        result.success(getPinnedShortcuts())
                    }
                    "launchShortcut" -> {
                        val pkg = call.argument<String>("packageName") ?: ""
                        val shortcutId = call.argument<String>("shortcutId") ?: ""
                        val userSerial = call.argument<Number>("userSerial")?.toLong()
                        result.success(launchShortcut(pkg, shortcutId, userSerial))
                    }
                    "unpinShortcut" -> {
                        val pkg = call.argument<String>("packageName") ?: ""
                        val shortcutId = call.argument<String>("shortcutId") ?: ""
                        val userSerial = call.argument<Number>("userSerial")?.toLong()
                        result.success(unpinShortcut(pkg, shortcutId, userSerial))
                    }
                    // ── Wallpaper Subsystem ────────────────────────
                    "setWallpaper" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val which = call.argument<Int>("which") ?: 1
                        if (bytes != null) {
                            result.success(setWallpaper(bytes, which))
                        } else {
                            result.error("INVALID_ARGUMENT", "bytes required", null)
                        }
                    }
                    "clearWallpaper" -> {
                        result.success(setBlackWallpaper())
                    }
                    "setBlackWallpaper" -> {
                        result.success(setBlackWallpaper())
                    }
                    // ── Android 15+ Private Space Subsystem ────────
                    "isPrivateSpaceAvailable" -> {
                        result.success(isPrivateSpaceAvailable())
                    }
                    "isPrivateSpaceLocked" -> {
                        result.success(isPrivateSpaceLocked())
                    }
                    "togglePrivateSpace" -> {
                        val requestUnlock = call.argument<Boolean>("requestUnlock") ?: true
                        result.success(togglePrivateSpace(requestUnlock))
                    }
                    "openDeviceSettings" -> {
                        result.success(openDeviceSettings())
                    }
                    // ── Timed Access Monitoring ───────────────────
                    "startTimedSession" -> {
                        val sessionId = call.argument<String>("sessionId")
                        val packageName = call.argument<String>("packageName")
                        val expiresAt = call.argument<Number>("expiresAt")?.toLong() ?: 0L
                        if (sessionId.isNullOrBlank() || packageName.isNullOrBlank() || expiresAt <= 0L) {
                            result.error("INVALID_ARGUMENT", "sessionId, packageName, and expiresAt required", null)
                        } else {
                            startTimedSession(sessionId, packageName, expiresAt)
                            result.success(true)
                        }
                    }
                    "clearTimedSession" -> {
                        val sessionId = call.argument<String>("sessionId")
                        clearTimedSession(sessionId)
                        result.success(true)
                    }
                    "terminateTimedSession" -> {
                        val sessionId = call.argument<String>("sessionId")
                        if (sessionId.isNullOrBlank()) {
                            result.error("INVALID_ARGUMENT", "sessionId is required", null)
                        } else {
                            if (timedSessionId == sessionId) {
                                executeAuthoritativeTermination(sessionId, timedSessionPackage ?: "")
                                result.success(true)
                            } else {
                                // Stale session ID or mismatch -> safely ignore
                                result.success(false)
                            }
                        }
                    }
                    "extendTimedSession" -> {
                        val sessionId = call.argument<String>("sessionId") ?: ""
                        val addedDurationMs = (call.argument<Number>("addedDurationMs"))?.toLong() ?: (5 * 60 * 1000L)
                        val pkg = timedSessionPackage ?: TimedAccessStateStore.getActiveSession(this)?.packageName ?: ""
                        val success = handleOverlayExtend(sessionId, pkg, addedDurationMs)
                        result.success(success)
                    }
                    "setDistractionPackages" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        distractionPackages.clear()
                        distractionPackages.addAll(packages)
                        TimedAccessStateStore.setDistractionPackages(this@MainActivity, packages.toSet())
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Restore native session authority if persisted
        val existingSession = TimedAccessStateStore.getActiveSession(this)
        if (existingSession != null && existingSession.expiresAt > System.currentTimeMillis()) {
            timedSessionId = existingSession.sessionId
            timedSessionPackage = existingSession.packageName
            timedSessionExpiresAt = existingSession.expiresAt
            distractionPackages.add(existingSession.packageName)
        }
        distractionPackages.addAll(TimedAccessStateStore.getDistractionPackages(this))

        handleTimedAccessIntent(intent)

        registerPackageChangeReceiver()
        registerProfileChangeReceiver()
    }

    // ── Launcher helpers ──────────────────────────────────────

    private fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        val resolveInfo = packageManager.resolveActivity(intent, 0)
        return resolveInfo?.activityInfo?.packageName == packageName
    }

    private fun openDefaultLauncherSettings() {
        val intent = Intent(Settings.ACTION_HOME_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as? LauncherApps
        val userManager = getSystemService(Context.USER_SERVICE) as? UserManager
        val myUserHandle = Process.myUserHandle()
        val apps = mutableListOf<Map<String, Any?>>()
        val pm = packageManager

        if (launcherApps != null && userManager != null) {
            val profiles: List<UserHandle> = try {
                userManager.userProfiles
            } catch (e: Exception) {
                listOf(myUserHandle)
            }

            for (user in profiles) {
                val userSerial = try {
                    userManager.getSerialNumberForUser(user)
                } catch (e: Exception) {
                    0L
                }
                val isWorkProfile = (user != myUserHandle)

                val activityList: List<LauncherActivityInfo> = try {
                    launcherApps.getActivityList(null, user)
                } catch (e: Exception) {
                    emptyList()
                }

                for (info in activityList) {
                    val appInfo = info.applicationInfo
                    val pkg = appInfo.packageName ?: continue
                    if (pkg == this.packageName) continue

                    val appName = try {
                        info.label?.toString() ?: pkg
                    } catch (e: Exception) {
                        pkg
                    }

                    val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

                    val isGame = ((appInfo.flags and ApplicationInfo.FLAG_IS_GAME) != 0) ||
                        (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && appInfo.category == ApplicationInfo.CATEGORY_GAME)

                    val category = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        appInfo.category
                    } else {
                        -1
                    }

                    val installTime = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            info.firstInstallTime
                        } catch (_: Exception) {
                            0L
                        }
                    } else {
                        0L
                    }

                    val activityName = try {
                        info.componentName?.className ?: ""
                    } catch (e: Exception) {
                        ""
                    }

                    apps.add(
                        mapOf(
                            "name" to appName,
                            "packageName" to pkg,
                            "isSystemApp" to isSystemApp,
                            "isGame" to isGame,
                            "category" to category,
                            "installTime" to installTime,
                            "userSerial" to userSerial,
                            "isWorkProfile" to isWorkProfile,
                            "activityName" to activityName
                        )
                    )
                }
            }
        }

        // Fallback to queryIntentActivities if LauncherApps returned empty
        if (apps.isEmpty()) {
            val intent = Intent(Intent.ACTION_MAIN, null)
            intent.addCategory(Intent.CATEGORY_LAUNCHER)

            val resolveInfos: List<ResolveInfo> = try {
                pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)
            } catch (e: Exception) {
                emptyList()
            }

            for (info in resolveInfos) {
                val activityInfo = info.activityInfo ?: continue
                val pkg = activityInfo.packageName ?: continue
                if (pkg == this.packageName) continue

                val appName = try {
                    info.loadLabel(pm).toString()
                } catch (e: Exception) {
                    pkg
                }

                val isSystemApp = try {
                    val appInfo = pm.getApplicationInfo(pkg, 0)
                    (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                } catch (e: Exception) {
                    false
                }

                val isGame = try {
                    val appInfo = pm.getApplicationInfo(pkg, 0)
                    ((appInfo.flags and ApplicationInfo.FLAG_IS_GAME) != 0) ||
                        (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && appInfo.category == ApplicationInfo.CATEGORY_GAME)
                } catch (e: Exception) {
                    false
                }

                val category = try {
                    val appInfo = pm.getApplicationInfo(pkg, 0)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        appInfo.category
                    } else {
                        -1
                    }
                } catch (e: Exception) {
                    -1
                }

                val installTime = try {
                    pm.getPackageInfo(pkg, 0).firstInstallTime
                } catch (e: Exception) {
                    0L
                }

                apps.add(
                    mapOf(
                        "name" to appName,
                        "packageName" to pkg,
                        "isSystemApp" to isSystemApp,
                        "isGame" to isGame,
                        "category" to category,
                        "installTime" to installTime,
                        "userSerial" to 0L,
                        "isWorkProfile" to false,
                        "activityName" to (activityInfo.name ?: "")
                    )
                )
            }
        }

        // Guarantee device system Settings is always discoverable in drawer
        val hasDeviceSettings = apps.any {
            val pkg = (it["packageName"] as? String) ?: ""
            pkg == "com.android.settings" || pkg == "android.settings"
        }
        if (!hasDeviceSettings) {
            try {
                val settingsAppInfo = pm.getApplicationInfo("com.android.settings", 0)
                val settingsName = try {
                    settingsAppInfo.loadLabel(pm).toString()
                } catch (_: Exception) {
                    "Settings"
                }
                apps.add(
                    mapOf(
                        "name" to settingsName,
                        "packageName" to "com.android.settings",
                        "isSystemApp" to true,
                        "isGame" to false,
                        "category" to -1,
                        "installTime" to 0L,
                        "userSerial" to 0L,
                        "isWorkProfile" to false,
                        "activityName" to "com.android.settings.Settings"
                    )
                )
            } catch (_: Exception) {}
        }

        return apps.sortedBy { (it["name"] as? String)?.lowercase() ?: "" }
    }

    private fun expandStatusBar() {
        try {
            val statusBarService = getSystemService("statusbar")
            val statusBarManager = Class.forName("android.app.StatusBarManager")
            val method = statusBarManager.getMethod("expandNotificationsPanel")
            method.invoke(statusBarService)
        } catch (e: Exception) {
            try {
                val statusBarService = getSystemService("statusbar")
                val statusBarManager = Class.forName("android.app.StatusBarManager")
                val method = statusBarManager.getMethod("expand")
                method.invoke(statusBarService)
            } catch (e2: Exception) {
                // Ignore failure
            }
        }
    }

    private fun openAppDetails(pkg: String) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", pkg, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e: Exception) {
            val intent = Intent(Settings.ACTION_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        }
    }

    private fun uninstallApp(pkg: String) {
        try {
            val intent = Intent(Intent.ACTION_DELETE).apply {
                data = Uri.fromParts("package", pkg, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e: Exception) {
            // Ignore
        }
    }

    private fun openClock(): Boolean {
        return try {
            val intent = Intent(AlarmClock.ACTION_SHOW_ALARMS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                val knownClocks = listOf(
                    "com.google.android.deskclock",
                    "com.android.deskclock",
                    "com.sec.android.app.clockpackage",
                    "com.oneplus.deskclock",
                    "com.coloros.alarmclock",
                    "com.miui.clock"
                )
                for (p in knownClocks) {
                    val launch = packageManager.getLaunchIntentForPackage(p)
                    if (launch != null) {
                        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(launch)
                        return true
                    }
                }
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun openCalendar(): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_APP_CALENDAR)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                val knownCalendars = listOf(
                    "com.google.android.calendar",
                    "com.android.calendar",
                    "com.samsung.android.calendar",
                    "com.oneplus.calendar",
                    "com.miui.calendar"
                )
                for (p in knownCalendars) {
                    val launch = packageManager.getLaunchIntentForPackage(p)
                    if (launch != null) {
                        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(launch)
                        return true
                    }
                }
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun getBatteryLevel(): Int {
        return try {
            val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } catch (e: Exception) {
            -1
        }
    }

    private fun openWebSearch(query: String) {
        try {
            val intent = Intent(Intent.ACTION_WEB_SEARCH).apply {
                putExtra(SearchManager.QUERY, query)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
            } else {
                val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.google.com/search?q=" + Uri.encode(query))).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(browserIntent)
            }
        } catch (e: Exception) {
            // Ignore
        }
    }

    private fun lockScreen(): Boolean {
        // Priority 1: Accessibility Service (Android 9+ / API 28+)
        // This does not break fingerprint or biometric unlock
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && MyAccessibilityService.isRunning()) {
            if (MyAccessibilityService.lock()) {
                return true
            }
        }

        // Priority 2: Device Admin / Device Owner fallback
        try {
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            if (protectedModeManager.isDeviceOwner()) {
                dpm.lockNow()
                return true
            }
            val adminComponent = android.content.ComponentName(this, ProtectedDeviceAdminReceiver::class.java)
            if (dpm.isAdminActive(adminComponent)) {
                dpm.lockNow()
                return true
            }
        } catch (e: Exception) {
            // Ignore
        }

        return false
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        if (MyAccessibilityService.isRunning()) return true
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val colonSplitter = android.text.TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)
        val expectedComponentName = "${packageName}/${MyAccessibilityService::class.java.canonicalName}"
        val shortComponentName = "${packageName}/.MyAccessibilityService"
        while (colonSplitter.hasNext()) {
            val componentName = colonSplitter.next()
            if (componentName.equals(expectedComponentName, ignoreCase = true) ||
                componentName.equals(shortComponentName, ignoreCase = true) ||
                componentName.contains("MyAccessibilityService")) {
                return true
            }
        }
        return false
    }

    private fun openAccessibilitySettings() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e: Exception) {
            // fallback
        }
    }

    // ── Dynamic Package Change Receiver ───────────────────────

    private var packageChangeReceiver: android.content.BroadcastReceiver? = null

    private fun registerPackageChangeReceiver() {
        if (packageChangeReceiver != null) return
        packageChangeReceiver = object : android.content.BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val action = intent?.action ?: return
                val dataUri = intent.data ?: return
                val pkg = dataUri.schemeSpecificPart ?: return
                if (pkg == packageName) return // Ignore ourselves

                runOnUiThread {
                    methodChannel?.invokeMethod(
                        "onPackagesChanged",
                        mapOf(
                            "packageName" to pkg,
                            "action" to action
                        )
                    )
                }
            }
        }

        val filter = android.content.IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addDataScheme("package")
        }
        registerReceiver(packageChangeReceiver, filter)
    }

    private fun unregisterPackageChangeReceiver() {
        packageChangeReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                // Ignore if already unregistered
            }
            packageChangeReceiver = null
        }
    }

    // ── Dynamic Profile Change Receiver ───────────────────────

    private var profileChangeReceiver: android.content.BroadcastReceiver? = null

    private fun registerProfileChangeReceiver() {
        if (profileChangeReceiver != null) return
        profileChangeReceiver = object : android.content.BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                runOnUiThread {
                    methodChannel?.invokeMethod(
                        "onPackagesChanged",
                        mapOf(
                            "action" to (intent?.action ?: "PROFILE_CHANGE")
                        )
                    )
                }
            }
        }

        val filter = android.content.IntentFilter().apply {
            addAction(Intent.ACTION_MANAGED_PROFILE_AVAILABLE)
            addAction(Intent.ACTION_MANAGED_PROFILE_UNAVAILABLE)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                addAction(Intent.ACTION_MANAGED_PROFILE_UNLOCKED)
            }
            if (Build.VERSION.SDK_INT >= 35) {
                addAction("android.intent.action.PROFILE_AVAILABLE")
                addAction("android.intent.action.PROFILE_UNAVAILABLE")
            }
        }
        try {
            registerReceiver(profileChangeReceiver, filter)
        } catch (_: Exception) {}
    }

    private fun unregisterProfileChangeReceiver() {
        profileChangeReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {}
            profileChangeReceiver = null
        }
    }

    // ── E-Ink Subsystem ───────────────────────────────────────

    private fun isEinkDevice(): Boolean {
        try {
            // 1. Refresh rate check (max supported refresh rate <= 30Hz)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val display = windowManager.defaultDisplay
                val maxRate = display?.supportedModes?.maxOfOrNull { it.refreshRate } ?: 60f
                if (maxRate <= 30.5f) return true
            }

            // 2. Brand & Manufacturer checks
            val brand = (Build.BRAND ?: "").lowercase()
            val manufacturer = (Build.MANUFACTURER ?: "").lowercase()
            val einkBrands = listOf("onyx", "boox", "dasung", "bigme", "boyue", "meebook", "mudita")
            if (einkBrands.any { brand.contains(it) || manufacturer.contains(it) }) return true

            // 3. Hisense e-ink models
            val model = Build.MODEL ?: ""
            val hisenseRegex = Regex("\\bA[579]\\b|TOUCH|HI READER", RegexOption.IGNORE_CASE)
            if (hisenseRegex.containsMatchIn(model)) return true

            // 4. Onyx SDK reflection check
            try {
                Class.forName("android.onyx.ViewUpdateHelper")
                return true
            } catch (_: ClassNotFoundException) {}
        } catch (_: Exception) {}
        return false
    }

    // ── Pinned Shortcuts Subsystem ────────────────────────────

    private fun getPinnedShortcuts(): List<Map<String, Any?>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return emptyList()
        val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as? LauncherApps ?: return emptyList()
        val userManager = getSystemService(Context.USER_SERVICE) as? UserManager ?: return emptyList()
        val result = mutableListOf<Map<String, Any?>>()

        try {
            val profiles = userManager.userProfiles
            for (user in profiles) {
                val userSerial = userManager.getSerialNumberForUser(user)
                val query = LauncherApps.ShortcutQuery().apply {
                    setQueryFlags(LauncherApps.ShortcutQuery.FLAG_MATCH_PINNED)
                }
                val shortcuts = launcherApps.getShortcuts(query, user) ?: continue
                for (shortcut in shortcuts) {
                    val label = shortcut.shortLabel?.toString()
                        ?: shortcut.longLabel?.toString()
                        ?: shortcut.id
                    result.add(
                        mapOf(
                            "id" to shortcut.id,
                            "packageName" to shortcut.`package`,
                            "label" to label,
                            "userSerial" to userSerial,
                            "isEnabled" to shortcut.isEnabled
                        )
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return result
    }

    private fun launchShortcut(packageName: String, shortcutId: String, userSerial: Long?): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as? LauncherApps ?: return false
        val userManager = getSystemService(Context.USER_SERVICE) as? UserManager ?: return false
        val targetUser = if (userSerial != null && userSerial != 0L) {
            userManager.getUserForSerialNumber(userSerial) ?: Process.myUserHandle()
        } else {
            Process.myUserHandle()
        }
        return try {
            launcherApps.startShortcut(packageName, shortcutId, null, null, targetUser)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun unpinShortcut(packageName: String, shortcutId: String, userSerial: Long?): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as? LauncherApps ?: return false
        val userManager = getSystemService(Context.USER_SERVICE) as? UserManager ?: return false
        val targetUser = if (userSerial != null && userSerial != 0L) {
            userManager.getUserForSerialNumber(userSerial) ?: Process.myUserHandle()
        } else {
            Process.myUserHandle()
        }
        return try {
            val query = LauncherApps.ShortcutQuery().apply {
                setPackage(packageName)
                setQueryFlags(LauncherApps.ShortcutQuery.FLAG_MATCH_PINNED)
            }
            val currentShortcuts = launcherApps.getShortcuts(query, targetUser) ?: emptyList()
            val remainingIds = currentShortcuts.map { it.id }.filter { it != shortcutId }
            launcherApps.pinShortcuts(packageName, remainingIds, targetUser)
            true
        } catch (e: Exception) {
            false
        }
    }

    // ── Wallpaper Subsystem ───────────────────────────────────

    private fun setWallpaper(imageBytes: ByteArray, which: Int = 1): Boolean {
        return try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            if (bitmap != null) {
                val wm = WallpaperManager.getInstance(this)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    val flag = when (which) {
                        2 -> WallpaperManager.FLAG_LOCK
                        3 -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                        else -> WallpaperManager.FLAG_SYSTEM
                    }
                    wm.setBitmap(bitmap, null, true, flag)
                } else {
                    wm.setBitmap(bitmap)
                }
                bitmap.recycle()
                true
            } else {
                false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun setBlackWallpaper(): Boolean {
        return try {
            val wm = WallpaperManager.getInstance(this)
            val dm = resources.displayMetrics
            val width = if (dm.widthPixels > 0) dm.widthPixels else 1080
            val height = if (dm.heightPixels > 0) dm.heightPixels else 1920

            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            canvas.drawColor(Color.BLACK)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                wm.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK)
            } else {
                wm.setBitmap(bitmap)
            }
            bitmap.recycle()
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun clearDeviceWallpaper(): Boolean {
        return setBlackWallpaper()
    }

    private fun checkAndApplyBlackWallpaperOnHome(): Boolean {
        return try {
            if (isDefaultLauncher()) {
                val prefs = getSharedPreferences("unclutter_prefs", Context.MODE_PRIVATE)
                val alreadyApplied = prefs.getBoolean("black_wallpaper_set_on_home", false)
                if (!alreadyApplied) {
                    val success = setBlackWallpaper()
                    if (success) {
                        prefs.edit().putBoolean("black_wallpaper_set_on_home", true).apply()
                    }
                    return success
                }
            }
            false
        } catch (_: Exception) {
            false
        }
    }

    // ── Android 15+ Private Space Subsystem ───────────────────

    private fun getPrivateSpaceUserHandle(): UserHandle? {
        val userManager = getSystemService(Context.USER_SERVICE) as? UserManager ?: return null
        val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as? LauncherApps ?: return null
        try {
            for (user in userManager.userProfiles) {
                if (Build.VERSION.SDK_INT >= 35) {
                    val info = launcherApps.getLauncherUserInfo(user)
                    if (info?.userType == "android.os.usertype.profile.PRIVATE") {
                        return user
                    }
                }
            }
        } catch (_: Exception) {}
        return null
    }

    private fun isPrivateSpaceAvailable(): Boolean {
        return getPrivateSpaceUserHandle() != null
    }

    private fun isPrivateSpaceLocked(): Boolean {
        val handle = getPrivateSpaceUserHandle() ?: return false
        val userManager = getSystemService(Context.USER_SERVICE) as? UserManager ?: return false
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                userManager.isQuietModeEnabled(handle)
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun togglePrivateSpace(requestUnlock: Boolean): Boolean {
        val handle = getPrivateSpaceUserHandle() ?: return false
        val userManager = getSystemService(Context.USER_SERVICE) as? UserManager ?: return false
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                userManager.requestQuietModeEnabled(!requestUnlock, handle)
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun openDeviceSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            try {
                val fallbackIntent = Intent().apply {
                    component = ComponentName("com.android.settings", "com.android.settings.Settings")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(fallbackIntent)
                true
            } catch (e2: Exception) {
                try {
                    val pkgIntent = packageManager.getLaunchIntentForPackage("com.android.settings")
                    if (pkgIntent != null) {
                        pkgIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(pkgIntent)
                        true
                    } else {
                        false
                    }
                } catch (e3: Exception) {
                    false
                }
            }
        }
    }

    private fun launchApp(packageName: String, userSerial: Long? = null, activityName: String? = null): Boolean {
        return try {
            // Direct handling for device system settings (ensures reliability across OEMs like Motorola / Samsung)
            if (packageName == "com.android.settings" || packageName == "android.settings" || packageName.endsWith(".settings")) {
                return openDeviceSettings()
            }

            val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as? LauncherApps
            val userManager = getSystemService(Context.USER_SERVICE) as? UserManager
            val myUserHandle = Process.myUserHandle()

            if (launcherApps != null && userManager != null && userSerial != null && userSerial != 0L) {
                val targetUser = userManager.getUserForSerialNumber(userSerial)
                if (targetUser != null) {
                    val component = if (!activityName.isNullOrBlank()) {
                        ComponentName(packageName, activityName)
                    } else {
                        launcherApps.getActivityList(packageName, targetUser).firstOrNull()?.componentName
                    }

                    if (component != null) {
                        launcherApps.startMainActivity(component, targetUser, null, null)
                        return true
                    }
                }
            }

            // Direct Component launch if activityName is known
            if (!activityName.isNullOrBlank()) {
                try {
                    val compIntent = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        component = ComponentName(packageName, activityName)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(compIntent)
                    return true
                } catch (_: Exception) {}
            }

            // Standard / main user launch
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launchIntent)
                true
            } else if (launcherApps != null) {
                val component = launcherApps.getActivityList(packageName, myUserHandle).firstOrNull()?.componentName
                if (component != null) {
                    launcherApps.startMainActivity(component, myUserHandle, null, null)
                    true
                } else {
                    if (packageName.contains("settings", ignoreCase = true)) {
                        openDeviceSettings()
                    } else {
                        false
                    }
                }
            } else {
                if (packageName.contains("settings", ignoreCase = true)) {
                    openDeviceSettings()
                } else {
                    false
                }
            }
        } catch (e: Exception) {
            if (packageName.contains("settings", ignoreCase = true)) {
                openDeviceSettings()
            } else {
                false
            }
        }
    }

    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    // ── Usage Stats ───────────────────────────────────────────

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    private fun getUsageStatsManager(): UsageStatsManager {
        return getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    }

    private fun startOfTodayMillis(): Long {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun startOfWeekMillis(): Long {
        val cal = Calendar.getInstance()
        cal.set(Calendar.DAY_OF_WEEK, cal.firstDayOfWeek)
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    /**
     * Returns list of maps:
     * { packageName, totalTimeInForeground (ms), lastTimeUsed }
     * Sorted by usage descending.
     */
    private fun getTodayUsage(): List<Map<String, Any?>> {
        if (!hasUsagePermission()) return emptyList()

        val end = System.currentTimeMillis()
        val start = startOfTodayMillis()

        return queryUsage(start, end)
    }

    private fun getWeeklyUsage(): List<Map<String, Any?>> {
        if (!hasUsagePermission()) return emptyList()

        val end = System.currentTimeMillis()
        val start = startOfWeekMillis()

        return queryUsage(start, end)
    }

    fun getAppUsage(packageName: String): Map<String, Any?> {
        if (!hasUsagePermission()) {
            return mapOf(
                "packageName" to packageName,
                "todayMs" to 0L,
                "weekMs" to 0L
            )
        }

        val now = System.currentTimeMillis()
        val todayStart = startOfTodayMillis()
        val weekStart = startOfWeekMillis()

        val todayStats = queryUsage(todayStart, now)
        val weekStats = queryUsage(weekStart, now)

        val todayMs = todayStats
            .firstOrNull { it["packageName"] == packageName }
            ?.get("totalTimeInForeground") as? Long ?: 0L

        val weekMs = weekStats
            .firstOrNull { it["packageName"] == packageName }
            ?.get("totalTimeInForeground") as? Long ?: 0L

        return mapOf(
            "packageName" to packageName,
            "todayMs" to todayMs,
            "weekMs" to weekMs
        )
    }

    private fun openScreenTimeApp(customPackage: String?): Boolean {
        // 1. Custom app assigned by user
        if (!customPackage.isNullOrBlank()) {
            val launchIntent = packageManager.getLaunchIntentForPackage(customPackage)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launchIntent)
                return true
            }
        }

        // 2. Google Digital Wellbeing
        val googleWellbeing = packageManager.getLaunchIntentForPackage("com.google.android.apps.wellbeing")
        if (googleWellbeing != null) {
            googleWellbeing.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(googleWellbeing)
            return true
        }

        // 3. Samsung Forest Digital Wellbeing
        val samsungForest = packageManager.getLaunchIntentForPackage("com.samsung.android.forest")
        if (samsungForest != null) {
            samsungForest.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(samsungForest)
            return true
        }

        // 4. Fallback: Power usage summary or Usage Access settings
        try {
            val powerUsage = Intent(Intent.ACTION_POWER_USAGE_SUMMARY).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            if (powerUsage.resolveActivity(packageManager) != null) {
                startActivity(powerUsage)
                return true
            }
        } catch (e: Exception) {
            // ignore
        }

        return try {
            val usageIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(usageIntent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun queryUsage(start: Long, end: Long): List<Map<String, Any?>> {
        val usm = getUsageStatsManager()

        // Priority 1: UsageEvents stream for microsecond-precise, real-time calculation
        try {
            val events = usm.queryEvents(start, end)
            if (events != null) {
                val aggregated = mutableMapOf<String, Long>()
                val lastUsed = mutableMapOf<String, Long>()
                val currentForegroundStart = mutableMapOf<String, Long>()
                val event = UsageEvents.Event()
                var eventCount = 0

                while (events.hasNextEvent()) {
                    events.getNextEvent(event)
                    eventCount++
                    val pkg = event.packageName ?: continue
                    if (pkg == packageName) continue // Skip launcher itself

                    val time = event.timeStamp
                    if (time > (lastUsed[pkg] ?: 0L)) {
                        lastUsed[pkg] = time
                    }

                    when (event.eventType) {
                        UsageEvents.Event.ACTIVITY_RESUMED,
                        UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                            if (currentForegroundStart[pkg] == null) {
                                currentForegroundStart[pkg] = time
                            }
                        }
                        UsageEvents.Event.ACTIVITY_PAUSED,
                        UsageEvents.Event.ACTIVITY_STOPPED,
                        UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                            val startTime = currentForegroundStart.remove(pkg)
                            if (startTime != null && time > startTime) {
                                val duration = time - startTime
                                aggregated[pkg] = (aggregated[pkg] ?: 0L) + duration
                            }
                        }
                    }
                }

                // Close any currently active sessions that didn't receive a background event before 'end'
                for ((pkg, startTime) in currentForegroundStart) {
                    if (end > startTime) {
                        val duration = end - startTime
                        aggregated[pkg] = (aggregated[pkg] ?: 0L) + duration
                    }
                }

                if (eventCount > 0 && aggregated.isNotEmpty()) {
                    return aggregated
                        .filter { it.value > 0 }
                        .map { (pkg, time) ->
                            mapOf(
                                "packageName" to pkg,
                                "totalTimeInForeground" to time,
                                "lastTimeUsed" to (lastUsed[pkg] ?: 0L)
                            )
                        }
                        .sortedByDescending { it["totalTimeInForeground"] as Long }
                }
            }
        } catch (e: Exception) {
            // Fall back to queryUsageStats below
        }

        // Priority 2: Fallback to queryUsageStats (INTERVAL_DAILY)
        val stats: List<UsageStats> = try {
            usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
                ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }

        val aggregated = mutableMapOf<String, Long>()
        val lastUsed = mutableMapOf<String, Long>()

        for (stat in stats) {
            val pkg = stat.packageName ?: continue
            if (pkg == packageName) continue // skip ourselves

            aggregated[pkg] = (aggregated[pkg] ?: 0L) + stat.totalTimeInForeground
            val prev = lastUsed[pkg] ?: 0L
            if (stat.lastTimeUsed > prev) {
                lastUsed[pkg] = stat.lastTimeUsed
            }
        }

        return aggregated
            .filter { it.value > 0 }
            .map { (pkg, time) ->
                mapOf(
                    "packageName" to pkg,
                    "totalTimeInForeground" to time,
                    "lastTimeUsed" to (lastUsed[pkg] ?: 0L)
                )
            }
            .sortedByDescending { it["totalTimeInForeground"] as Long }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Launchers should not close on back press
    }

    private fun returnToLauncher() {
        try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            startActivity(intent)
            runOnUiThread {
                methodChannel?.invokeMethod("onHomePressed", null)
            }
        } catch (_: Exception) {}
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val isHomeAction = (Intent.ACTION_MAIN == intent.action && intent.hasCategory(Intent.CATEGORY_HOME)) ||
                           (intent.flags and Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED != 0)
        if (isHomeAction) {
            runOnUiThread {
                methodChannel?.invokeMethod("onHomePressed", null)
            }
        }
        if (intent.getBooleanExtra("trigger_recovery", false)) {
            runOnUiThread {
                methodChannel?.invokeMethod("onRecoveryTriggered", null)
            }
        }
        handleTimedAccessIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        checkAndApplyBlackWallpaperOnHome()
        if (intent.getBooleanExtra("trigger_recovery", false)) {
            intent.removeExtra("trigger_recovery")
            runOnUiThread {
                methodChannel?.invokeMethod("onRecoveryTriggered", null)
            }
        }
    }

    // ── Notifications ─────────────────────────────────────────

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else {
            NotificationManagerCompat.from(this).areNotificationsEnabled()
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                result.success(true)
            } else {
                pendingNotificationResult = result
                requestPermissions(
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_REQUEST_CODE
                )
            }
        } else {
            result.success(NotificationManagerCompat.from(this).areNotificationsEnabled())
        }
    }

    private fun openNotificationSettings() {
        try {
            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e: Exception) {
            val intent = Intent(Settings.ACTION_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingNotificationResult?.success(granted)
            pendingNotificationResult = null
        }
    }

    private fun handleTimedAccessIntent(intent: Intent?) {
        val expiredId = intent?.getStringExtra("timed_access_expired_session_id")
        val expiredPkg = intent?.getStringExtra("timed_access_expired_package")
        if (!expiredId.isNullOrBlank() && !expiredPkg.isNullOrBlank()) {
            timedSessionHandler.postDelayed({
                notifyTimedAccessExpired(expiredId, expiredPkg)
            }, 300)
        }
    }

    // ── Timed Access Monitoring Subsystem ──────────────────────
    private var timedSessionId: String? = null
    private var timedSessionPackage: String? = null
    private var timedSessionExpiresAt: Long = 0L
    private val timedSessionHandler = Handler(Looper.getMainLooper())
    private val timedSessionRunnable = Runnable {
        triggerTimedAccessExpiry()
    }
    private val distractionPackages: MutableSet<String> = java.util.concurrent.ConcurrentHashMap.newKeySet()
    private val isTerminating = java.util.concurrent.atomic.AtomicBoolean(false)

    fun isDistractionApp(pkg: String): Boolean {
        return TimedAccessStateStore.isDistractionPackage(this, pkg) ||
               distractionPackages.contains(pkg) ||
               timedSessionPackage == pkg
    }

    fun isSessionValidFor(pkg: String): Boolean {
        return TimedAccessStateStore.isSessionValid(this, pkg)
    }

    fun bringLauncherToFront() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.w("MainActivity", "bringLauncherToFront failed: ${e.message}")
        }
    }

    fun notifyDistractionIntercepted(packageName: String) {
        timedSessionHandler.post {
            methodChannel?.invokeMethod("onDistractionIntercepted", mapOf(
                "packageName" to packageName
            ))
        }
    }

    private fun pauseMedia() {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (audioManager != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val playbackAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                    val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                        .setAudioAttributes(playbackAttributes)
                        .setAcceptsDelayedFocusGain(false)
                        .setOnAudioFocusChangeListener { /* no-op */ }
                        .build()
                    audioManager.requestAudioFocus(focusRequest)
                    timedSessionHandler.postDelayed({
                        try { audioManager.abandonAudioFocusRequest(focusRequest) } catch (_: Exception) {}
                    }, 400)
                } else {
                    @Suppress("DEPRECATION")
                    audioManager.requestAudioFocus(null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN)
                    timedSessionHandler.postDelayed({
                        @Suppress("DEPRECATION")
                        try { audioManager.abandonAudioFocus(null) } catch (_: Exception) {}
                    }, 400)
                }
            }
        } catch (e: Exception) {
            Log.w("MainActivity", "pauseMedia failed: ${e.message}")
        }
    }

    fun executeAuthoritativeTermination(sessionId: String, targetPackage: String) {
        if (!isTerminating.compareAndSet(false, true)) {
            Log.d("TimedAccess", "executeAuthoritativeTermination ignored (already terminating): [sessionId=$sessionId, pkg=$targetPackage]")
            return
        }
        Log.d("TimedAccess", "executeAuthoritativeTermination starting: [sessionId=$sessionId, pkg=$targetPackage]")

        // Dismiss any active overlay immediately
        UsageTimerOverlayManager.dismiss()
        TimedAccessStateStore.setSessionState(this, TimedAccessStateStore.STATE_TERMINATING)

        try {
            // 1. Cancel pending native Handler callbacks
            try {
                timedSessionHandler.removeCallbacks(timedSessionRunnable)
            } catch (e: Exception) {
                Log.w("TimedAccess", "Handler cancel failed: ${e.message}")
            }

            // 2. Cancel exact AlarmManager expiry PendingIntent
            try {
                cancelAlarm()
            } catch (e: Exception) {
                Log.w("TimedAccess", "Alarm cancel failed: ${e.message}")
            }

            // 3. Pause media playback
            try {
                pauseMedia()
            } catch (e: Exception) {
                Log.w("TimedAccess", "pauseMedia failed: ${e.message}")
            }

            // 4. Perform Back where appropriate
            try {
                MyAccessibilityService.pressBack()
            } catch (e: Exception) {
                Log.w("TimedAccess", "pressBack failed: ${e.message}")
            }

            // 5. Perform Home exit protocol
            try {
                MyAccessibilityService.goHome()
            } catch (e: Exception) {
                Log.w("TimedAccess", "goHome failed: ${e.message}")
            }
            try {
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                startActivity(homeIntent)
            } catch (e: Exception) {
                Log.w("TimedAccess", "Home intent launch failed: ${e.message}")
            }

            // 6. Attempt PiP dismissal through existing AccessibilityService
            try {
                MyAccessibilityService.dismissPip(targetPackage)
            } catch (e: Exception) {
                Log.w("TimedAccess", "PiP dismissal failed: ${e.message}")
            }

            // 7. Remove target application task from Recents / Overview
            try {
                val am = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    val appTasks = am?.appTasks
                    if (appTasks != null) {
                        for (task in appTasks) {
                            val basePkg = task.taskInfo?.baseIntent?.component?.packageName
                            if (basePkg == targetPackage) {
                                task.finishAndRemoveTask()
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                Log.w("TimedAccess", "Task removal failed: ${e.message}")
            }

            // 8. Request background process cleanup where Android permits it
            try {
                val am = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                am?.killBackgroundProcesses(targetPackage)
            } catch (e: Exception) {
                Log.w("TimedAccess", "killBackgroundProcesses failed: ${e.message}")
            }

            // 9. Apply existing Device Owner enforcement if app is Device Owner
            try {
                if (protectedModeManager.isDeviceOwner()) {
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
                    val adminComponent = ComponentName(this, ProtectedDeviceAdminReceiver::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        dpm?.setPackagesSuspended(adminComponent, arrayOf(targetPackage), true)
                        timedSessionHandler.postDelayed({
                            try {
                                dpm?.setPackagesSuspended(adminComponent, arrayOf(targetPackage), false)
                            } catch (_: Exception) {}
                        }, 500)
                    }
                }
            } catch (e: Exception) {
                Log.w("TimedAccess", "Device Owner suspension failed: ${e.message}")
            }

            // 10. Return Unclutter/MainActivity to foreground
            try {
                bringLauncherToFront()
            } catch (e: Exception) {
                Log.w("TimedAccess", "bringLauncherToFront failed: ${e.message}")
            }

            // 11. Delayed PiP checks (at 250ms and 500ms) because PiP can appear asynchronously
            timedSessionHandler.postDelayed({
                try {
                    MyAccessibilityService.dismissPip(targetPackage)
                } catch (_: Exception) {}
            }, 250)
            timedSessionHandler.postDelayed({
                try {
                    MyAccessibilityService.dismissPip(targetPackage)
                } catch (_: Exception) {}
            }, 500)

            // 12. Notify Flutter that the session was terminated
            timedSessionHandler.post {
                try {
                    methodChannel?.invokeMethod("onSessionTerminated", mapOf(
                        "sessionId" to sessionId,
                        "packageName" to targetPackage
                    ))
                } catch (e: Exception) {
                    Log.w("TimedAccess", "onSessionTerminated invoke failed: ${e.message}")
                }
            }

            // 13. Clear native session state & persistence
            try {
                TimedAccessStateStore.clearSession(this, sessionId)
            } catch (e: Exception) {
                Log.w("TimedAccess", "clearSession failed: ${e.message}")
            }
            timedSessionId = null
            timedSessionPackage = null
            timedSessionExpiresAt = 0L
        } finally {
            isTerminating.set(false)
        }
    }

    private fun startTimedSession(sessionId: String, packageName: String, expiresAt: Long) {
        // Cancel previous session & alarms cleanly
        clearTimedSession(null)
        UsageTimerOverlayManager.dismiss()

        timedSessionId = sessionId
        timedSessionPackage = packageName
        timedSessionExpiresAt = expiresAt
        distractionPackages.add(packageName)

        // Persist authoritatively in native storage with ACTIVE state
        TimedAccessStateStore.saveSession(this, sessionId, packageName, expiresAt, TimedAccessStateStore.STATE_ACTIVE)

        // Schedule Handler callback for current session
        val delayMs = Math.max(0L, expiresAt - System.currentTimeMillis())
        timedSessionHandler.removeCallbacks(timedSessionRunnable)
        timedSessionHandler.postDelayed(timedSessionRunnable, delayMs)

        // Schedule exact AlarmManager alarm
        scheduleAlarm(sessionId, packageName, expiresAt)
    }

    fun handleOverlayExtend(sessionId: String, packageName: String, addedDurationMs: Long): Boolean {
        return try {
            UsageTimerOverlayManager.dismiss()

            val active = TimedAccessStateStore.getActiveSession(this)
            val effectiveSessionId = if (sessionId.isNotBlank()) sessionId else active?.sessionId ?: ""
            val effectivePkg = if (packageName.isNotBlank()) packageName else active?.packageName ?: ""

            if (effectiveSessionId.isBlank() || effectivePkg.isBlank()) {
                false
            } else {
                val newExpiresAt = System.currentTimeMillis() + addedDurationMs
                timedSessionId = effectiveSessionId
                timedSessionPackage = effectivePkg
                timedSessionExpiresAt = newExpiresAt

                // Save to native store with ACTIVE state
                TimedAccessStateStore.saveSession(this, effectiveSessionId, effectivePkg, newExpiresAt, TimedAccessStateStore.STATE_ACTIVE)

                // Reschedule Handler callback
                timedSessionHandler.removeCallbacks(timedSessionRunnable)
                timedSessionHandler.postDelayed(timedSessionRunnable, addedDurationMs)

                // Reschedule exact AlarmManager alarm
                scheduleAlarm(effectiveSessionId, effectivePkg, newExpiresAt)

                // Notify Flutter
                timedSessionHandler.post {
                    methodChannel?.invokeMethod("onSessionExtended", mapOf(
                        "sessionId" to effectiveSessionId,
                        "packageName" to effectivePkg,
                        "expiresAt" to newExpiresAt
                    ))
                }
                true
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "handleOverlayExtend failed: ${e.message}", e)
            false
        }
    }

    private fun scheduleAlarm(sessionId: String, packageName: String, expiresAt: Long) {
        try {
            cancelAlarm()
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            val intent = Intent(this, TimedExpiryReceiver::class.java).apply {
                putExtra("sessionId", sessionId)
                putExtra("packageName", packageName)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                9090,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager?.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, expiresAt, pendingIntent)
            } else {
                alarmManager?.setExact(AlarmManager.RTC_WAKEUP, expiresAt, pendingIntent)
            }
        } catch (e: Exception) {
            Log.w("MainActivity", "AlarmManager scheduling failed: ${e.message}")
        }
    }

    private fun cancelAlarm() {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            val intent = Intent(this, TimedExpiryReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                9090,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pendingIntent != null) {
                alarmManager?.cancel(pendingIntent)
                pendingIntent.cancel()
            }
        } catch (e: Exception) {
            Log.w("MainActivity", "AlarmManager cancel failed: ${e.message}")
        }
    }

    private fun clearTimedSession(sessionId: String?) {
        if (sessionId == null || timedSessionId == sessionId) {
            UsageTimerOverlayManager.dismiss()
            timedSessionHandler.removeCallbacks(timedSessionRunnable)
            cancelAlarm()
            TimedAccessStateStore.clearSession(this, sessionId)
            timedSessionId = null
            timedSessionPackage = null
            timedSessionExpiresAt = 0L
        }
    }

    fun triggerTimedAccessExpiry() {
        val sId = timedSessionId ?: return
        val pkg = timedSessionPackage ?: return
        notifyTimedAccessExpired(sId, pkg)
    }

    fun notifyTimedAccessExpired(sessionId: String, packageName: String) {
        // Stale callback protection: ignore if not matching active session
        val active = TimedAccessStateStore.getActiveSession(this)
        if (active != null && active.sessionId != sessionId) {
            Log.w("MainActivity", "Ignoring stale notifyTimedAccessExpired for $sessionId (active: ${active.sessionId})")
            return
        }

        // Set native state to EXPIRED_WAITING
        TimedAccessStateStore.setSessionState(this, TimedAccessStateStore.STATE_EXPIRED_WAITING)

        // Layer 1: Display native overlay over target app (Target app stays underneath! NO Home!)
        UsageTimerOverlayManager.showExpiryOverlay(this, sessionId, packageName)

        if (timedSessionId == null || timedSessionId == sessionId) {
            timedSessionHandler.post {
                methodChannel?.invokeMethod("onTimedAccessExpired", mapOf(
                    "sessionId" to sessionId,
                    "packageName" to packageName
                ))
            }
        }
    }

    override fun onDestroy() {
        if (instance === this) {
            instance = null
        }
        UsageTimerOverlayManager.dismiss()
        timedSessionHandler.removeCallbacks(timedSessionRunnable)
        unregisterPackageChangeReceiver()
        unregisterProfileChangeReceiver()
        super.onDestroy()
    }
}
