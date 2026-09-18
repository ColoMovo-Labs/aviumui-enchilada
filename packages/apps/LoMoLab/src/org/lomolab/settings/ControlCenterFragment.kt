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

class ControlCenterFragment : PreferenceFragmentCompat() {

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.control_center_settings, rootKey)
        val resolver = requireContext().contentResolver

        SettingsHelper.bindList(
            findPreference<ListPreference>("avium_control_center_style"),
            resolver,
            "avium_control_center_style",
            SettingsHelper.Table.SYSTEM,
            defaultVal = 0
        )

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>("avium_control_center_blur"),
            resolver,
            "avium_control_center_blur",
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = true
        )

        SettingsHelper.bindList(
            findPreference<ListPreference>("avium_control_center_blur_intensity"),
            resolver,
            "avium_control_center_blur_intensity",
            SettingsHelper.Table.SYSTEM,
            defaultVal = 0
        )

        SettingsHelper.bindList(
            findPreference<ListPreference>("lomolab_control_center_quick_pulldown"),
            resolver,
            "lomolab_control_center_quick_pulldown",
            SettingsHelper.Table.SYSTEM,
            defaultVal = 0
        )
    }
}
