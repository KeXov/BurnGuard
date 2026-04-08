package com.burnguard.burn_guard

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

object OverlayGlobalState {
    private const val PREFS_NAME = "burnguard_global_state"
    private const val KEY_ENABLED = "global_enabled"
    
    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
    private const val FLUTTER_OVERLAYS_KEY = "flutter.overlay_configs"
    private const val FLUTTER_ACTIVE_IDS_KEY = "flutter.active_overlay_ids"
    private const val FLUTTER_GLOBAL_ENABLED_KEY = "flutter.global_enabled"
    
    var isEnabled: Boolean = false
        set(value) {
            field = value
            saveEnabledState(lastContext)
        }
    
    private var lastContext: Context? = null
    
    fun init(context: Context) {
        lastContext = context.applicationContext
        isEnabled = loadGlobalEnabled(context)
        android.util.Log.d("BurnGuard", "OverlayGlobalState init, isEnabled=$isEnabled")
    }
    
    private fun loadGlobalEnabled(context: Context): Boolean {
        val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
        return flutterPrefs.getBoolean(FLUTTER_GLOBAL_ENABLED_KEY, false)
    }
    
    fun saveEnabledState(context: Context?) {
        context?.let { ctx ->
            val flutterPrefs = ctx.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            flutterPrefs.edit().putBoolean(FLUTTER_GLOBAL_ENABLED_KEY, isEnabled).apply()
            android.util.Log.d("BurnGuard", "Saved global enabled: $isEnabled")
        }
    }
    
    fun getActiveOverlayConfigs(context: Context): List<String> {
        val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
        
        val overlaysJson = flutterPrefs.getString(FLUTTER_OVERLAYS_KEY, null)
        val activeIdsJson = flutterPrefs.getString(FLUTTER_ACTIVE_IDS_KEY, null)
        
        if (overlaysJson == null || activeIdsJson == null) {
            android.util.Log.d("BurnGuard", "No overlays or active IDs found")
            return emptyList()
        }
        
        return try {
            val activeIds = mutableListOf<String>()
            val activeIdsArray = JSONArray(activeIdsJson)
            for (i in 0 until activeIdsArray.length()) {
                activeIds.add(activeIdsArray.getString(i))
            }
            
            val overlaysArray = JSONArray(overlaysJson)
            val configs = mutableListOf<String>()
            
            for (i in 0 until overlaysArray.length()) {
                val overlayJson = overlaysArray.getJSONObject(i)
                val overlayId = overlayJson.optString("id")
                
                if (activeIds.contains(overlayId)) {
                    configs.add(overlayJson.toString())
                }
            }
            
            android.util.Log.d("BurnGuard", "Found ${configs.size} active overlay configs")
            configs
        } catch (e: Exception) {
            android.util.Log.e("BurnGuard", "Error parsing overlay configs", e)
            emptyList()
        }
    }
    
    fun hasActiveOverlays(context: Context): Boolean {
        val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
        val activeIdsJson = flutterPrefs.getString(FLUTTER_ACTIVE_IDS_KEY, null)
        
        if (activeIdsJson == null) {
            return false
        }
        
        return try {
            val activeIdsArray = JSONArray(activeIdsJson)
            activeIdsArray.length() > 0
        } catch (e: Exception) {
            false
        }
    }
}
