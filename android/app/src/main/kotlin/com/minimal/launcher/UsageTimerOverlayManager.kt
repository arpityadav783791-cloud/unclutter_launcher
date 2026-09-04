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
import android.util.DisplayMetrics
import android.util.Log
import android.util.TypedValue
import android.view.ContextThemeWrapper
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Non-intrusive, persistent usage timer overlay for active distraction apps, with
 * in-place expired dialog overlay:
 *
 * 1. While timer runs: A 4dp top progress bar across the screen edge and floating countdown pill.
 *    Non-blocking (FLAG_NOT_TOUCHABLE) so user freely interacts with the distraction app.
 *
 * 2. When timer exhausts: The distraction app remains open underneath, and an in-place modal
 *    overlay popup card appears directly over the app with dimmed scrim:
 *    - [ Extend ] (allows picking 5m / 10m / 15m / 30m to restart timer and continue)
 *    - [ TAKE ME OUT OF HERE ] (completely terminates the distraction app, prevents YouTube PiP,
 *      kills processes, and returns to Unclutter launcher)
 *    - [ Block <AppName> ]
 *    - Time remaining: 0 min
 *    - X h Y min spent today / X h Y min last 7 days
 */
object UsageTimerOverlayManager {

    private const val TAG = "UsageTimerOverlay"

    @Volatile
    private var activePackage: String? = null
    private var appName: String? = null
    private var startedAtMillis: Long = 0L
    private var expiresAtMillis: Long = 0L

    private var currentContext: Context? = null
    private var windowManager: WindowManager? = null
    private var overlayRoot: FrameLayout? = null

    // Running timer views
    private var timerBarContainer: FrameLayout? = null
    private var progressTrack: View? = null
    private var progressFill: View? = null
    private var timeLabel: TextView? = null

    // Expired modal overlay views
    private var expiredContainer: FrameLayout? = null
    private var isExpiredDialogShowing: Boolean = false

    private var isAttached: Boolean = false
    private var isVisibleState: Boolean = false
    private var screenWidthPx: Int = 0

    private val updateHandler = Handler(Looper.getMainLooper())
    private val updateRunnable = object : Runnable {
        override fun run() {
            updateTimerState()
            if (activePackage != null) {
                updateHandler.postDelayed(this, 500L)
            }
        }
    }

    var onSessionExpired: ((String) -> Unit)? = null

    fun startSession(
        context: Context,
        packageName: String,
        appNameStr: String,
        startedAt: Long,
        expiresAt: Long
    ) {
        Log.d(TAG, "startSession: pkg=$packageName, expires=$expiresAt")
        stopSession()

        activePackage = packageName
        appName = appNameStr
        startedAtMillis = startedAt
        expiresAtMillis = expiresAt
        currentContext = context.applicationContext
        isExpiredDialogShowing = false

        ensureOverlayAttachedAndShown()
        updateHandler.post(updateRunnable)
    }

    fun hasActiveSessionFor(packageName: String): Boolean {
        return activePackage != null && activePackage == packageName && System.currentTimeMillis() < expiresAtMillis
    }

    fun isSessionOpenFor(packageName: String): Boolean {
        return activePackage != null && activePackage == packageName
    }

    fun showExpiredCard() {
        val target = activePackage ?: return
        if (!isExpiredDialogShowing) {
            updateHandler.post {
                showExpiredCardOnApp(target)
            }
        }
    }

    fun extendSession(minutes: Int) {
        val target = activePackage ?: return
        val name = appName ?: target
        val now = System.currentTimeMillis()
        val newExpires = now + minutes * 60 * 1000L
        startedAtMillis = now
        expiresAtMillis = newExpires
        isExpiredDialogShowing = false

        // Remove expired card
        expiredContainer?.let { overlayRoot?.removeView(it) }
        expiredContainer = null

        // Restore running bar container
        timerBarContainer?.visibility = View.VISIBLE

        // Restore window layout to top bar and NOT_TOUCHABLE
        val root = overlayRoot
        val wm = windowManager
        if (root != null && wm != null) {
            try {
                val lp = root.layoutParams as? WindowManager.LayoutParams
                if (lp != null) {
                    val density = root.context.resources.displayMetrics.density
                    val resId = root.context.resources.getIdentifier("status_bar_height", "dimen", "android")
                    val statusBarHeightPx = if (resId > 0) root.context.resources.getDimensionPixelSize(resId) else (28 * density).toInt()
                    val totalContainerHeightPx = statusBarHeightPx + (36 * density).toInt()

                    lp.width = WindowManager.LayoutParams.MATCH_PARENT
                    lp.height = totalContainerHeightPx
                    lp.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                    wm.updateViewLayout(root, lp)
                }
            } catch (e: Exception) {
                Log.w(TAG, "Error restoring overlay window size: ${e.message}")
            }
        }

        MainActivity.instance?.let { act ->
            act.notifySessionExtended(target, minutes)
            act.updateSessionExpiry(target, name, newExpires)
        }
    }

    fun stopSession() {
        Log.d(TAG, "stopSession")
        updateHandler.removeCallbacks(updateRunnable)
        activePackage = null
        appName = null
        startedAtMillis = 0L
        expiresAtMillis = 0L
        isExpiredDialogShowing = false

        removeOverlayFromWindow()
    }

    fun onForegroundPackageChanged(currentPkg: String) {
        val target = activePackage ?: return
        if (currentPkg == target) {
            showOverlay()
        } else {
            hideOverlay()
        }
    }

    private fun resolveOverlayEnvironment(): Pair<Context, WindowManager>? {
        val service = MyAccessibilityService.instance
        if (service != null) {
            val wm = service.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            if (wm != null) {
                return Pair(service, wm)
            }
        }

        val appCtx = currentContext ?: return null
        val canDraw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(appCtx)
        } else {
            true
        }

        if (canDraw) {
            val wm = appCtx.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            if (wm != null) {
                return Pair(appCtx, wm)
            }
        }

        Log.w(TAG, "Neither AccessibilityService nor SYSTEM_ALERT_WINDOW capability is active")
        return null
    }

    private fun ensureOverlayAttachedAndShown() {
        val env = resolveOverlayEnvironment() ?: return
        val ctx = env.first
        val wm = env.second
        windowManager = wm

        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        wm.defaultDisplay?.getMetrics(metrics)
        screenWidthPx = metrics.widthPixels.coerceAtLeast(1080)

        ensureOverlayView(ctx)
        showOverlay()
    }

    private fun ensureOverlayView(context: Context) {
        if (overlayRoot != null) return

        val themedContext = ContextThemeWrapper(context, android.R.style.Theme_DeviceDefault)
        val density = themedContext.resources.displayMetrics.density
        val trackHeightPx = (4 * density).toInt().coerceAtLeast(6)

        val resId = themedContext.resources.getIdentifier("status_bar_height", "dimen", "android")
        val statusBarHeightPx = if (resId > 0) {
            themedContext.resources.getDimensionPixelSize(resId)
        } else {
            (28 * density).toInt()
        }
        val totalContainerHeightPx = statusBarHeightPx + (36 * density).toInt()

        val root = FrameLayout(themedContext).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                totalContainerHeightPx
            )
            setBackgroundColor(Color.TRANSPARENT)
            clipChildren = false
            clipToPadding = false
        }

        // ── 1. Running Timer Bar Container ────────────────────────
        val barContainer = FrameLayout(themedContext).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                totalContainerHeightPx,
                Gravity.TOP or Gravity.START
            )
            setBackgroundColor(Color.TRANSPARENT)
            clipChildren = false
            clipToPadding = false
        }

        val track = View(themedContext).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                trackHeightPx,
                Gravity.TOP or Gravity.START
            )
            setBackgroundColor(Color.parseColor("#80000000"))
        }
        barContainer.addView(track)

        val fill = View(themedContext).apply {
            layoutParams = FrameLayout.LayoutParams(
                0,
                trackHeightPx,
                Gravity.TOP or Gravity.START
            )
            setBackgroundColor(Color.parseColor("#FFFFFFFF"))
        }
        barContainer.addView(fill)

        val label = TextView(themedContext).apply {
            val pillBg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 12 * density
                setColor(Color.parseColor("#E6000000"))
                setStroke((1 * density).toInt(), Color.parseColor("#66FFFFFF"))
            }
            background = pillBg
            setTextColor(Color.parseColor("#FFFFFF"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.MONOSPACE
            includeFontPadding = false
            val padH = (10 * density).toInt()
            val padV = (4 * density).toInt()
            setPadding(padH, padV, padH, padV)

            val params = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.TOP or Gravity.END
            ).apply {
                topMargin = statusBarHeightPx + (6 * density).toInt()
                marginEnd = (14 * density).toInt()
            }
            layoutParams = params
            text = "00:00"
        }
        barContainer.addView(label)
        root.addView(barContainer)

        overlayRoot = root
        timerBarContainer = barContainer
        progressTrack = track
        progressFill = fill
        timeLabel = label
    }

    private fun showOverlay() {
        val env = resolveOverlayEnvironment()
        if (env == null) {
            Log.w(TAG, "Cannot showOverlay: no valid overlay environment")
            return
        }

        val ctx = env.first
        val wm = env.second
        windowManager = wm

        ensureOverlayView(ctx)
        val root = overlayRoot ?: return

        if (!isAttached) {
            val isAccessibility = MyAccessibilityService.instance != null
            var windowType = if (isAccessibility) {
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val density = root.context.resources.displayMetrics.density
            val resId = root.context.resources.getIdentifier("status_bar_height", "dimen", "android")
            val statusBarHeightPx = if (resId > 0) {
                root.context.resources.getDimensionPixelSize(resId)
            } else {
                (28 * density).toInt()
            }
            val totalContainerHeightPx = statusBarHeightPx + (36 * density).toInt()

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                if (isExpiredDialogShowing) WindowManager.LayoutParams.MATCH_PARENT else totalContainerHeightPx,
                windowType,
                if (isExpiredDialogShowing) {
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                } else {
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                },
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = 0
                y = 0
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                }
            }

            try {
                wm.addView(root, params)
                isAttached = true
                Log.d(TAG, "Overlay attached to WindowManager with type $windowType")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to attach with $windowType: ${e.message}, trying fallback")
                val appCtx = currentContext
                if (appCtx != null && (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(appCtx))) {
                    val fallbackWm = appCtx.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
                    if (fallbackWm != null) {
                        params.type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                        } else {
                            @Suppress("DEPRECATION")
                            WindowManager.LayoutParams.TYPE_PHONE
                        }
                        try {
                            fallbackWm.addView(root, params)
                            windowManager = fallbackWm
                            isAttached = true
                            Log.d(TAG, "Overlay attached via fallback with type ${params.type}")
                        } catch (e2: Exception) {
                            Log.e(TAG, "Fallback also failed: ${e2.message}")
                            return
                        }
                    } else {
                        return
                    }
                } else {
                    return
                }
            }
        }

        root.visibility = View.VISIBLE
        isVisibleState = true
        updateTimerState()
    }

    private fun hideOverlay() {
        val root = overlayRoot ?: return
        root.visibility = View.GONE
        isVisibleState = false
    }

    private fun removeOverlayFromWindow() {
        val root = overlayRoot ?: return
        val wm = windowManager

        if (isAttached && wm != null) {
            try {
                wm.removeView(root)
                Log.d(TAG, "Overlay removed from WindowManager")
            } catch (e: Exception) {
                Log.w(TAG, "Error removing overlay view: ${e.message}")
            }
            isAttached = false
        }
        isVisibleState = false
        overlayRoot = null
        timerBarContainer = null
        progressTrack = null
        progressFill = null
        timeLabel = null
        expiredContainer = null
        windowManager = null
    }

    private fun updateTimerState() {
        val target = activePackage ?: return
        val now = System.currentTimeMillis()
        val total = (expiresAtMillis - startedAtMillis).coerceAtLeast(1L)
        val elapsed = (now - startedAtMillis).coerceAtLeast(0L)
        val progress = (elapsed.toDouble() / total.toDouble()).coerceIn(0.0, 1.0)
        val remainingMillis = (expiresAtMillis - now).coerceAtLeast(0L)

        // Ensure overlay is attached if environment became available
        if (!isAttached) {
            ensureOverlayAttachedAndShown()
        }

        // Auto-show if foreground package matches target app
        val lastPkg = MyAccessibilityService.lastForegroundPackage
        if (lastPkg != null && lastPkg == target && !isVisibleState) {
            showOverlay()
        }

        // Update progress bar width
        val fill = progressFill
        if (fill != null && screenWidthPx > 0) {
            val fillWidth = (screenWidthPx * progress).toInt().coerceIn(0, screenWidthPx)
            val lp = fill.layoutParams
            if (lp.width != fillWidth) {
                lp.width = fillWidth
                fill.layoutParams = lp
                fill.requestLayout()
            }
        }

        // Update time label
        val label = timeLabel
        if (label != null) {
            val remainingSec = (remainingMillis + 999L) / 1000L
            val mins = remainingSec / 60
            val secs = remainingSec % 60
            label.text = String.format("%02d:%02d", mins, secs)
        }

        // ── In-place Expiration Trigger ───────────────────────────
        if (now >= expiresAtMillis && !isExpiredDialogShowing) {
            Log.d(TAG, "Session expired for $target. Showing in-place modal overlay card on top of app.")
            showExpiredCardOnApp(target)
        }
    }

    /**
     * Renders the exact modal dialog card from the screenshot right over the distraction app.
     * Touches to the app underneath are blocked by a 70% dim scrim.
     */
    private fun showExpiredCardOnApp(targetPackage: String) {
        val root = overlayRoot ?: return
        val wm = windowManager ?: return
        isExpiredDialogShowing = true

        // Hide the thin top bar
        timerBarContainer?.visibility = View.GONE

        // Update WindowManager layout to full screen and remove FLAG_NOT_TOUCHABLE and FLAG_NOT_FOCUSABLE so modal is interactive and can intercept Back key
        try {
            val lp = root.layoutParams as? WindowManager.LayoutParams
            if (lp != null) {
                lp.width = WindowManager.LayoutParams.MATCH_PARENT
                lp.height = WindowManager.LayoutParams.MATCH_PARENT
                lp.flags = WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                wm.updateViewLayout(root, lp)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not expand overlay to full screen: ${e.message}")
        }

        if (expiredContainer != null) {
            root.removeView(expiredContainer)
            expiredContainer = null
        }

        val context = root.context
        val density = context.resources.displayMetrics.density
        val displayName = appName ?: targetPackage

        // 1. Fullscreen Dim Scrim (blocks clicks from passing to app underneath)
        val container = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.parseColor("#B3000000")) // 70% dim black scrim
            isClickable = true
            isFocusable = true
            isFocusableInTouchMode = true
            setOnKeyListener { _, keyCode, event ->
                if (keyCode == KeyEvent.KEYCODE_BACK && event.action == KeyEvent.ACTION_UP) {
                    Log.d(TAG, "Back key pressed on expired overlay: terminating $targetPackage")
                    stopSession()
                    MainActivity.instance?.terminateTargetApp(targetPackage)
                    true
                } else {
                    false
                }
            }
        }

        // 2. Floating Card (matching screenshot)
        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            val cardBg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 24 * density
                setColor(Color.parseColor("#141414")) // AMOLED deep black
                setStroke((1.5f * density).toInt(), Color.WHITE) // White border
            }
            background = cardBg
            val pad = (20 * density).toInt()
            setPadding(pad, (22 * density).toInt(), pad, (22 * density).toInt())

            val cardLp = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            ).apply {
                val marginH = (16 * density).toInt()
                marginStart = marginH
                marginEnd = marginH
            }
            layoutParams = cardLp
        }

        // ── Extension Options Row (revealed when Extend tapped) ─────
        val extOptionsRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = (12 * density).toInt()
            }
            visibility = View.GONE
        }

        fun createPill(minutes: Int, labelStr: String): View {
            return TextView(context).apply {
                val bg = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = 8 * density
                    setColor(Color.parseColor("#222222"))
                    setStroke((1 * density).toInt(), Color.parseColor("#66FFFFFF"))
                }
                background = bg
                text = labelStr
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                val p = LinearLayout.LayoutParams(0, (36 * density).toInt(), 1f).apply {
                    val m = (4 * density).toInt()
                    marginStart = m
                    marginEnd = m
                }
                layoutParams = p
                setOnClickListener {
                    extendSession(minutes)
                }
            }
        }
        extOptionsRow.addView(createPill(5, "5m"))
        extOptionsRow.addView(createPill(10, "10m"))
        extOptionsRow.addView(createPill(15, "15m"))
        extOptionsRow.addView(createPill(30, "30m"))

        // ── Row 1: [ Extend ]  [ TAKE ME OUT OF HERE ] ──────────────
        val row1 = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        val btnExtend = TextView(context).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 10 * density
                setColor(Color.TRANSPARENT)
                setStroke((1.5f * density).toInt(), Color.WHITE)
            }
            background = bg
            text = "Extend"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            val padH = (20 * density).toInt()
            setPadding(padH, 0, padH, 0)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                (44 * density).toInt()
            )
            setOnClickListener {
                extOptionsRow.visibility = if (extOptionsRow.visibility == View.VISIBLE) View.GONE else View.VISIBLE
            }
        }
        row1.addView(btnExtend)

        val spacer1 = View(context).apply {
            layoutParams = LinearLayout.LayoutParams((10 * density).toInt(), 1)
        }
        row1.addView(spacer1)

        val btnTakeMeOut = TextView(context).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 10 * density
                setColor(Color.WHITE)
            }
            background = bg
            text = "TAKE ME OUT OF HERE"
            setTextColor(Color.BLACK)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                0,
                (44 * density).toInt(),
                1f
            )
            setOnClickListener {
                // COMPLETELY TERMINATE TARGET APP & RETURN TO UNCLUTTER
                Log.d(TAG, "TAKE ME OUT OF HERE pressed: terminating $targetPackage")
                stopSession()
                MainActivity.instance?.terminateTargetApp(targetPackage)
            }
        }
        row1.addView(btnTakeMeOut)
        card.addView(row1)

        // Add spacer
        val spacerRow1 = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, (12 * density).toInt())
        }
        card.addView(spacerRow1)

        // ── Row 2: [ Block <AppName> ] ─────────────────────────────
        val btnBlock = TextView(context).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 10 * density
                setColor(Color.TRANSPARENT)
                setStroke((1.5f * density).toInt(), Color.WHITE)
            }
            background = bg
            text = "Block $displayName"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                (44 * density).toInt()
            )
            setOnClickListener {
                Log.d(TAG, "Block app pressed for $targetPackage")
                stopSession()
                MainActivity.instance?.blockDistractionApp(targetPackage)
                MainActivity.instance?.terminateTargetApp(targetPackage)
            }
        }
        card.addView(btnBlock)
        card.addView(extOptionsRow)

        // Spacer before stats
        val spacerStats = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, (22 * density).toInt())
        }
        card.addView(spacerStats)

        // ── Row 3: Time Remaining & Usage Stats ───────────────────
        val row3 = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            gravity = Gravity.BOTTOM
        }

        // Left column: Time remaining 0 min
        val colLeft = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }
        val labelTimeRem = TextView(context).apply {
            text = "Time remaining"
            setTextColor(Color.parseColor("#9E9E9E"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
        }
        val labelZeroMin = TextView(context).apply {
            text = "0 min"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 34f)
            typeface = Typeface.DEFAULT_BOLD
        }
        colLeft.addView(labelTimeRem)
        colLeft.addView(labelZeroMin)
        row3.addView(colLeft)

        // Query usage stats from MainActivity
        var todayStr = "0 min"
        var weekStr = "0 min"
        try {
            val usageMap = MainActivity.instance?.getAppUsage(targetPackage)
            val todayMs = (usageMap?.get("todayMs") as? Number)?.toLong() ?: 0L
            val weekMs = (usageMap?.get("weekMs") as? Number)?.toLong() ?: 0L
            if (todayMs > 0) todayStr = formatDuration(todayMs)
            if (weekMs > 0) weekStr = formatDuration(weekMs)
        } catch (_: Exception) {}

        // Right column: Today / 7 days spent
        val colRight = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.END
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        val textToday = TextView(context).apply {
            val span = android.text.SpannableStringBuilder()
            span.append(todayStr, android.text.style.StyleSpan(Typeface.BOLD), android.text.Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            span.append(" spent today")
            text = span
            setTextColor(Color.parseColor("#9E9E9E"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
        }
        val textWeek = TextView(context).apply {
            val span = android.text.SpannableStringBuilder()
            span.append(weekStr, android.text.style.StyleSpan(Typeface.BOLD), android.text.Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            span.append(" last 7 days")
            text = span
            setTextColor(Color.parseColor("#9E9E9E"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            val p = LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                topMargin = (6 * density).toInt()
            }
            layoutParams = p
        }
        colRight.addView(textToday)
        colRight.addView(textWeek)
        row3.addView(colRight)

        card.addView(row3)
        container.addView(card)
        root.addView(container)
        expiredContainer = container
        container.requestFocus()
    }

    private fun formatDuration(ms: Long): String {
        val totalMinutes = ms / 60000L
        if (totalMinutes < 60) {
            return "${totalMinutes} min"
        }
        val hours = totalMinutes / 60L
        val mins = totalMinutes % 60L
        return if (mins > 0) "${hours} h ${mins} min" else "${hours} h"
    }
}
