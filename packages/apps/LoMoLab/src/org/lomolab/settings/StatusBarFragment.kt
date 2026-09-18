/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings

import android.os.Bundle
import androidx.preference.ListPreference
import androidx.preference.PreferenceFragmentCompat
import androidx.preference.TwoStatePreference
import org.lomolab.settings.utils.SettingsHelper

class StatusBarFragment : PreferenceFragmentCompat() {

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.status_bar_settings, rootKey)
        val resolver = requireContext().contentResolver

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>("status_bar_capsule_enabled"),
            resolver,
            "status_bar_capsule_enabled",
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = true
        )

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>("lomolab_status_bar_network_traffic"),
            resolver,
            "lomolab_status_bar_network_traffic",
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = false
        )

        SettingsHelper.bindList(
            findPreference<ListPreference>("lomolab_status_bar_battery_style"),
            resolver,
            "lomolab_status_bar_battery_style",
            SettingsHelper.Table.SYSTEM,
            defaultVal = 0
        )
    }
}
