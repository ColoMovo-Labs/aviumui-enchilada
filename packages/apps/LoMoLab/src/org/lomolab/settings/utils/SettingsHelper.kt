/*
 * Copyright (C) 2026 The AviumUI / LoMoLab Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lomolab.settings.utils

import android.content.ContentResolver
import android.content.Context
import android.provider.Settings
import androidx.preference.ListPreference
import androidx.preference.Preference
import androidx.preference.TwoStatePreference

object SettingsHelper {

    enum class Table {
        SYSTEM,
        SECURE,
        GLOBAL
    }

    fun bindSwitch(
        pref: TwoStatePreference?,
        resolver: ContentResolver,
        key: String,
        table: Table = Table.SYSTEM,
        defaultEnabled: Boolean = false
    ) {
        if (pref == null) return
        val defaultVal = if (defaultEnabled) 1 else 0
        val current = when (table) {
            Table.SYSTEM -> Settings.System.getInt(resolver, key, defaultVal)
            Table.SECURE -> Settings.Secure.getInt(resolver, key, defaultVal)
            Table.GLOBAL -> Settings.Global.getInt(resolver, key, defaultVal)
        }
        pref.isChecked = current == 1
        pref.onPreferenceChangeListener = Preference.OnPreferenceChangeListener { _, newValue ->
            val checked = newValue as? Boolean ?: false
            val valToPut = if (checked) 1 else 0
            when (table) {
                Table.SYSTEM -> Settings.System.putInt(resolver, key, valToPut)
                Table.SECURE -> Settings.Secure.putInt(resolver, key, valToPut)
                Table.GLOBAL -> Settings.Global.putInt(resolver, key, valToPut)
            }
            true
        }
    }

    fun bindList(
        pref: ListPreference?,
        resolver: ContentResolver,
        key: String,
        table: Table = Table.SYSTEM,
        defaultVal: Int = 0
    ) {
        if (pref == null) return
        val current = when (table) {
            Table.SYSTEM -> Settings.System.getInt(resolver, key, defaultVal)
            Table.SECURE -> Settings.Secure.getInt(resolver, key, defaultVal)
            Table.GLOBAL -> Settings.Global.getInt(resolver, key, defaultVal)
        }
        pref.value = current.toString()
        pref.summary = "%s"
        pref.onPreferenceChangeListener = Preference.OnPreferenceChangeListener { _, newValue ->
            val value = (newValue as? String)?.toIntOrNull() ?: defaultVal
            when (table) {
                Table.SYSTEM -> Settings.System.putInt(resolver, key, value)
                Table.SECURE -> Settings.Secure.putInt(resolver, key, value)
                Table.GLOBAL -> Settings.Global.putInt(resolver, key, value)
            }
            true
        }
    }
}
