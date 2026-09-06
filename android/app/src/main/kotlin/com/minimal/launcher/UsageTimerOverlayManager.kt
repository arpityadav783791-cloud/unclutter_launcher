package com.minimal.launcher

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import java.util.concurrent.atomic.AtomicBoolean

/**
 * UsageTimerOverlayManager
 *
 * Implements Layer 1 (Expiry Overlay & Focus Protection):
 * When a Timed Access session expires:
 * 1. Target app remains running underneath (NO Home, NO Back, NO task kill).
 * 2. An authoritative native overlay appears on top of the screen.
 * 3. User chooses between "Extend" and "Take Me Out of Here".
 * 4. Only "Take Me Out of Here" triggers the authoritative termination protocol.
 */
object UsageTimerOverlayManager {
    private const val TAG = "UsageTimerOverlay"
    private val mainHandler = Handler(Looper.getMainLooper())

    private var currentOverlayView: View? = null
    private var currentWindowManager: WindowManager? = null
    private val isOverlayVisible = AtomicBoolean(false)
    private val isDecisionExecuting = AtomicBoolean(false)

    fun showExpiryOverlay(context: Context, sessionId: String, packageName: String) {
        mainHandler.post {
            try {
                if (isOverlayVisible.get()) {
                    Log.d(TAG, "Overlay already visible for session $sessionId")
                    return@post
                }

                // Resolve WindowManager and Context
                val (wm, overlayContext, layoutType) = resolveOverlayContext(context) ?: run {
                    Log.w(TAG, "Cannot display overlay: No overlay permission or accessibility service available.")
                    return@post
                }

                isDecisionExecuting.set(false)

                // Layout parameters: covers full screen, receives touch events, prevents interaction with app underneath
                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    layoutType,
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.CENTER
                }

                val view = createOverlayView(overlayContext, sessionId, packageName)
                wm.addView(view, params)
                currentOverlayView = view
                currentWindowManager = wm
                isOverlayVisible.set(true)
                Log.d(TAG, "Expiry overlay presented for $packageName [sessionId=$sessionId]")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to show expiry overlay: ${e.message}", e)
            }
        }
    }

    fun dismiss() {
        mainHandler.post {
            try {
                val view = currentOverlayView
                val wm = currentWindowManager
                if (view != null && wm != null) {
                    try {
                        wm.removeView(view)
                    } catch (e: Exception) {
                        Log.w(TAG, "Error removing overlay view: ${e.message}")
                    }
                }
            } finally {
                currentOverlayView = null
                currentWindowManager = null
                isOverlayVisible.set(false)
            }
        }
    }

    fun isShowing(): Boolean = isOverlayVisible.get()

    private data class OverlayResolution(
        val windowManager: WindowManager,
        val context: Context,
        val layoutType: Int
    )

    private fun resolveOverlayContext(fallbackContext: Context): OverlayResolution? {
        // Priority 1: Settings.canDrawOverlays -> TYPE_APPLICATION_OVERLAY
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(fallbackContext)) {
            val wm = fallbackContext.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            if (wm != null) {
                val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                }
                return OverlayResolution(wm, fallbackContext, type)
            }
        }

        // Priority 2: MyAccessibilityService.instance -> TYPE_ACCESSIBILITY_OVERLAY
        val accessibilityService = MyAccessibilityService.instance
        if (accessibilityService != null) {
            val wm = accessibilityService.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            if (wm != null) {
                return OverlayResolution(
                    wm,
                    accessibilityService,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                )
            }
        }

        return null
    }

    private fun createOverlayView(context: Context, sessionId: String, packageName: String): View {
        val dp = context.resources.displayMetrics.density

        // Root container: dims the target app underneath
        val root = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT
            )
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#D90A0A0A")) // 85% opacity dark
            isClickable = true
            isFocusable = true
        }

        // Center card
        val card = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                (320 * dp).toInt(),
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins((24 * dp).toInt(), (24 * dp).toInt(), (24 * dp).toInt(), (24 * dp).toInt())
            }
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding((24 * dp).toInt(), (28 * dp).toInt(), (24 * dp).toInt(), (28 * dp).toInt())

            val cardBg = GradientDrawable().apply {
                cornerRadius = 20 * dp
                setColor(Color.parseColor("#1C1C1E"))
                setStroke((1 * dp).toInt(), Color.parseColor("#33FFFFFF"))
            }
            background = cardBg
        }

        val appName = formatPackageName(packageName)

        // Title: "Time is up"
        val titleText = TextView(context).apply {
            text = "Time is up"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        card.addView(titleText)

        // Subtitle: app-specific limit explanation
        val messageText = TextView(context).apply {
            text = "Your timed access for $appName has ended.\nWhat would you like to do?"
            setTextColor(Color.parseColor("#99FFFFFF"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            gravity = Gravity.CENTER
            setLineSpacing(4 * dp, 1f)
            setPadding(0, (12 * dp).toInt(), 0, (24 * dp).toInt())
        }
        card.addView(messageText)

        // Buttons container
        val buttonsContainer = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            orientation = LinearLayout.VERTICAL
        }

        // Button 1: Extend (+5m)
        val extendButton = Button(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                (48 * dp).toInt()
            ).apply {
                bottomMargin = (12 * dp).toInt()
            }
            text = "Extend (+5m)"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            typeface = Typeface.DEFAULT_BOLD
            val btnBg = GradientDrawable().apply {
                cornerRadius = 14 * dp
                setColor(Color.parseColor("#2C2C2E"))
                setStroke((1 * dp).toInt(), Color.parseColor("#44FFFFFF"))
            }
            background = btnBg
            isAllCaps = false

            setOnClickListener {
                if (isDecisionExecuting.compareAndSet(false, true)) {
                    dismiss()
                    MainActivity.instance?.handleOverlayExtend(sessionId, packageName, 5 * 60 * 1000L)
                }
            }
        }
        buttonsContainer.addView(extendButton)

        // Button 2: Take Me Out of Here (Primary exit action)
        val exitButton = Button(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                (48 * dp).toInt()
            )
            text = "Take Me Out of Here"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            typeface = Typeface.DEFAULT_BOLD
            val btnBg = GradientDrawable().apply {
                cornerRadius = 14 * dp
                setColor(Color.parseColor("#E53935")) // Distinct accent red
            }
            background = btnBg
            isAllCaps = false

            setOnClickListener {
                if (isDecisionExecuting.compareAndSet(false, true)) {
                    dismiss()
                    MainActivity.instance?.executeAuthoritativeTermination(sessionId, packageName)
                }
            }
        }
        buttonsContainer.addView(exitButton)

        card.addView(buttonsContainer)
        root.addView(card)

        return root
    }

    private fun formatPackageName(packageName: String): String {
        if (packageName.isBlank()) return "App"
        val parts = packageName.split(".")
        val last = parts.lastOrNull()?.capitalizeFirstLetter() ?: packageName
        return last
    }

    private fun String.capitalizeFirstLetter(): String {
        if (isEmpty()) return this
        return substring(0, 1).uppercase() + substring(1)
    }
}
