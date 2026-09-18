/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings

import android.os.Bundle
import androidx.preference.ListPreference
import androidx.preference.PreferenceFragmentCompat
import org.lomolab.settings.utils.SettingsHelper

class AnimationsFragment : PreferenceFragmentCompat() {

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.animations_settings, rootKey)
        val resolver = requireContext().contentResolver

        SettingsHelper.bindList(
            findPreference<ListPreference>("lomolab_screen_off_animation"),
            resolver,
            "lomolab_screen_off_animation",
            SettingsHelper.Table.SYSTEM,
            defaultVal = 0
        )
    }
}
