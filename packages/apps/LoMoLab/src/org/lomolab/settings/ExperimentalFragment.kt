/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings

import android.os.Bundle
import androidx.preference.PreferenceFragmentCompat
import androidx.preference.TwoStatePreference
import org.lomolab.settings.utils.SettingsHelper

class ExperimentalFragment : PreferenceFragmentCompat() {

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.experimental_settings, rootKey)
        val resolver = requireContext().contentResolver

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>("lomolab_exp_memory_compaction"),
            resolver,
            "lomolab_exp_memory_compaction",
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = false
        )

        SettingsHelper.bindSwitch(
            findPreference<TwoStatePreference>("lomolab_exp_game_touch_tuning"),
            resolver,
            "lomolab_exp_game_touch_tuning",
            SettingsHelper.Table.SYSTEM,
            defaultEnabled = false
        )
    }
}
