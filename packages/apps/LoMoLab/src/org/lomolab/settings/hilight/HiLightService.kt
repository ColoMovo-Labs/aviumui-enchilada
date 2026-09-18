/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings.hilight

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.media.AudioManager
import android.media.AudioPlaybackConfiguration
import android.media.AudioRecordingConfiguration
import android.os.BatteryManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

class HiLightService : Service() {

    companion object {
        private const val TAG = "LoMoHiLightService"
        private const val THINKING_TIMEOUT_MS = 10000L

        const val KEY_HILIGHT_ENABLED = "lomolab_hilight_enabled"
        const val KEY_LISTENING_ENABLED = "lomolab_hilight_listening_enabled"
        const val KEY_THINKING_ENABLED = "lomolab_hilight_thinking_enabled"
        const val KEY_RESPONDING_ENABLED = "lomolab_hilight_responding_enabled"
        const val KEY_SCREEN_OFF_ONLY = "lomolab_hilight_screen_off_only"
        const val KEY_DISABLE_CHARGING = "lomolab_hilight_disable_charging"

        fun startIfEnabled(context: Context) {
            val enabled = Settings.System.getInt(context.contentResolver, KEY_HILIGHT_ENABLED, 0) == 1
            if (enabled) {
                try {
                    context.startService(Intent(context, HiLightService::class.java))
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to start HiLightService", e)
                }
            }
        }

        fun stop(context: Context) {
            try {
                context.stopService(Intent(context, HiLightService::class.java))
            } catch (e: Exception) {
                Log.w(TAG, "Failed to stop HiLightService", e)
            }
        }
    }

    private enum class State {
        IDLE,
        LISTENING,
        THINKING,
        RESPONDING
    }

    private var currentState = State.IDLE
    private var isCharging = false
    private val handler = Handler(Looper.getMainLooper())
    private var audioManager: AudioManager? = null

    private val thinkingTimeoutRunnable = Runnable {
        if (currentState == State.THINKING) {
            Log.d(TAG, "Thinking timeout expired, returning to IDLE")
            transitionTo(State.IDLE)
        }
    }

    private val settingsObserver = object : ContentObserver(handler) {
        override fun onChange(selfChange: Boolean) {
            val enabled = Settings.System.getInt(contentResolver, KEY_HILIGHT_ENABLED, 0) == 1
            if (!enabled) {
                Log.i(TAG, "HiLight disabled via settings, stopping service")
                stopSelf()
            }
        }
    }

    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_BATTERY_CHANGED) {
                val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                        status == BatteryManager.BATTERY_STATUS_FULL
                if (isCharging && isDisableCharging()) {
                    transitionTo(State.IDLE)
                }
            }
        }
    }

    private val recordingCallback = object : AudioManager.AudioRecordingCallback() {
        override fun onRecordingConfigChanged(configs: MutableList<AudioRecordingConfiguration>?) {
            val assistantUid = HiLightController.getAssistantUid(this@HiLightService)
            if (assistantUid <= 0) return

            val isAssistantRecording = configs?.any {
                it.clientAudioSessionId != 0 && it.clientUid == assistantUid
            } == true

            if (isAssistantRecording) {
                if (isListeningEnabled()) {
                    transitionTo(State.LISTENING)
                }
            } else {
                if (currentState == State.LISTENING) {
                    if (isThinkingEnabled()) {
                        transitionTo(State.THINKING)
                    } else {
                        transitionTo(State.IDLE)
                    }
                }
            }
        }
    }

    private val playbackCallback = object : AudioManager.AudioPlaybackCallback() {
        override fun onPlaybackConfigChanged(configs: MutableList<AudioPlaybackConfiguration>?) {
            val assistantUid = HiLightController.getAssistantUid(this@HiLightService)
            if (assistantUid <= 0) return

            val isAssistantPlaying = configs?.any {
                it.isActive && it.clientUid == assistantUid
            } == true

            if (isAssistantPlaying) {
                if (isRespondingEnabled()) {
                    transitionTo(State.RESPONDING)
                }
            } else {
                if (currentState == State.RESPONDING) {
                    transitionTo(State.IDLE)
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "HiLightService starting (strictly event-driven, 0 wakelocks)")

        contentResolver.registerContentObserver(
            Settings.System.getUriFor(KEY_HILIGHT_ENABLED),
            false,
            settingsObserver
        )

        registerReceiver(batteryReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))

        audioManager = getSystemService(AudioManager::class.java)
        audioManager?.registerAudioRecordingCallback(recordingCallback, handler)
        audioManager?.registerAudioPlaybackCallback(playbackCallback, handler)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i(TAG, "HiLightService stopping")

        handler.removeCallbacks(thinkingTimeoutRunnable)
        contentResolver.unregisterContentObserver(settingsObserver)
        try { unregisterReceiver(batteryReceiver) } catch (ignored: Exception) {}

        audioManager?.unregisterAudioRecordingCallback(recordingCallback)
        audioManager?.unregisterAudioPlaybackCallback(playbackCallback)

        transitionTo(State.IDLE)
        HiLightController.clearLed()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun isListeningEnabled(): Boolean =
        Settings.System.getInt(contentResolver, KEY_LISTENING_ENABLED, 1) == 1

    private fun isThinkingEnabled(): Boolean =
        Settings.System.getInt(contentResolver, KEY_THINKING_ENABLED, 1) == 1

    private fun isRespondingEnabled(): Boolean =
        Settings.System.getInt(contentResolver, KEY_RESPONDING_ENABLED, 1) == 1

    private fun isScreenOffOnly(): Boolean =
        Settings.System.getInt(contentResolver, KEY_SCREEN_OFF_ONLY, 0) == 1

    private fun isDisableCharging(): Boolean =
        Settings.System.getInt(contentResolver, KEY_DISABLE_CHARGING, 1) == 1

    private fun canShowLed(): Boolean {
        if (isCharging && isDisableCharging()) {
            return false
        }
        if (isScreenOffOnly()) {
            val pm = getSystemService(PowerManager::class.java)
            if (pm?.isInteractive == true) {
                return false
            }
        }
        return true
    }

    private fun transitionTo(newState: State) {
        if (currentState == newState) return
        currentState = newState
        handler.removeCallbacks(thinkingTimeoutRunnable)

        if (!canShowLed() || newState == State.IDLE) {
            HiLightController.clearLed()
            return
        }

        when (newState) {
            State.LISTENING -> {
                HiLightController.setLedColor(this, HiLightController.COLOR_LISTENING)
            }
            State.THINKING -> {
                HiLightController.setLedColor(this, HiLightController.COLOR_THINKING)
                handler.postDelayed(thinkingTimeoutRunnable, THINKING_TIMEOUT_MS)
            }
            State.RESPONDING -> {
                HiLightController.setLedColor(this, HiLightController.COLOR_RESPONDING)
            }
            State.IDLE -> {
                HiLightController.clearLed()
            }
        }
    }
}
