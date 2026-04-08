package com.burnguard.burn_guard

import android.graphics.drawable.Icon
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.content.Intent
import android.os.Build
import org.json.JSONObject

class OverlayTileService : TileService() {
    
    override fun onTileAdded() {
        super.onTileAdded()
        updateTileState()
    }
    
    override fun onStartListening() {
        super.onStartListening()
        OverlayGlobalState.init(applicationContext)
        updateTileState()
    }
    
    override fun onClick() {
        super.onClick()
        
        val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            android.provider.Settings.canDrawOverlays(applicationContext)
        } else {
            true
        }
        
        if (!hasPermission) {
            val intent = Intent(android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                data = android.net.Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivityAndCollapse(intent)
            return
        }
        
        val currentlyEnabled = OverlayGlobalState.isEnabled
        val newEnabled = !currentlyEnabled
        
        android.util.Log.d("BurnGuard", "TileService onClick: currentlyEnabled=$currentlyEnabled, newEnabled=$newEnabled")
        
        if (newEnabled) {
            startAllOverlays()
        } else {
            stopAllOverlays()
        }
        
        OverlayGlobalState.isEnabled = newEnabled
        OverlayGlobalState.saveEnabledState(applicationContext)
        OverlayStateBroadcaster.sendStateChange(applicationContext, newEnabled)
        updateTileState()
    }
    
    private fun startAllOverlays() {
        val configs = OverlayGlobalState.getActiveOverlayConfigs(applicationContext)
        android.util.Log.d("BurnGuard", "TileService starting ${configs.size} overlays")
        
        if (configs.isEmpty()) {
            android.util.Log.d("BurnGuard", "No active overlays to start")
            return
        }
        
        val accessibilityService = OverlayAccessibilityService.getInstance()
        
        if (accessibilityService != null) {
            android.util.Log.d("BurnGuard", "Using accessibility service to start overlays")
            for (config in configs) {
                accessibilityService.startOverlay(config)
            }
        } else {
            android.util.Log.d("BurnGuard", "Using foreground service to start overlays")
            for (config in configs) {
                val intent = Intent(applicationContext, OverlayService::class.java).apply {
                    action = OverlayService.ACTION_START
                    putExtra("config", config)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    applicationContext.startForegroundService(intent)
                } else {
                    applicationContext.startService(intent)
                }
            }
        }
    }
    
    private fun stopAllOverlays() {
        android.util.Log.d("BurnGuard", "TileService stopping all overlays")
        
        val accessibilityService = OverlayAccessibilityService.getInstance()
        if (accessibilityService != null) {
            accessibilityService.stopAllOverlays()
        }
        
        val intent = Intent(applicationContext, OverlayService::class.java).apply {
            action = OverlayService.ACTION_STOP_ALL
        }
        applicationContext.startService(intent)
    }
    
    private fun updateTileState() {
        val tile = qsTile ?: return
        
        val isEnabled = OverlayGlobalState.isEnabled
        val hasActiveOverlays = OverlayGlobalState.hasActiveOverlays(applicationContext)
        
        android.util.Log.d("BurnGuard", "TileService updateTileState: isEnabled=$isEnabled, hasActiveOverlays=$hasActiveOverlays")
        
        tile.state = when {
            isEnabled && hasActiveOverlays -> Tile.STATE_ACTIVE
            hasActiveOverlays -> Tile.STATE_INACTIVE
            else -> Tile.STATE_UNAVAILABLE
        }
        
        tile.label = "BurnGuard"
        tile.subtitle = if (isEnabled) "运行中" else "已停止"
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val iconRes = if (isEnabled) {
                android.R.drawable.ic_menu_close_clear_cancel
            } else {
                android.R.drawable.ic_menu_add
            }
            tile.icon = Icon.createWithResource(applicationContext, iconRes)
        }
        
        tile.updateTile()
    }
}
