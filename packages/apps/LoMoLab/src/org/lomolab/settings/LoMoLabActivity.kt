/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import com.google.android.material.appbar.MaterialToolbar

class LoMoLabActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_lomolab)

        val toolbar = findViewById<MaterialToolbar>(R.id.toolbar)
        setSupportActionBar(toolbar)

        if (savedInstanceState == null) {
            supportFragmentManager.beginTransaction()
                .replace(R.id.content_frame, LoMoLabMainFragment())
                .commit()
        }
    }

    class LoMoLabMainFragment : PreferenceFragmentCompat() {
        override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
            setPreferencesFromResource(R.xml.lomolab_main, rootKey)
        }

        override fun onPreferenceTreeClick(preference: Preference): Boolean {
            val (fragmentClass, titleRes) = when (preference.key) {
                "category_appearance_fonts" -> Pair(AppearanceFontsFragment::class.java.name, R.string.category_appearance_fonts_title)
                "category_status_bar" -> Pair(StatusBarFragment::class.java.name, R.string.category_status_bar_title)
                "category_super_island" -> Pair(SuperIslandFragment::class.java.name, R.string.category_super_island_title)
                "category_control_center" -> Pair(ControlCenterFragment::class.java.name, R.string.category_control_center_title)
                "category_animations" -> Pair(AnimationsFragment::class.java.name, R.string.category_animations_title)
                "category_pixel_features" -> Pair(PixelFeaturesFragment::class.java.name, R.string.category_pixel_features_title)
                "category_gemini_hilight" -> Pair(GeminiHiLightFragment::class.java.name, R.string.category_gemini_hilight_title)
                "category_experimental" -> Pair(ExperimentalFragment::class.java.name, R.string.category_experimental_title)
                "category_about_lomolab" -> Pair(AboutLoMoLabFragment::class.java.name, R.string.category_about_lomolab_title)
                else -> return super.onPreferenceTreeClick(preference)
            }

            val intent = Intent(requireContext(), SubSettingsActivity::class.java).apply {
                putExtra(SubSettingsActivity.EXTRA_FRAGMENT_NAME, fragmentClass)
                putExtra(SubSettingsActivity.EXTRA_TITLE, getString(titleRes))
            }
            startActivity(intent)
            return true
        }
    }
}
