/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings

import android.os.Bundle
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import org.lomolab.settings.pixel.AiWallpaperController

class PixelFeaturesFragment : PreferenceFragmentCompat() {

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.pixel_features_settings, rootKey)

        findPreference<Preference>("lomolab_ai_wallpaper")?.setOnPreferenceClickListener {
            AiWallpaperController.launchOrShowUnavailable(requireContext())
            true
        }
    }
}
