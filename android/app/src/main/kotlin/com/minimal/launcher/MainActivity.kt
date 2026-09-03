package com.minimal.launcher

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.minimal.launcher/native"
    private var methodChannel: MethodChannel? = null
    private lateinit var protectedModeManager: ProtectedModeManager

    private var activeSessionPackage: String? = null
    private var activeSessionExpiryMillis: Long = 0L
    private val sessionHandler = Handler(Looper.getMainLooper())
    private val sessionExpiryRunnable = Runnable {
        enforceSessionExpiration()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        protectedModeManager = ProtectedModeManager.getInstance(this)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDefaultLauncher" -> {
                        result.success(isDefaultLauncher())
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
                        if (packageName.isNullOrBlank()) {
                            result.error("INVALID_ARGUMENT", "packageName is required", null)
                        } else {
                            result.success(launchApp(packageName))
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
                    // ── Timed Distraction Access ──────────────────
                    "startTimedSession" -> {
                        val packageName = call.argument<String>("packageName") ?: ""
                        val durationSeconds = call.argument<Int>("durationSeconds") ?: 0
                        startTimedSession(packageName, durationSeconds)
                        result.success(null)
                    }
                    "cancelTimedSession" -> {
                        cancelTimedSession()
                        result.success(null)
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
                    else -> result.notImplemented()
                }
            }
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
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null)
        intent.addCategory(Intent.CATEGORY_LAUNCHER)

        val resolveInfos: List<ResolveInfo> = try {
            pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)
        } catch (e: Exception) {
            emptyList()
        }

        val apps = mutableListOf<Map<String, Any?>>()

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

            apps.add(
                mapOf(
                    "name" to appName,
                    "packageName" to pkg,
                    "isSystemApp" to isSystemApp
                )
            )
        }

        return apps.sortedBy { (it["name"] as? String)?.lowercase() ?: "" }
    }

    private fun launchApp(packageName: String): Boolean {
        return try {
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launchIntent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
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

    private fun getAppUsage(packageName: String): Map<String, Any?> {
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

    private fun queryUsage(start: Long, end: Long): List<Map<String, Any?>> {
        val usm = getUsageStatsManager()
        val stats: List<UsageStats> = try {
            usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
                ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }

        // Aggregate by package (query can return multiple intervals)
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

    // ── Timed Session Enforcement ─────────────────────────────

    private fun startTimedSession(packageName: String, durationSeconds: Int) {
        sessionHandler.removeCallbacks(sessionExpiryRunnable)
        activeSessionPackage = packageName
        activeSessionExpiryMillis = System.currentTimeMillis() + (durationSeconds * 1000L)
        sessionHandler.postDelayed(sessionExpiryRunnable, durationSeconds * 1000L)
    }

    private fun cancelTimedSession() {
        sessionHandler.removeCallbacks(sessionExpiryRunnable)
        activeSessionPackage = null
        activeSessionExpiryMillis = 0L
    }

    private fun returnToLauncher() {
        try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            startActivity(intent)
        } catch (e: Exception) {
            // fallback
        }
    }

    private fun enforceSessionExpiration() {
        val expiredPkg = activeSessionPackage ?: ""
        activeSessionPackage = null
        activeSessionExpiryMillis = 0L
        returnToLauncher()
        runOnUiThread {
            methodChannel?.invokeMethod("onSessionExpired", mapOf("packageName" to expiredPkg))
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra("timed_session_expired", false)) {
            val pkg = intent.getStringExtra("expired_package") ?: ""
            runOnUiThread {
                methodChannel?.invokeMethod("onSessionExpired", mapOf("packageName" to pkg))
            }
        }
        if (intent.getBooleanExtra("trigger_recovery", false)) {
            runOnUiThread {
                methodChannel?.invokeMethod("onRecoveryTriggered", null)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        if (activeSessionExpiryMillis > 0 && System.currentTimeMillis() >= activeSessionExpiryMillis) {
            enforceSessionExpiration()
        }
        if (intent.getBooleanExtra("trigger_recovery", false)) {
            intent.removeExtra("trigger_recovery")
            runOnUiThread {
                methodChannel?.invokeMethod("onRecoveryTriggered", null)
            }
        }
    }

    override fun onDestroy() {
        sessionHandler.removeCallbacks(sessionExpiryRunnable)
        super.onDestroy()
    }
}
