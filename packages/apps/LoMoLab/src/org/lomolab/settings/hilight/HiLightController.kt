/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings.hilight

import android.app.role.RoleManager
import android.content.ComponentName
import android.content.Context
import android.hardware.lights.Light
import android.hardware.lights.LightState
import android.hardware.lights.LightsManager
import android.hardware.lights.LightsRequest
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log

object HiLightController {

    private const val TAG = "LoMoHiLightController"

    const val COLOR_LISTENING = 0xFF00FFFF.toInt()  // Cyan
    const val COLOR_THINKING = 0xFF9C27B0.toInt()   // Purple
    const val COLOR_RESPONDING = 0xFF2979FF.toInt() // Blue

    private var activeSession: LightsManager.LightsSession? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun getAssistantPackage(context: Context): String? {
        try {
            val roleManager = context.getSystemService(RoleManager::class.java)
            val holders = roleManager?.getRoleHolders(RoleManager.ROLE_ASSISTANT)
            if (!holders.isNullOrEmpty()) {
                return holders[0]
            }
        } catch (e: Exception) {
            Log.w(TAG, "RoleManager query failed", e)
        }

        try {
            val assistSetting = Settings.Secure.getString(context.contentResolver, "assistant")
            if (!assistSetting.isNullOrEmpty()) {
                val cn = ComponentName.unflattenFromString(assistSetting)
                if (cn != null) {
                    return cn.packageName
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Settings.Secure assistant query failed", e)
        }

        return null
    }

    fun getAssistantUid(context: Context): Int {
        val pkg = getAssistantPackage(context) ?: return -1
        return try {
            context.packageManager.getPackageUid(pkg, 0)
        } catch (e: Exception) {
            -1
        }
    }

    @Synchronized
    fun setLedColor(context: Context, color: Int) {
        try {
            val lightsManager = context.getSystemService(LightsManager::class.java) ?: return
            val targetLight = lightsManager.lights.firstOrNull {
                it.hasRgbControl()
            } ?: lightsManager.lights.firstOrNull {
                it.name.contains("notification", ignoreCase = true) ||
                it.name.contains("status", ignoreCase = true) ||
                it.name.contains("led", ignoreCase = true)
            } ?: lightsManager.lights.firstOrNull() ?: return

            if (activeSession == null) {
                activeSession = lightsManager.openSession()
            }

            val request = LightsRequest.Builder()
                .addLight(targetLight, LightState.Builder().setColor(color).build())
                .build()

            activeSession?.requestLights(request)
            Log.d(TAG, "Requested LED color: 0x${Integer.toHexString(color)}")
        } catch (e: Exception) {
            Log.e(TAG, "Error setting LED color", e)
        }
    }

    @Synchronized
    fun clearLed() {
        try {
            activeSession?.close()
            activeSession = null
            Log.d(TAG, "Cleared LED and restored system ownership")
        } catch (e: Exception) {
            Log.e(TAG, "Error closing lights session", e)
            activeSession = null
        }
    }

    fun testLed(context: Context, color: Int, onFinish: (() -> Unit)? = null) {
        setLedColor(context, color)
        mainHandler.postDelayed({
            clearLed()
            onFinish?.invoke()
        }, 2500)
    }
}
