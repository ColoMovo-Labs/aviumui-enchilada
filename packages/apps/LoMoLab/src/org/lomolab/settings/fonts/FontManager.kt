/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings.fonts

import android.content.Context
import android.content.om.OverlayManager
import android.os.Process
import android.os.UserHandle
import android.provider.Settings
import android.util.Log
import org.json.JSONObject

object FontManager {

    private const val TAG = "LoMoLabFontManager"
    private const val CATEGORY_FONT = "android.theme.customization.font"
    private const val SETTING_THEME_CUSTOMIZATION = "theme_customization_overlay_packages"
    private const val KEY_LOMOLAB_CUSTOM_FONT = "lomolab_custom_font"

    val FONT_OVERLAYS = listOf(
        "org.avium.overlay.font.smileysans",
        "org.avium.overlay.font.lxgwwenkai",
        "org.avium.overlay.font.lxgwneoxihei",
        "org.avium.overlay.font.xiaolai",
        "org.avium.overlay.font.notoserifsc",
        "org.avium.overlay.font.zcoolqingkehuangyou",
        "org.avium.overlay.font.zcoolxiaowei",
        "org.avium.overlay.font.zcoolkuaile",
        "org.avium.overlay.font.mashanzheng",
        "org.avium.overlay.font.longcang",
        "org.avium.overlay.font.zhimangxing"
    )

    fun getCurrentFont(context: Context): String {
        try {
            val raw = Settings.Secure.getString(context.contentResolver, SETTING_THEME_CUSTOMIZATION)
            if (!raw.isNullOrEmpty()) {
                val json = JSONObject(raw)
                if (json.has(CATEGORY_FONT)) {
                    return json.getString(CATEGORY_FONT)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error reading current font setting", e)
        }
        val fallback = Settings.System.getString(context.contentResolver, KEY_LOMOLAB_CUSTOM_FONT)
        return if (!fallback.isNullOrEmpty()) fallback else "android"
    }

    fun applyFont(context: Context, overlayPkg: String?): Boolean {
        try {
            val resolver = context.contentResolver
            val raw = Settings.Secure.getString(resolver, SETTING_THEME_CUSTOMIZATION)
            val json = if (!raw.isNullOrEmpty()) {
                try { JSONObject(raw) } catch (e: Exception) { JSONObject() }
            } else {
                JSONObject()
            }

            val targetPkg = if (overlayPkg.isNullOrEmpty() || overlayPkg == "android") {
                json.remove(CATEGORY_FONT)
                "android"
            } else {
                json.put(CATEGORY_FONT, overlayPkg)
                overlayPkg
            }

            Settings.Secure.putString(resolver, SETTING_THEME_CUSTOMIZATION, json.toString())
            Settings.System.putString(resolver, KEY_LOMOLAB_CUSTOM_FONT, targetPkg)

            // Direct OverlayManager invocation for immediate system-wide enforcement
            try {
                val om = context.getSystemService(OverlayManager::class.java)
                if (om != null) {
                    val userHandle = Process.myUserHandle()
                    for (pkg in FONT_OVERLAYS) {
                        try {
                            if (pkg == targetPkg) {
                                om.setEnabled(pkg, true, userHandle)
                            } else {
                                om.setEnabled(pkg, false, userHandle)
                            }
                        } catch (oe: Exception) {
                            Log.w(TAG, "OverlayManager exception on $pkg", oe)
                        }
                    }
                }
            } catch (t: Throwable) {
                Log.w(TAG, "OverlayManager service direct invocation skipped", t)
            }

            Log.i(TAG, "Font applied successfully: $targetPkg")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to apply font overlay: $overlayPkg", e)
            return false
        }
    }
}
