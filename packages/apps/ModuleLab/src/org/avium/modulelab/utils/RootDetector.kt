package org.avium.modulelab.utils

import android.content.Context
import android.os.SystemProperties
import org.avium.modulelab.data.FrameworkStatus
import org.avium.modulelab.data.RootEnvironment
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

object RootDetector {

    fun detectEnvironment(): RootEnvironment {
        val suPaths = arrayOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/data/adb/magisk/busybox",
            "/data/adb/ksu/bin/su",
            "/data/adb/ap/bin/su"
        )
        var suPathFound = ""
        for (p in suPaths) {
            if (File(p).exists()) {
                suPathFound = p
                break
            }
        }

        val hasDataAdb = File("/data/adb").exists()
        var engineName = "Unknown"
        var versionString = ""
        var isRooted = false

        // 1. Check Magisk
        val magiskDir = File("/data/adb/magisk")
        if (magiskDir.exists() || suPathFound.contains("magisk")) {
            engineName = "Magisk"
            isRooted = true
            versionString = getMagiskVersion()
        } else if (File("/data/adb/ksu").exists() || File("/sys/fs/selinux").exists() && File("/data/adb/ksu/bin/su").exists()) {
            engineName = "KernelSU"
            isRooted = true
            versionString = "KSU Native"
        } else if (File("/data/adb/ap").exists()) {
            engineName = "APatch"
            isRooted = true
            versionString = "APatch Native"
        } else if (suPathFound.isNotEmpty()) {
            engineName = "Generic Su"
            isRooted = true
            versionString = "Pre-installed"
        }

        // 2. SELinux Status
        val isSELinuxEnforcing = isSELinuxEnforcing()

        // 3. Zygisk Status
        val isZygisk = isZygiskActive()

        return RootEnvironment(
            isRooted = isRooted,
            engineName = engineName,
            versionString = versionString,
            suPath = if (suPathFound.isNotEmpty()) suPathFound else "None",
            isSELinuxEnforcing = isSELinuxEnforcing,
            hasDataAdb = hasDataAdb,
            isZygiskEnabled = isZygisk
        )
    }

    private fun isSELinuxEnforcing(): Boolean {
        return try {
            val enforceFile = File("/sys/fs/selinux/enforce")
            if (enforceFile.exists()) {
                enforceFile.readText().trim() == "1"
            } else {
                true
            }
        } catch (_: Exception) {
            true
        }
    }

    private fun isZygiskActive(): Boolean {
        val zygiskFlag = File("/data/adb/magisk/zygisk")
        if (zygiskFlag.exists()) return true
        val prop = SystemProperties.get("persist.magisk.zygisk", "0")
        if (prop == "1") return true
        val zygiskModule = File("/data/adb/modules/zygisk_lsposed")
        return zygiskModule.exists() && !File(zygiskModule, "disable").exists()
    }

    private fun getMagiskVersion(): String {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("magisk", "-v"))
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val line = reader.readLine()
            reader.close()
            process.destroy()
            line ?: "v30.7"
        } catch (_: Exception) {
            "v30.7 (Integrated)"
        }
    }

    fun detectFrameworks(context: Context): FrameworkStatus {
        val lsposedModule = File("/data/adb/modules/zygisk_lsposed")
        val lsposedDir = File("/data/adb/lspd")
        val isLsposed = (lsposedModule.exists() && !File(lsposedModule, "disable").exists()) || lsposedDir.exists()
        val lsposedVer = if (isLsposed) "v1.9.3" else "Inactive"

        val vectorModule = File("/data/adb/modules/zygisk_vector")
        val vectorDir = File("/data/adb/vector")
        val isVector = (vectorModule.exists() && !File(vectorModule, "disable").exists()) || vectorDir.exists()
        val vectorVer = if (isVector) "v1.0 (LSPlant)" else "Inactive"

        val hasConflict = isLsposed && isVector

        return FrameworkStatus(
            isLSPosedActive = isLsposed,
            lsposedVersion = lsposedVer,
            isVectorActive = isVector,
            vectorVersion = vectorVer,
            hasConflict = hasConflict
        )
    }
}
