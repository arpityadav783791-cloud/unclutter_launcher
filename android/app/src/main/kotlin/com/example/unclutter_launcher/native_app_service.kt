package com.example.minimalist_launcher

import android.content.Context
import android.content.Intent

class NativeAppService(
    private val context: Context
) {

    fun getInstalledApps(): List<Map<String, Any>> {

        val packageManager = context.packageManager

        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        val activities = packageManager.queryIntentActivities(
            intent,
            0
        )

        return activities
            .mapNotNull { resolveInfo ->

                val applicationInfo = resolveInfo.activityInfo?.applicationInfo
                    ?: return@mapNotNull null

                val packageName = applicationInfo.packageName

                val appName = packageManager
                    .getApplicationLabel(applicationInfo)
                    .toString()

                mapOf(
                    "name" to appName,
                    "packageName" to packageName,
                    "isLaunchable" to true
                )
            }
            .distinctBy { it["packageName"] }
            .sortedBy {
                it["name"].toString().lowercase()
            }
    }
}