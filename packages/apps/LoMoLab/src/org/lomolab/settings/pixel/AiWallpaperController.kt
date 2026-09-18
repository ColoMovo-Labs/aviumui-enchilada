/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings.pixel

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.appcompat.app.AlertDialog
import org.lomolab.settings.R

object AiWallpaperController {

    private const val TAG = "LoMoLabAiWallpaper"

    private val CANDIDATE_INTENTS = listOf(
        Intent().setComponent(ComponentName("com.google.android.apps.wallpaper", "com.google.android.apps.wallpaper.picker.CategoryPickerActivity")),
        Intent().setComponent(ComponentName("com.google.android.apps.aiwallpapers", "com.google.android.apps.aiwallpapers.MainActivity")),
        Intent().setComponent(ComponentName("com.google.android.apps.wallpaper.nexus", "com.google.android.apps.wallpaper.nexus.NexusWallpaper")),
        Intent(Intent.ACTION_SET_WALLPAPER).setPackage("com.google.android.apps.wallpaper")
    )

    fun launchOrShowUnavailable(context: Context) {
        val pm = context.packageManager

        for (intent in CANDIDATE_INTENTS) {
            try {
                val resolved = pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
                if (resolved != null && resolved.activityInfo != null && resolved.activityInfo.exported) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    Log.i(TAG, "Launched AI Wallpaper component: ${resolved.activityInfo.name}")
                    return
                }
            } catch (e: Exception) {
                Log.w(TAG, "Candidate intent resolution failed for $intent", e)
            }
        }

        // Component unavailable - show graceful dialog without crashing
        Log.i(TAG, "AI Wallpaper component unavailable on this system")
        AlertDialog.Builder(context)
            .setTitle(R.string.ai_wallpaper_unavailable_title)
            .setMessage(R.string.ai_wallpaper_unavailable_msg)
            .setPositiveButton(R.string.action_ok, null)
            .show()
    }
}
