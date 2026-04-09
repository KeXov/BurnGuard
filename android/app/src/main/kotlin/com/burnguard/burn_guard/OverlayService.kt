package com.burnguard.burn_guard

import android.animation.ValueAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject
import java.util.Random

/**
 * OverlayService - 系统级悬浮窗服务
 * 
 * 功能特性：
 * - 支持多个独立遮罩实例
 * - 当遮罩覆盖顶部时，全局隐藏系统UI（状态栏和导航栏）
 * - 在所有应用中都保持系统UI隐藏状态
 * - 支持触摸穿透
 * - 支持多种动画模式
 * - 优先使用无障碍服务（如果已启用），否则使用普通悬浮窗
 */
class OverlayService : Service() {
    
    companion object {
        const val ACTION_START = "com.burnguard.action.START"
        const val ACTION_STOP = "com.burnguard.action.STOP"
        const val ACTION_UPDATE = "com.burnguard.action.UPDATE"
        const val ACTION_STOP_ALL = "com.burnguard.action.STOP_ALL"
        const val CHANNEL_ID = "burnguard_overlay_channel"
        
        private val runningOverlays = mutableSetOf<String>()
        var eventSink: EventChannel.EventSink? = null
        
        fun isOverlayRunning(overlayId: String): Boolean {
            val accessibilityService = OverlayAccessibilityService.getInstance()
            if (accessibilityService != null) {
                return accessibilityService.isOverlayRunning(overlayId)
            }
            return runningOverlays.contains(overlayId)
        }
        
        fun getRunningOverlayIds(): Set<String> {
            val accessibilityService = OverlayAccessibilityService.getInstance()
            if (accessibilityService != null) {
                return accessibilityService.getRunningOverlayIds()
            }
            return runningOverlays.toSet()
        }
        
        fun getRunningOverlayConfigs(): List<Map<String, Any>> {
            val accessibilityService = OverlayAccessibilityService.getInstance()
            if (accessibilityService != null) {
                return accessibilityService.getRunningOverlayConfigs().map { config ->
                    mapOf(
                        "id" to config.id,
                        "x" to config.x,
                        "y" to config.y,
                        "width" to config.width,
                        "height" to config.height,
                        "opacity" to config.opacity,
                        "color" to config.color,
                        "mode" to config.mode,
                        "borderRadius" to config.borderRadius,
                        "touchPassthrough" to config.touchPassthrough,
                        "driftIntervalSeconds" to config.driftIntervalSeconds,
                        "driftPixels" to config.driftPixels
                    )
                }
            }
            return emptyList()
        }
        
        fun isAccessibilityServiceEnabled(): Boolean {
            return OverlayAccessibilityService.isServiceEnabled()
        }
        
        fun ensureAccessibilityOverlaysRestored() {
            val accessibilityService = OverlayAccessibilityService.getInstance()
            accessibilityService?.ensureRestored()
        }
    }
    
    private var windowManager: WindowManager? = null
    private val overlayInstances = mutableMapOf<String, OverlayInstance>()
    private val handler = Handler(Looper.getMainLooper())
    
    private var realScreenWidth: Int = 0
    private var realScreenHeight: Int = 0
    private var statusBarHeight: Int = 0
    private var navigationBarHeight: Int = 0
    
    // 全屏透明覆盖层（用于强制隐藏系统UI）
    private var fullscreenOverlay: FrameLayout? = null
    private var isSystemUIHidden = false
    
    data class OverlayConfig(
        val id: String = "",
        val x: Float = 0f,
        val y: Float = 0f,
        val width: Float = 100f,
        val height: Float = 100f,
        val opacity: Float = 0.15f,
        val color: String = "#000000",
        val mode: String = "static",
        val borderRadius: Float = 0f,
        val touchPassthrough: Boolean = true,
        val driftIntervalSeconds: Int = 10,
        val driftPixels: Int = 5
    )
    
    data class OverlayInstance(
        var view: FrameLayout?,
        var config: OverlayConfig,
        var animationRunnable: Runnable?,
        var breathingAnimator: ValueAnimator?,
        val random: Random
    )
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        initializeScreenDimensions()
        OverlayGlobalState.init(applicationContext)
    }
    
    private fun initializeScreenDimensions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val windowMetrics = windowManager?.currentWindowMetrics
            val bounds = windowMetrics?.bounds
            realScreenWidth = bounds?.width() ?: 1080
            realScreenHeight = bounds?.height() ?: 1920
            
            val windowInsets = windowMetrics?.windowInsets
            val insets = windowInsets?.getInsetsIgnoringVisibility(
                android.view.WindowInsets.Type.systemBars()
            )
            statusBarHeight = insets?.top ?: 0
            navigationBarHeight = insets?.bottom ?: 0
        } else {
            val displayMetrics = DisplayMetrics()
            @Suppress("DEPRECATION")
            windowManager?.defaultDisplay?.getRealMetrics(displayMetrics)
            realScreenWidth = displayMetrics.widthPixels
            realScreenHeight = displayMetrics.heightPixels
            
            statusBarHeight = getStatusBarHeightLegacy()
            navigationBarHeight = getNavigationBarHeightLegacy()
        }
        
        android.util.Log.d("BurnGuard", "Screen: ${realScreenWidth}x${realScreenHeight}, " +
                "StatusBar: ${statusBarHeight}px, NavigationBar: ${navigationBarHeight}px")
    }
    
    private fun getStatusBarHeightLegacy(): Int {
        val resourceId = resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (resourceId > 0) {
            resources.getDimensionPixelSize(resourceId)
        } else {
            (24 * resources.displayMetrics.density).toInt()
        }
    }
    
    private fun getNavigationBarHeightLegacy(): Int {
        val resourceId = resources.getIdentifier("navigation_bar_height", "dimen", "android")
        return if (resourceId > 0) {
            resources.getDimensionPixelSize(resourceId)
        } else {
            0
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val configString = intent.getStringExtra("config")
                val config = parseConfig(configString)
                startOverlay(config)
            }
            ACTION_STOP -> {
                val overlayId = intent.getStringExtra("id") ?: ""
                stopOverlay(overlayId)
                val accessibilityService = OverlayAccessibilityService.getInstance()
                val hasRunningOverlays = if (accessibilityService != null) {
                    accessibilityService.getRunningOverlayIds().isNotEmpty()
                } else {
                    overlayInstances.isNotEmpty()
                }
                if (!hasRunningOverlays) {
                    removeFullscreenOverlay()
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
            }
            ACTION_UPDATE -> {
                val configString = intent.getStringExtra("config")
                val config = parseConfig(configString)
                updateOverlay(config)
            }
            ACTION_STOP_ALL -> {
                stopAllOverlays()
                removeFullscreenOverlay()
                OverlayGlobalState.isEnabled = false
                OverlayGlobalState.saveEnabledState(applicationContext)
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "BurnGuard 防烧屏服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "保持防烧屏遮罩运行"
                setShowBadge(false)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(overlayCount: Int = 1): Notification {
        val contentText = if (overlayCount > 1) {
            "$overlayCount 个遮罩运行中"
        } else {
            "防烧屏功能运行中"
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("BurnGuard")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_menu_manage)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    private fun parseConfig(configString: String?): OverlayConfig {
        return try {
            val json = JSONObject(configString ?: "{}")
            OverlayConfig(
                id = json.optString("id", "overlay_${System.currentTimeMillis()}"),
                x = json.optDouble("x", 0.0).toFloat(),
                y = json.optDouble("y", 0.0).toFloat(),
                width = json.optDouble("width", 100.0).toFloat(),
                height = json.optDouble("height", 100.0).toFloat(),
                opacity = json.optDouble("opacity", 0.15).toFloat(),
                color = json.optString("color", "#000000"),
                mode = json.optString("mode", "static"),
                borderRadius = json.optDouble("borderRadius", 0.0).toFloat(),
                touchPassthrough = json.optBoolean("touchPassthrough", true),
                driftIntervalSeconds = json.optInt("driftIntervalSeconds", 10),
                driftPixels = json.optInt("driftPixels", 5)
            )
        } catch (e: Exception) {
            android.util.Log.e("BurnGuard", "Error parsing config", e)
            OverlayConfig(id = "overlay_${System.currentTimeMillis()}")
        }
    }
    
    /**
     * 检测是否有遮罩覆盖状态栏区域
     */
    private fun shouldHideSystemUI(): Boolean {
        for (instance in overlayInstances.values) {
            val config = instance.config
            // 如果遮罩从顶部开始(y=0)且高度大于等于状态栏高度
            if (config.y == 0f && config.height >= statusBarHeight) {
                return true
            }
        }
        return false
    }
    
    /**
     * 创建全屏透明覆盖层
     * 这个覆盖层会强制系统UI保持隐藏状态
     */
    private fun createFullscreenOverlay() {
        if (fullscreenOverlay != null) return
        
        android.util.Log.d("BurnGuard", "Creating fullscreen overlay to hide system UI")
        
        // 创建一个完全透明的全屏覆盖层
        fullscreenOverlay = FrameLayout(this).apply {
            setBackgroundColor(Color.TRANSPARENT)
            setLayerType(View.LAYER_TYPE_HARDWARE, null)
        }
        
        // 创建布局参数 - 全屏透明窗口
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        
        // 关键Flags组合
        var flags = 0
        flags = flags or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        flags = flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
        flags = flags or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
        flags = flags or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        flags = flags or WindowManager.LayoutParams.FLAG_LAYOUT_IN_OVERSCAN  // 关键：允许覆盖到overscan区域
        flags = flags or WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            flags = flags or WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS
        }
        
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,  // 全屏
            type,
            flags,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 0
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                layoutInDisplayCutoutMode = 
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
            
            setTitle("BurnGuard Fullscreen Overlay")
        }
        
        try {
            // 添加全屏覆盖层（作为底层）
            windowManager?.addView(fullscreenOverlay, params)
            isSystemUIHidden = true
            android.util.Log.d("BurnGuard", "Fullscreen overlay created successfully")
        } catch (e: Exception) {
            android.util.Log.e("BurnGuard", "Failed to create fullscreen overlay", e)
            fullscreenOverlay = null
        }
    }
    
    /**
     * 移除全屏透明覆盖层
     */
    private fun removeFullscreenOverlay() {
        if (fullscreenOverlay == null) return
        
        android.util.Log.d("BurnGuard", "Removing fullscreen overlay")
        
        try {
            windowManager?.removeView(fullscreenOverlay)
        } catch (e: Exception) {
            android.util.Log.e("BurnGuard", "Failed to remove fullscreen overlay", e)
        }
        
        fullscreenOverlay = null
        isSystemUIHidden = false
    }
    
    /**
     * 更新系统UI状态
     */
    private fun updateSystemUIState() {
        if (shouldHideSystemUI()) {
            createFullscreenOverlay()
        } else {
            removeFullscreenOverlay()
        }
    }
    
    private fun createLayoutParams(config: OverlayConfig): WindowManager.LayoutParams {
        val width = if (config.width >= 100f) {
            WindowManager.LayoutParams.MATCH_PARENT
        } else {
            (realScreenWidth * config.width / 100f).toInt()
        }
        
        val height = config.height.toInt()
        
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        
        var flags = 0
        flags = flags or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        flags = flags or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
        flags = flags or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        
        if (config.touchPassthrough) {
            flags = flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
        }
        
        flags = flags or WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            flags = flags or WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS
        }
        
        val params = WindowManager.LayoutParams(
            width,
            height,
            type,
            flags,
            PixelFormat.TRANSLUCENT
        )
        
        params.gravity = Gravity.TOP or Gravity.START
        params.x = config.x.toInt()
        params.y = config.y.toInt()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            params.layoutInDisplayCutoutMode = 
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        
        params.setTitle("BurnGuard Overlay - ${config.id}")
        
        return params
    }
    
    private fun startOverlay(config: OverlayConfig) {
        val accessibilityService = OverlayAccessibilityService.getInstance()
        if (accessibilityService != null) {
            android.util.Log.d("BurnGuard", "Using accessibility service for overlay ${config.id}")
            val configJson = JSONObject().apply {
                put("id", config.id)
                put("x", config.x)
                put("y", config.y)
                put("width", config.width)
                put("height", config.height)
                put("opacity", config.opacity)
                put("color", config.color)
                put("mode", config.mode)
                put("borderRadius", config.borderRadius)
                put("touchPassthrough", config.touchPassthrough)
                put("driftIntervalSeconds", config.driftIntervalSeconds)
                put("driftPixels", config.driftPixels)
            }.toString()
            
            val success = accessibilityService.startOverlay(configJson)
            if (success) {
                runningOverlays.add(config.id)
                eventSink?.success(mapOf("event" to "started", "id" to config.id))
            }
            return
        }
        
        if (overlayInstances.containsKey(config.id)) {
            android.util.Log.d("BurnGuard", "Overlay ${config.id} already running, updating instead")
            updateOverlay(config)
            return
        }
        
        if (overlayInstances.isEmpty()) {
            startForeground(1, createNotification(1))
        } else {
            updateNotification()
        }
        
        runningOverlays.add(config.id)
        
        android.util.Log.d("BurnGuard", "Starting overlay ${config.id} with regular overlay service")
        
        val overlayView = createOverlayView(config)
        val params = createLayoutParams(config)
        
        try {
            windowManager?.addView(overlayView, params)
            android.util.Log.d("BurnGuard", "Overlay added: w=${params.width}, h=${params.height}, " +
                    "x=${params.x}, y=${params.y}, flags=${params.flags}")
        } catch (e: Exception) {
            android.util.Log.e("BurnGuard", "Failed to add overlay view", e)
            runningOverlays.remove(config.id)
            return
        }
        
        val instance = OverlayInstance(
            view = overlayView,
            config = config,
            animationRunnable = null,
            breathingAnimator = null,
            random = Random()
        )
        overlayInstances[config.id] = instance
        
        if (config.mode != "static") {
            startAnimation(config.id)
        }
        
        updateSystemUIState()
        
        eventSink?.success(mapOf("event" to "started", "id" to config.id))
    }
    
    private fun createOverlayView(config: OverlayConfig): FrameLayout {
        return FrameLayout(this).apply {
            val color = parseColor(config.color)
            
            if (config.borderRadius > 0) {
                val shape = GradientDrawable()
                shape.setColor(color)
                shape.cornerRadius = config.borderRadius
                background = shape
            } else {
                setBackgroundColor(color)
            }
            
            alpha = config.opacity
            setLayerType(View.LAYER_TYPE_HARDWARE, null)
        }
    }
    
    private fun stopOverlay(overlayId: String) {
        val accessibilityService = OverlayAccessibilityService.getInstance()
        if (accessibilityService != null) {
            android.util.Log.d("BurnGuard", "Stopping overlay $overlayId via accessibility service")
            accessibilityService.stopOverlay(overlayId)
            runningOverlays.remove(overlayId)
            eventSink?.success(mapOf("event" to "stopped", "id" to overlayId))
            return
        }
        
        val instance = overlayInstances[overlayId] ?: return
        
        stopAnimation(overlayId)
        
        instance.view?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (e: Exception) {
                android.util.Log.e("BurnGuard", "Failed to remove overlay view", e)
            }
        }
        
        overlayInstances.remove(overlayId)
        runningOverlays.remove(overlayId)
        
        updateNotification()
        
        updateSystemUIState()
        
        eventSink?.success(mapOf("event" to "stopped", "id" to overlayId))
        
        android.util.Log.d("BurnGuard", "Stopped overlay $overlayId, remaining: ${overlayInstances.size}")
    }
    
    private fun stopAllOverlays() {
        val accessibilityService = OverlayAccessibilityService.getInstance()
        if (accessibilityService != null) {
            android.util.Log.d("BurnGuard", "Stopping all overlays via accessibility service")
            accessibilityService.stopAllOverlays()
            runningOverlays.clear()
            return
        }
        
        overlayInstances.keys.toList().forEach { overlayId ->
            stopOverlay(overlayId)
        }
    }
    
    private fun updateNotification() {
        val count = overlayInstances.size
        if (count > 0) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.notify(1, createNotification(count))
        }
    }
    
    private fun stopAnimation(overlayId: String) {
        val instance = overlayInstances[overlayId] ?: return
        
        instance.animationRunnable?.let { handler.removeCallbacks(it) }
        instance.animationRunnable = null
        
        instance.breathingAnimator?.cancel()
        instance.breathingAnimator = null
    }
    
    private fun updateOverlay(config: OverlayConfig) {
        val accessibilityService = OverlayAccessibilityService.getInstance()
        if (accessibilityService != null) {
            android.util.Log.d("BurnGuard", "Updating overlay ${config.id} via accessibility service")
            val configJson = JSONObject().apply {
                put("id", config.id)
                put("x", config.x)
                put("y", config.y)
                put("width", config.width)
                put("height", config.height)
                put("opacity", config.opacity)
                put("color", config.color)
                put("mode", config.mode)
                put("borderRadius", config.borderRadius)
                put("touchPassthrough", config.touchPassthrough)
                put("driftIntervalSeconds", config.driftIntervalSeconds)
                put("driftPixels", config.driftPixels)
            }.toString()
            
            accessibilityService.updateOverlay(configJson)
            eventSink?.success(mapOf("event" to "updated", "id" to config.id))
            return
        }
        
        val instance = overlayInstances[config.id] ?: run {
            android.util.Log.d("BurnGuard", "Overlay ${config.id} not running, starting instead")
            startOverlay(config)
            return
        }
        
        android.util.Log.d("BurnGuard", "Updating overlay ${config.id}")
        
        stopAnimation(config.id)
        
        val view = instance.view ?: return
        
        val color = parseColor(config.color)
        if (config.borderRadius > 0) {
            val shape = GradientDrawable()
            shape.setColor(color)
            shape.cornerRadius = config.borderRadius
            view.background = shape
        } else {
            view.setBackgroundColor(color)
        }
        view.alpha = config.opacity
        
        val params = createLayoutParams(config)
        
        try {
            windowManager?.updateViewLayout(view, params)
        } catch (e: Exception) {
            android.util.Log.e("BurnGuard", "Failed to update overlay view", e)
        }
        
        instance.config = config
        
        if (config.mode != "static") {
            startAnimation(config.id)
        }
        
        updateSystemUIState()
        
        eventSink?.success(mapOf("event" to "updated", "id" to config.id))
    }
    
    private fun startAnimation(overlayId: String) {
        val instance = overlayInstances[overlayId] ?: return
        
        when (instance.config.mode) {
            "drift" -> startDriftAnimation(overlayId)
            "breathing" -> startBreathingAnimation(overlayId)
            "random" -> startRandomAnimation(overlayId)
        }
    }
    
    private fun startDriftAnimation(overlayId: String) {
        val instance = overlayInstances[overlayId] ?: return
        val intervalMs = (instance.config.driftIntervalSeconds * 1000L)
        val pixels = instance.config.driftPixels
        
        instance.animationRunnable = object : Runnable {
            override fun run() {
                instance.view?.let { view ->
                    val params = view.layoutParams as? WindowManager.LayoutParams ?: return@let
                    
                    val newX = params.x + instance.random.nextInt(pixels * 2 + 1) - pixels
                    val newY = params.y + instance.random.nextInt(pixels * 2 + 1) - pixels
                    
                    params.x = newX
                    params.y = newY
                    
                    try {
                        windowManager?.updateViewLayout(view, params)
                    } catch (e: Exception) {
                        android.util.Log.e("BurnGuard", "Failed to update drift animation", e)
                    }
                }
                handler.postDelayed(this, intervalMs)
            }
        }
        handler.postDelayed(instance.animationRunnable!!, intervalMs)
    }
    
    private fun startBreathingAnimation(overlayId: String) {
        val instance = overlayInstances[overlayId] ?: return
        val targetOpacity = instance.config.opacity
        
        instance.breathingAnimator = ValueAnimator.ofFloat(targetOpacity * 0.3f, targetOpacity).apply {
            duration = 3000
            repeatMode = ValueAnimator.REVERSE
            repeatCount = ValueAnimator.INFINITE
            interpolator = AccelerateDecelerateInterpolator()
            addUpdateListener { animation ->
                instance.view?.alpha = animation.animatedValue as Float
            }
        }
        instance.breathingAnimator?.start()
    }
    
    private fun startRandomAnimation(overlayId: String) {
        val instance = overlayInstances[overlayId] ?: return
        val intervalMs = (instance.config.driftIntervalSeconds * 1000L)
        val pixels = instance.config.driftPixels
        
        instance.animationRunnable = object : Runnable {
            override fun run() {
                instance.view?.let { view ->
                    val params = view.layoutParams as? WindowManager.LayoutParams ?: return@let
                    
                    val newX = params.x + instance.random.nextInt(pixels * 2 + 1) - pixels
                    val newY = params.y + instance.random.nextInt(pixels * 2 + 1) - pixels
                    val baseOpacity = instance.config.opacity
                    val newOpacity = baseOpacity + (instance.random.nextFloat() - 0.5f) * 0.1f
                    
                    params.x = newX
                    params.y = newY
                    
                    try {
                        windowManager?.updateViewLayout(view, params)
                        view.alpha = newOpacity.coerceIn(0.1f, 1.0f)
                    } catch (e: Exception) {
                        android.util.Log.e("BurnGuard", "Failed to update random animation", e)
                    }
                }
                handler.postDelayed(this, intervalMs)
            }
        }
        handler.postDelayed(instance.animationRunnable!!, intervalMs)
    }
    
    private fun parseColor(colorHex: String): Int {
        return try {
            val hex = colorHex.replace("#", "")
            Color.parseColor("#FF$hex")
        } catch (e: Exception) {
            Color.BLACK
        }
    }
    
    override fun onDestroy() {
        stopAllOverlays()
        removeFullscreenOverlay()
        super.onDestroy()
    }
}
