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
import org.lomolab.settings.fonts.FontManager

class AppearanceFontsFragment : PreferenceFragmentCompat() {

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.appearance_fonts_settings, rootKey)

        val fontPicker = findPreference<ListPreference>("lomolab_font_picker")
        if (fontPicker != null) {
            val current = FontManager.getCurrentFont(requireContext())
            fontPicker.value = current
            val idx = fontPicker.findIndexOfValue(current)
            if (idx >= 0) {
                fontPicker.summary = fontPicker.entries[idx]
            }

            fontPicker.onPreferenceChangeListener = Preference.OnPreferenceChangeListener { _, newValue ->
                val pkg = newValue as? String ?: "android"
                val ok = FontManager.applyFont(requireContext(), pkg)
                if (ok) {
                    val newIdx = fontPicker.findIndexOfValue(pkg)
                    val label = if (newIdx >= 0) fontPicker.entries[newIdx] else pkg
                    fontPicker.summary = label
                    Toast.makeText(
                        requireContext(),
                        getString(R.string.font_applied_toast, label),
                        Toast.LENGTH_SHORT
                    ).show()
                }
                true
            }
        }

        val deepLinkPref = findPreference<Preference>("deep_link_avium_personalization")
        deepLinkPref?.setOnPreferenceClickListener {
            try {
                val intent = Intent().setComponent(
                    ComponentName("org.exthm.featuresettings", "org.exthm.featuresettings.MainActivity")
                )
                startActivity(intent)
            } catch (e: Exception) {
                Toast.makeText(requireContext(), "AviumUI Personalization not found", Toast.LENGTH_SHORT).show()
            }
            true
        }
    }
}
