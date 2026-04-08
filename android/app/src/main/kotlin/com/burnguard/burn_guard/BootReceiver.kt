package com.burnguard.burn_guard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            // Start overlay service on boot if enabled
            // This can be extended to check SharedPreferences for auto-start preference
        }
    }
}
