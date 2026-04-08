package com.burnguard.burn_guard

import android.accessibilityservice.AccessibilityService
import android.app.ActivityManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.service.quicksettings.TileService
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.burnguard/overlay"
    private val EVENT_CHANNEL = "com.burnguard/overlay_events"
    private lateinit var systemUIManager: SystemUIManager
    private var stateChangeReceiver: StateChangeReceiver? = null
    private var methodChannel: MethodChannel? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        systemUIManager = SystemUIManager(this)
        systemUIManager.register()
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "hasAccessibilityPermission" -> {
                    result.success(hasAccessibilityPermission())
                }
                "isAccessibilityEnabledInSettings" -> {
                    result.success(isAccessibilityServiceEnabledInSettings())
                }
                "isAccessibilityServiceRunning" -> {
                    result.success(isAccessibilityServiceRunning())
                }
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermission()
                    result.success(true)
                }
                "startOverlay" -> {
                    val config = call.arguments as? Map<*, *>
                    startOverlayService(config)
                    result.success(true)
                }
                "stopOverlay" -> {
                    val args = call.arguments as? Map<*, *>
                    val overlayId = args?.get("id") as? String ?: ""
                    stopOverlayService(overlayId)
                    result.success(true)
                }
                "updateOverlay" -> {
                    val config = call.arguments as? Map<*, *>
                    updateOverlayService(config)
                    result.success(true)
                }
                "isOverlayRunning" -> {
                    val args = call.arguments as? Map<*, *>
                    val overlayId = args?.get("id") as? String ?: ""
                    result.success(OverlayService.isOverlayRunning(overlayId))
                }
                "getRunningOverlays" -> {
                    result.success(OverlayService.getRunningOverlayIds().toList())
                }
                "getRunningOverlayConfigs" -> {
                    result.success(getRunningOverlayConfigs())
                }
                "ensureOverlaysRestored" -> {
                    ensureOverlaysRestored()
                    result.success(true)
                }
                "updateQuickTile" -> {
                    updateQuickTile()
                    result.success(true)
                }
                "getScreenSize" -> {
                    val screenSize = getScreenSize()
                    result.success(screenSize)
                }
                "hideSystemUI" -> {
                    systemUIManager.hideSystemUI()
                    result.success(true)
                }
                "restoreSystemUI" -> {
                    systemUIManager.restoreSystemUI()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    OverlayService.eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    OverlayService.eventSink = null
                }
            })
        
        registerStateChangeReceiver()
    }
    
    private fun registerStateChangeReceiver() {
        stateChangeReceiver = StateChangeReceiver()
        val filter = IntentFilter(OverlayStateBroadcaster.ACTION_STATE_CHANGED)
        LocalBroadcastManager.getInstance(this).registerReceiver(stateChangeReceiver!!, filter)
    }
    
    inner class StateChangeReceiver : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == OverlayStateBroadcaster.ACTION_STATE_CHANGED) {
                val enabled = intent.getBooleanExtra(OverlayStateBroadcaster.EXTRA_ENABLED, false)
                android.util.Log.d("BurnGuard", "Received state change: enabled=$enabled")
                methodChannel?.invokeMethod("onGlobalStateChanged", mapOf("enabled" to enabled))
            }
        }
    }
    
    override fun onDestroy() {
        systemUIManager.unregister()
        stateChangeReceiver?.let {
            LocalBroadcastManager.getInstance(this).unregisterReceiver(it)
        }
        super.onDestroy()
    }
    
    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }
    
    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivity(intent)
        }
    }
    
    private fun hasAccessibilityPermission(): Boolean {
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        
        val serviceName = "${packageName}/${OverlayAccessibilityService::class.java.canonicalName}"
        val isServiceEnabled = OverlayAccessibilityService.isServiceEnabled()
        val isInSettings = enabledServices.contains(packageName) || enabledServices.contains(serviceName)
        
        android.util.Log.d("BurnGuard", "Accessibility check: isServiceEnabled=$isServiceEnabled, isInSettings=$isInSettings")
        
        return isServiceEnabled
    }
    
    private fun isAccessibilityServiceEnabledInSettings(): Boolean {
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        
        val serviceName = "${packageName}/${OverlayAccessibilityService::class.java.canonicalName}"
        return enabledServices.contains(packageName) || enabledServices.contains(serviceName)
    }
    
    private fun isAccessibilityServiceRunning(): Boolean {
        return OverlayAccessibilityService.isServiceEnabled()
    }
    
    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }
    
    private fun startOverlayService(config: Map<*, *>?) {
        val configJson = config?.let { JSONObject(it).toString() } ?: "{}"
        val serviceIntent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_START
            putExtra("config", configJson)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }
    
    private fun stopOverlayService(overlayId: String) {
        val serviceIntent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_STOP
            putExtra("id", overlayId)
        }
        startService(serviceIntent)
    }
    
    private fun updateOverlayService(config: Map<*, *>?) {
        val configJson = config?.let { JSONObject(it).toString() } ?: "{}"
        android.util.Log.d("BurnGuard", "Updating overlay with config: $configJson")
        val serviceIntent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_UPDATE
            putExtra("config", configJson)
        }
        startService(serviceIntent)
    }
    
    private fun getScreenSize(): Map<String, Double> {
        val windowManager = getSystemService(WINDOW_SERVICE) as android.view.WindowManager
        val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display ?: windowManager.defaultDisplay
        } else {
            windowManager.defaultDisplay
        }
        
        val point = android.graphics.Point()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bounds = windowManager.currentWindowMetrics.bounds
            return mapOf(
                "width" to bounds.width().toDouble(),
                "height" to bounds.height().toDouble()
            )
        } else {
            @Suppress("DEPRECATION")
            display.getRealSize(point)
            return mapOf(
                "width" to point.x.toDouble(),
                "height" to point.y.toDouble()
            )
        }
    }
    
    private fun getRunningOverlayConfigs(): List<Map<String, Any>> {
        return OverlayService.getRunningOverlayConfigs()
    }
    
    private fun ensureOverlaysRestored() {
        OverlayService.ensureAccessibilityOverlaysRestored()
    }
    
    private fun updateQuickTile() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            TileService.requestListeningState(
                applicationContext,
                ComponentName(applicationContext, OverlayTileService::class.java)
            )
        }
    }
}
