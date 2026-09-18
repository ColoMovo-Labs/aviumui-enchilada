/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings

import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.preference.ListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import androidx.preference.TwoStatePreference
import org.lomolab.settings.utils.SettingsHelper

class SuperIslandFragment : PreferenceFragmentCompat() {

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.super_island_settings, rootKey)
        val resolver = requireContext().contentResolver

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>("super_island_enabled"),
            resolver,
            "super_island_enabled",
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = true
        )

        SettingsHelper.bindList(
            findPreference<ListPreference>("island_display_mode"),
            resolver,
            "island_display_mode",
            SettingsHelper.Table.SYSTEM,
            defaultVal = 0
        )

        val events = listOf(
            "island_event_media",
            "island_event_charging",
            "island_event_headset",
            "island_event_call",
            "island_event_recording",
            "island_event_timer",
            "island_event_flashlight"
        )

        for (eventKey in events) {
            SettingsHelper.bindSwitch(
                findPreference<TwoStatePreference>(eventKey),
                resolver,
                eventKey,
                SettingsHelper.Table.SYSTEM,
                defaultEnabled = true
            )
        }

        val deepLink = findPreference<Preference>("deep_link_avium_featuresettings_island")
        deepLink?.setOnPreferenceClickListener {
            try {
                val intent = Intent().setComponent(
                    ComponentName("org.exthm.featuresettings", "org.exthm.featuresettings.MainActivity")
                )
                startActivity(intent)
            } catch (e: Exception) {
                Toast.makeText(requireContext(), "AviumUI settings not found", Toast.LENGTH_SHORT).show()
            }
            true
        }
    }
}
