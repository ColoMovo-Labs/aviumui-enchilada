package org.avium.modulelab.utils

import org.avium.modulelab.data.ModuleInfo
import java.io.File

object SafeModeController {

    private const val SAFE_MODE_FLAG = "/data/adb/modules/.disable_magisk"
    private const val ALT_SAFE_MODE_FLAG = "/data/adb/.disable_magisk"

    fun isSafeModeActive(): Boolean {
        return File(SAFE_MODE_FLAG).exists() || File(ALT_SAFE_MODE_FLAG).exists()
    }

    fun setSafeMode(enabled: Boolean): Boolean {
        val flag = File(SAFE_MODE_FLAG)
        return try {
            if (enabled) {
                flag.parentFile?.mkdirs()
                if (!flag.exists()) flag.createNewFile() else true
            } else {
                if (flag.exists()) flag.delete()
                val alt = File(ALT_SAFE_MODE_FLAG)
                if (alt.exists()) alt.delete()
                true
            }
        } catch (_: Exception) {
            false
        }
    }

    fun disableAllModules(modules: List<ModuleInfo>): Int {
        var count = 0
        for (m in modules) {
            if (m.isEnabled) {
                if (ModuleScanner.setModuleEnabled(m, false)) {
                    m.isEnabled = false
                    m.isNeedReboot = true
                    count++
                }
            }
        }
        return count
    }

    fun rollbackLastInstalledModule(modules: List<ModuleInfo>): ModuleInfo? {
        if (modules.isEmpty()) return null
        val newest = modules.maxByOrNull { it.lastModified } ?: return null
        if (newest.isEnabled) {
            ModuleScanner.setModuleEnabled(newest, false)
            newest.isEnabled = false
            newest.isNeedReboot = true
        }
        return newest
    }
}
