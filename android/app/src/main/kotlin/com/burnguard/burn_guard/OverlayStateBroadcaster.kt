package com.burnguard.burn_guard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.localbroadcastmanager.content.LocalBroadcastManager

object OverlayStateBroadcaster {
    const val ACTION_STATE_CHANGED = "com.burnguard.ACTION_STATE_CHANGED"
    const val EXTRA_ENABLED = "enabled"
    
    fun sendStateChange(context: Context, enabled: Boolean) {
        val intent = Intent(ACTION_STATE_CHANGED).apply {
            putExtra(EXTRA_ENABLED, enabled)
        }
        LocalBroadcastManager.getInstance(context).sendBroadcast(intent)
        android.util.Log.d("BurnGuard", "Sent state change broadcast: enabled=$enabled")
    }
}
