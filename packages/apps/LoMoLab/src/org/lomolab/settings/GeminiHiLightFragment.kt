/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings

import android.app.role.RoleManager
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.preference.ListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import androidx.preference.TwoStatePreference
import org.lomolab.settings.utils.SettingsHelper

class GeminiHiLightFragment : PreferenceFragmentCompat() {

    companion object {
        const val KEY_HILIGHT_ENABLED = "lomolab_hilight_enabled"
        const val KEY_LISTENING_ENABLED = "lomolab_hilight_listening_enabled"
        const val KEY_THINKING_ENABLED = "lomolab_hilight_thinking_enabled"
        const val KEY_RESPONDING_ENABLED = "lomolab_hilight_responding_enabled"
        const val KEY_SCREEN_OFF_ONLY = "lomolab_hilight_screen_off_only"
        const val KEY_DISABLE_CHARGING = "lomolab_hilight_disable_charging"
        const val KEY_TEST_TRIGGER = "lomolab_hilight_test_trigger"
        const val KEY_TEST_COLOR = "lomolab_hilight_test_color"
    }

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.gemini_hilight_settings, rootKey)
        val resolver = requireContext().contentResolver

        val mainSwitch = findPreference<TwoStatePreference>(KEY_HILIGHT_ENABLED)
        SettingsHelper.bindSwitch(
            mainSwitch,
            resolver,
            KEY_HILIGHT_ENABLED,
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = false
        )

        val assistantInfo = findPreference<Preference>("lomolab_hilight_assistant_info")
        try {
            val roleManager = requireContext().getSystemService(RoleManager::class.java)
            val holders = roleManager?.getRoleHolders(RoleManager.ROLE_ASSISTANT)
            if (!holders.isNullOrEmpty()) {
                assistantInfo?.summary = holders[0]
            } else {
                assistantInfo?.summary = "No Assistant role holder detected"
            }
        } catch (e: Exception) {
            assistantInfo?.summary = "Assistant role detection unavailable"
        }

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>(KEY_LISTENING_ENABLED),
            resolver,
            KEY_LISTENING_ENABLED,
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = true
        )

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>(KEY_THINKING_ENABLED),
            resolver,
            KEY_THINKING_ENABLED,
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = true
        )

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>(KEY_RESPONDING_ENABLED),
            resolver,
            KEY_RESPONDING_ENABLED,
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = true
        )

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>(KEY_SCREEN_OFF_ONLY),
            resolver,
            KEY_SCREEN_OFF_ONLY,
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = false
        )

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>(KEY_DISABLE_CHARGING),
            resolver,
            KEY_DISABLE_CHARGING,
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = true
        )

        val testLed = findPreference<ListPreference>("lomolab_hilight_test_led")
        testLed?.onPreferenceChangeListener = Preference.OnPreferenceChangeListener { _, newValue ->
            val colorStr = newValue as? String ?: "0xFFFFFFFF"
            val color = try {
                colorStr.toLong(16).toInt()
            } catch (e: Exception) {
                0xFFFFFFFF.toInt()
            }
            val idx = testLed.findIndexOfValue(colorStr)
            val label = if (idx >= 0) testLed.entries[idx] else colorStr

            Toast.makeText(
                requireContext(),
                getString(R.string.test_led_running, label),
                Toast.LENGTH_SHORT
            ).show()

            // Trigger test LED via Settings.System for SystemUI to execute
            try {
                Settings.System.putInt(resolver, KEY_TEST_COLOR, color)
                Settings.System.putLong(resolver, KEY_TEST_TRIGGER, System.currentTimeMillis())
            } catch (e: Exception) {
                // Ignore
            }

            false // Do not persist selection as a persistent setting
        }
    }
}
