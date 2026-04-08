package com.burnguard.burn_guard

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.FrameLayout
import org.json.JSONArray
import org.json.JSONObject
import java.util.Random

/**
 * OverlayAccessibilityService - 无障碍服务实现顶层遮罩
 * 
 * 通过无障碍服务，遮罩可以显示在所有窗口的最顶层，包括状态栏图标
 * 使用 TYPE_ACCESSIBILITY_OVERLAY 窗口类型实现覆盖状态栏
 * 
 * 状态恢复机制：
 * - 遮罩配置持久化到 SharedPreferences
 * - 服务重启时自动恢复之前的遮罩状态
 */
class OverlayAccessibilityService : AccessibilityService() {
    
    companion object {
        private const val PREFS_NAME = "burnguard_overlay_prefs"
        private const val KEY_OVERLAY_CONFIGS = "overlay_configs"
        private const val KEY_SERVICE_ACTIVE = "service_active"
        
        private var instance: OverlayAccessibilityService? = null
        
        fun getInstance(): OverlayAccessibilityService? = instance
        
        fun isServiceEnabled(): Boolean = instance != null
    }
    
    private var windowManager: WindowManager? = null
    private val overlayInstances = mutableMapOf<String, OverlayInstance>()
    private val handler = Handler(Looper.getMainLooper())
    private var prefs: android.content.SharedPreferences? = null
    private var isInitialized = false
    
    private var realScreenWidth: Int = 0
    private var realScreenHeight: Int = 0
    private var statusBarHeight: Int = 0
    private var navigationBarHeight: Int = 0
    
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
    
    private data class OverlayInstance(
        var view: FrameLayout?,
        var config: OverlayConfig,
        var animationRunnable: Runnable?,
        val random: Random
    )
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        android.util.Log.d("BurnGuard", "onServiceConnected called, isInitialized=$isInitialized")
        
        if (isInitialized) {
            android.util.Log.d("BurnGuard", "Already initialized, checking restore")
            ensureRestored()
            return
        }
        
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        isInitialized = true
        
        OverlayGlobalState.init(applicationContext)
        
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPES_ALL_MASK
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REQUEST_TOUCH_EXPLORATION_MODE or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
        
        initializeScreenDimensions()
        
        restoreOverlaysIfNeeded()
        
        android.util.Log.d("BurnGuard", "Accessibility service connected, TYPE_ACCESSIBILITY_OVERLAY enabled, overlays: ${overlayInstances.size}")
    }
    
    fun ensureRestored() {
        android.util.Log.d("BurnGuard", "ensureRestored called, overlayInstances.size=${overlayInstances.size}, prefs=${prefs != null}")
        if (overlayInstances.isEmpty()) {
            if (prefs == null) {
                prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            }
            restoreOverlaysIfNeeded()
        }
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
    }
    
    override fun onInterrupt() {
    }
    
    override fun onDestroy() {
        android.util.Log.d("BurnGuard", "Accessibility service onDestroy called, overlayInstances.size=${overlayInstances.size}")
        saveOverlayConfigs()
        stopAllOverlaysInternal()
        instance = null
        isInitialized = false
        super.onDestroy()
    }
    
    override fun onConfigurationChanged(newConfig: android.content.res.Configuration) {
        super.onConfigurationChanged(newConfig)
        initializeScreenDimensions()
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
        
        android.util.Log.d("BurnGuard", "Accessibility Screen: ${realScreenWidth}x${realScreenHeight}, " +
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
    
    fun startOverlay(configJson: String): Boolean {
        try {
            val config = parseConfig(configJson)
            
            if (overlayInstances.containsKey(config.id)) {
                updateOverlay(configJson)
                return true
            }
            
            val overlayView = createOverlayView(config)
            val params = createLayoutParams(config)
            
            windowManager?.addView(overlayView, params)
            
            val instance = OverlayInstance(
                view = overlayView,
                config = config,
                animationRunnable = null,
                random = Random()
            )
            overlayInstances[config.id] = instance
            
            if (config.mode != "static") {
                startAnimation(config.id)
            }
            
            saveOverlayConfigs()
            updateGlobalState()
            
            android.util.Log.d("BurnGuard", "Accessibility overlay started: ${config.id}")
            return true
        } catch (e: Exception) {
            android.util.Log.e("BurnGuard", "Failed to start overlay", e)
            return false
        }
    }
    
    fun stopOverlay(overlayId: String): Boolean {
        return stopOverlay(overlayId, updateSaved = true)
    }
    
    fun stopOverlay(overlayId: String, updateSaved: Boolean): Boolean {
        try {
            val instance = overlayInstances[overlayId] ?: return false
            
            instance.animationRunnable?.let { handler.removeCallbacks(it) }
            
            instance.view?.let {
                windowManager?.removeView(it)
            }
            
            overlayInstances.remove(overlayId)
            
            if (updateSaved) {
                saveOverlayConfigs()
            }
            
            updateGlobalState()
            
            android.util.Log.d("BurnGuard", "Accessibility overlay stopped: $overlayId, remaining: ${overlayInstances.size}")
            return true
        } catch (e: Exception) {
            android.util.Log.e("BurnGuard", "Failed to stop overlay", e)
            return false
        }
    }
    
    fun updateOverlay(configJson: String): Boolean {
        try {
            val config = parseConfig(configJson)
            val instance = overlayInstances[config.id] ?: return false
            
            instance.animationRunnable?.let { handler.removeCallbacks(it) }
            
            val view = instance.view ?: return false
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
            windowManager?.updateViewLayout(view, params)
            
            instance.config = config
            
            if (config.mode != "static") {
                startAnimation(config.id)
            }
            
            android.util.Log.d("BurnGuard", "Accessibility overlay updated: ${config.id}")
            return true
        } catch (e: Exception) {
            android.util.Log.e("BurnGuard", "Failed to update overlay", e)
            return false
        }
    }
    
    fun stopAllOverlays() {
        stopAllOverlaysInternal()
        clearSavedConfigs()
        OverlayGlobalState.isEnabled = false
        OverlayGlobalState.saveEnabledState(applicationContext)
    }
    
    private fun stopAllOverlaysInternal() {
        overlayInstances.keys.toList().forEach { overlayId ->
            stopOverlayInternal(overlayId)
        }
    }
    
    private fun stopOverlayInternal(overlayId: String) {
        try {
            val inst = overlayInstances[overlayId] ?: return
            inst.animationRunnable?.let { handler.removeCallbacks(it) }
            inst.view?.let { windowManager?.removeView(it) }
            overlayInstances.remove(overlayId)
        } catch (e: Exception) {
            android.util.Log.e("BurnGuard", "Failed to stop overlay internal: $overlayId", e)
        }
    }
    
    fun isOverlayRunning(overlayId: String): Boolean {
        return overlayInstances.containsKey(overlayId)
    }
    
    fun getRunningOverlayIds(): Set<String> {
        return overlayInstances.keys.toSet()
    }
    
    fun getRunningOverlayConfigs(): List<OverlayConfig> {
        return overlayInstances.values.map { it.config }
    }
    
    private fun updateGlobalState() {
        OverlayGlobalState.isEnabled = overlayInstances.isNotEmpty()
        OverlayGlobalState.saveEnabledState(applicationContext)
    }
    
    private fun saveOverlayConfigs() {
        if (overlayInstances.isEmpty()) {
            clearSavedConfigs()
            return
        }
        
        val jsonArray = JSONArray()
        overlayInstances.values.forEach { instance ->
            val json = JSONObject().apply {
                put("id", instance.config.id)
                put("x", instance.config.x)
                put("y", instance.config.y)
                put("width", instance.config.width)
                put("height", instance.config.height)
                put("opacity", instance.config.opacity)
                put("color", instance.config.color)
                put("mode", instance.config.mode)
                put("borderRadius", instance.config.borderRadius)
                put("touchPassthrough", instance.config.touchPassthrough)
                put("driftIntervalSeconds", instance.config.driftIntervalSeconds)
                put("driftPixels", instance.config.driftPixels)
            }
            jsonArray.put(json)
        }
        
        prefs?.edit()?.apply {
            putString(KEY_OVERLAY_CONFIGS, jsonArray.toString())
            putBoolean(KEY_SERVICE_ACTIVE, true)
            apply()
        }
        
        android.util.Log.d("BurnGuard", "Saved ${overlayInstances.size} overlay configs")
    }
    
    private fun clearSavedConfigs() {
        prefs?.edit()?.apply {
            remove(KEY_OVERLAY_CONFIGS)
            putBoolean(KEY_SERVICE_ACTIVE, false)
            apply()
        }
        android.util.Log.d("BurnGuard", "Cleared saved overlay configs")
    }
    
    private fun restoreOverlaysIfNeeded() {
        val configsJson = prefs?.getString(KEY_OVERLAY_CONFIGS, null)
        val wasActive = prefs?.getBoolean(KEY_SERVICE_ACTIVE, false) ?: false
        
        android.util.Log.d("BurnGuard", "restoreOverlaysIfNeeded: wasActive=$wasActive, hasConfigs=${!configsJson.isNullOrEmpty()}, currentOverlays=${overlayInstances.size}")
        
        if (!wasActive || configsJson.isNullOrEmpty()) {
            android.util.Log.d("BurnGuard", "No saved overlays to restore")
            return
        }
        
        if (overlayInstances.isNotEmpty()) {
            android.util.Log.d("BurnGuard", "Overlays already exist, skip restore")
            return
        }
        
        try {
            val jsonArray = JSONArray(configsJson)
            android.util.Log.d("BurnGuard", "Restoring ${jsonArray.length()} overlays from saved config")
            
            for (i in 0 until jsonArray.length()) {
                val json = jsonArray.getJSONObject(i)
                val config = OverlayConfig(
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
                
                startOverlayInternal(config)
            }
            
            android.util.Log.d("BurnGuard", "Restored ${overlayInstances.size} overlays successfully")
        } catch (e: Exception) {
            android.util.Log.e("BurnGuard", "Failed to restore overlays", e)
            clearSavedConfigs()
        }
    }
    
    private fun startOverlayInternal(config: OverlayConfig): Boolean {
        try {
            if (overlayInstances.containsKey(config.id)) {
                return true
            }
            
            val overlayView = createOverlayView(config)
            val params = createLayoutParams(config)
            
            windowManager?.addView(overlayView, params)
            
            val instance = OverlayInstance(
                view = overlayView,
                config = config,
                animationRunnable = null,
                random = Random()
            )
            overlayInstances[config.id] = instance
            
            if (config.mode != "static") {
                startAnimation(config.id)
            }
            
            return true
        } catch (e: Exception) {
            android.util.Log.e("BurnGuard", "Failed to start overlay internal", e)
            return false
        }
    }
    
    private fun createLayoutParams(config: OverlayConfig): WindowManager.LayoutParams {
        val width = if (config.width >= 100f) {
            WindowManager.LayoutParams.MATCH_PARENT
        } else {
            (realScreenWidth * config.width / 100f).toInt()
        }
        
        val height = config.height.toInt()
        
        // 使用无障碍服务的特殊窗口类型
        val type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        
        var flags = 0
        flags = flags or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        flags = flags or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
        flags = flags or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        flags = flags or WindowManager.LayoutParams.FLAG_LAYOUT_IN_OVERSCAN
        
        if (config.touchPassthrough) {
            flags = flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
        }
        
        flags = flags or WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        
        return WindowManager.LayoutParams(
            width,
            height,
            type,
            flags,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = config.x.toInt()
            y = config.y.toInt()
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                layoutInDisplayCutoutMode = 
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
            
            setTitle("BurnGuard Accessibility Overlay - ${config.id}")
        }
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
            OverlayConfig(id = "overlay_${System.currentTimeMillis()}")
        }
    }
    
    private fun parseColor(colorHex: String): Int {
        return try {
            val hex = colorHex.replace("#", "")
            Color.parseColor("#FF$hex")
        } catch (e: Exception) {
            Color.BLACK
        }
    }
    
    private fun startAnimation(overlayId: String) {
        val instance = overlayInstances[overlayId] ?: return
        
        when (instance.config.mode) {
            "drift" -> {
                val intervalMs = (instance.config.driftIntervalSeconds * 1000L)
                val pixels = instance.config.driftPixels
                
                instance.animationRunnable = object : Runnable {
                    override fun run() {
                        instance.view?.let { view ->
                            val params = view.layoutParams as? WindowManager.LayoutParams ?: return@let
                            
                            params.x += instance.random.nextInt(pixels * 2 + 1) - pixels
                            params.y += instance.random.nextInt(pixels * 2 + 1) - pixels
                            
                            windowManager?.updateViewLayout(view, params)
                        }
                        handler.postDelayed(this, intervalMs)
                    }
                }
                handler.postDelayed(instance.animationRunnable!!, intervalMs)
            }
            "breathing" -> {
                // 呼吸动画在无障碍服务中简化处理
            }
            "random" -> {
                val intervalMs = (instance.config.driftIntervalSeconds * 1000L)
                val pixels = instance.config.driftPixels
                
                instance.animationRunnable = object : Runnable {
                    override fun run() {
                        instance.view?.let { view ->
                            val params = view.layoutParams as? WindowManager.LayoutParams ?: return@let
                            
                            params.x += instance.random.nextInt(pixels * 2 + 1) - pixels
                            params.y += instance.random.nextInt(pixels * 2 + 1) - pixels
                            
                            val baseOpacity = instance.config.opacity
                            val newOpacity = baseOpacity + (instance.random.nextFloat() - 0.5f) * 0.1f
                            view.alpha = newOpacity.coerceIn(0.1f, 1.0f)
                            
                            windowManager?.updateViewLayout(view, params)
                        }
                        handler.postDelayed(this, intervalMs)
                    }
                }
                handler.postDelayed(instance.animationRunnable!!, intervalMs)
            }
        }
    }
}
