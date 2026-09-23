package org.avium.modulelab.data

/**
 * Metadata and runtime state for an individual Magisk / KernelSU / APatch module.
 */
data class ModuleInfo(
    val id: String,
    val name: String,
    val version: String,
    val versionCode: Long,
    val author: String,
    val description: String,
    val path: String,
    var isEnabled: Boolean,
    var isPendingRemove: Boolean,
    var isPendingUpdate: Boolean,
    var isNeedReboot: Boolean,
    val lastModified: Long,
    val serviceLog: String?
)
