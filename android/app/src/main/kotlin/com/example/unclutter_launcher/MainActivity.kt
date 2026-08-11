package com.example.minimalist_launcher

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private lateinit var nativeAppService: NativeAppService

    companion object {
        private const val CHANNEL = "minimalist_launcher/native_apps"
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        nativeAppService = NativeAppService(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "getInstalledApps" -> {
                    try {
                        val apps = nativeAppService.getInstalledApps()

                        result.success(apps)
                    } catch (e: Exception) {
                        result.error(
                            "GET_INSTALLED_APPS_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}