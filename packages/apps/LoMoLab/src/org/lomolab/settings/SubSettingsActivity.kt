/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.google.android.material.appbar.MaterialToolbar

class SubSettingsActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_FRAGMENT_NAME = "extra_fragment_name"
        const val EXTRA_TITLE = "extra_title"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_sub_settings)

        val toolbar = findViewById<MaterialToolbar>(R.id.toolbar)
        setSupportActionBar(toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)

        val title = intent.getStringExtra(EXTRA_TITLE)
        if (!title.isNullOrEmpty()) {
            supportActionBar?.title = title
        }

        toolbar.setNavigationOnClickListener {
            onBackPressedDispatcher.onBackPressed()
        }

        if (savedInstanceState == null) {
            val fragmentName = intent.getStringExtra(EXTRA_FRAGMENT_NAME)
            if (!fragmentName.isNullOrEmpty()) {
                val fragment = supportFragmentManager.fragmentFactory.instantiate(classLoader, fragmentName)
                supportFragmentManager.beginTransaction()
                    .replace(R.id.content_frame, fragment)
                    .commit()
            }
        }
    }
}
