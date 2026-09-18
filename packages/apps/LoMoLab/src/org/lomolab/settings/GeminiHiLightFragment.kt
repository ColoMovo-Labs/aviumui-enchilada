/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings

import android.os.Bundle
import android.widget.Toast
import androidx.preference.ListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import androidx.preference.TwoStatePreference
import org.lomolab.settings.hilight.HiLightController
import org.lomolab.settings.hilight.HiLightService
import org.lomolab.settings.utils.SettingsHelper

class GeminiHiLightFragment : PreferenceFragmentCompat() {

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.gemini_hilight_settings, rootKey)
        val resolver = requireContext().contentResolver

        val mainSwitch = findPreference<TwoStatePreference>(HiLightService.KEY_HILIGHT_ENABLED)
        SettingsHelper.bindSwitch(
            mainSwitch,
            resolver,
            HiLightService.KEY_HILIGHT_ENABLED,
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = false
        )

        mainSwitch?.onPreferenceChangeListener = Preference.OnPreferenceChangeListener { _, newValue ->
            val isEnabled = newValue as? Boolean ?: false
            if (isEnabled) {
                HiLightService.startIfEnabled(requireContext())
            } else {
                HiLightService.stop(requireContext())
                HiLightController.clearLed()
            }
            true
        }

        val assistantInfo = findPreference<Preference>("lomolab_hilight_assistant_info")
        val detectedAssistant = HiLightController.getAssistantPackage(requireContext())
        if (detectedAssistant != null) {
            assistantInfo?.summary = detectedAssistant
        } else {
            assistantInfo?.summary = "No Assistant role holder detected"
        }

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>(HiLightService.KEY_LISTENING_ENABLED),
            resolver,
            HiLightService.KEY_LISTENING_ENABLED,
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = true
        )

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>(HiLightService.KEY_THINKING_ENABLED),
            resolver,
            HiLightService.KEY_THINKING_ENABLED,
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = true
        )

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>(HiLightService.KEY_RESPONDING_ENABLED),
            resolver,
            HiLightService.KEY_RESPONDING_ENABLED,
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = true
        )

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>(HiLightService.KEY_SCREEN_OFF_ONLY),
            resolver,
            HiLightService.KEY_SCREEN_OFF_ONLY,
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = false
        )

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>(HiLightService.KEY_DISABLE_CHARGING),
            resolver,
            HiLightService.KEY_DISABLE_CHARGING,
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

            HiLightController.testLed(requireContext(), color) {
                // Restored
            }
            false // Do not persist selection as a persistent setting
        }
    }
}
