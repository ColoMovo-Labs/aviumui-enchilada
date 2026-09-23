package org.avium.modulelab.utils

import org.avium.modulelab.data.ModuleInfo
import java.io.File
import java.io.FileInputStream
import java.util.Properties

object ModuleScanner {

    private const val MODULES_DIR = "/data/adb/modules"

    fun scanModules(): List<ModuleInfo> {
        val rootDir = File(MODULES_DIR)
        if (!rootDir.exists() || !rootDir.isDirectory) {
            return emptyList()
        }

        val modules = mutableListOf<ModuleInfo>()
        val subDirs = rootDir.listFiles() ?: return emptyList()

        for (dir in subDirs) {
            if (!dir.isDirectory) continue
            val propFile = File(dir, "module.prop")
            if (!propFile.exists()) continue

            val props = Properties()
            try {
                FileInputStream(propFile).use { props.load(it) }
            } catch (_: Exception) {
                continue
            }

            val id = props.getProperty("id", dir.name)
            val name = props.getProperty("name", id)
            val version = props.getProperty("version", "Unknown")
            val versionCode = props.getProperty("versionCode", "0").toLongOrNull() ?: 0L
            val author = props.getProperty("author", "Unknown")
            val description = props.getProperty("description", "")

            val isEnabled = !File(dir, "disable").exists()
            val isPendingRemove = File(dir, "remove").exists()
            val isPendingUpdate = File(dir, "update").exists()
            val isNeedReboot = File(dir, "need_reboot").exists()

            var serviceLog: String? = null
            val logFile = File(dir, "service.log")
            val postFsLog = File(dir, "post-fs-data.log")
            if (logFile.exists()) {
                serviceLog = runCatching { logFile.readText() }.getOrNull()
            } else if (postFsLog.exists()) {
                serviceLog = runCatching { postFsLog.readText() }.getOrNull()
            }

            modules.add(
                ModuleInfo(
                    id = id,
                    name = name,
                    version = version,
                    versionCode = versionCode,
                    author = author,
                    description = description,
                    path = dir.absolutePath,
                    isEnabled = isEnabled,
                    isPendingRemove = isPendingRemove,
                    isPendingUpdate = isPendingUpdate,
                    isNeedReboot = isNeedReboot,
                    lastModified = dir.lastModified(),
                    serviceLog = serviceLog
                )
            )
        }

        // Sort: enabled first, then alphabetically by name
        return modules.sortedWith(
            compareByDescending<ModuleInfo> { it.isEnabled }.thenBy { it.name.lowercase() }
        )
    }

    fun setModuleEnabled(module: ModuleInfo, enable: Boolean): Boolean {
        val disableFile = File(module.path, "disable")
        return try {
            if (enable) {
                if (disableFile.exists()) disableFile.delete() else true
            } else {
                if (!disableFile.exists()) disableFile.createNewFile() else true
            }
        } catch (_: Exception) {
            false
        }
    }

    fun markModuleRemove(module: ModuleInfo, remove: Boolean): Boolean {
        val removeFile = File(module.path, "remove")
        return try {
            if (remove) {
                if (!removeFile.exists()) removeFile.createNewFile() else true
            } else {
                if (removeFile.exists()) removeFile.delete() else true
            }
        } catch (_: Exception) {
            false
        }
    }
}
