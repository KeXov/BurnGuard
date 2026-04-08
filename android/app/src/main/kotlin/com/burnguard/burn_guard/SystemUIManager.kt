package com.burnguard.burn_guard

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

/**
 * SystemUIManager - 管理系统UI（状态栏和导航栏）的显示/隐藏
 * 
 * 功能：
 * - 当遮罩覆盖状态栏时自动隐藏系统UI
 * - 当遮罩移除后恢复系统UI
 * - 使用沉浸式全屏模式
 */
class SystemUIManager(private val activity: FlutterActivity) {
    
    private var isSystemUIHidden = false
    
    private val systemUIReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                "com.burnguard.action.HIDE_SYSTEM_UI" -> hideSystemUI()
                "com.burnguard.action.RESTORE_SYSTEM_UI" -> restoreSystemUI()
            }
        }
    }
    
    fun register() {
        val filter = IntentFilter().apply {
            addAction("com.burnguard.action.HIDE_SYSTEM_UI")
            addAction("com.burnguard.action.RESTORE_SYSTEM_UI")
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.registerReceiver(systemUIReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            activity.registerReceiver(systemUIReceiver, filter)
        }
    }
    
    fun unregister() {
        try {
            activity.unregisterReceiver(systemUIReceiver)
        } catch (e: Exception) {
            // Receiver might not be registered
        }
    }
    
    /**
     * 隐藏系统UI（状态栏和导航栏）
     * 使用沉浸式全屏模式
     */
    fun hideSystemUI() {
        if (isSystemUIHidden) return
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ (API 30+): 使用 WindowInsetsController
            activity.window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            // Android 11以下: 使用 systemUiVisibility
            @Suppress("DEPRECATION")
            activity.window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                or View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            )
        }
        
        isSystemUIHidden = true
        android.util.Log.d("BurnGuard", "System UI hidden (status bar and navigation bar)")
    }
    
    /**
     * 恢复系统UI
     */
    fun restoreSystemUI() {
        if (!isSystemUIHidden) return
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ (API 30+): 使用 WindowInsetsController
            activity.window.insetsController?.let { controller ->
                controller.show(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
            }
        } else {
            // Android 11以下: 使用 systemUiVisibility
            @Suppress("DEPRECATION")
            activity.window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
        }
        
        isSystemUIHidden = false
        android.util.Log.d("BurnGuard", "System UI restored")
    }
    
    /**
     * 切换系统UI状态
     */
    fun toggleSystemUI() {
        if (isSystemUIHidden) {
            restoreSystemUI()
        } else {
            hideSystemUI()
        }
    }
}
