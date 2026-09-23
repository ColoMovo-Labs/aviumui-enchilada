package org.avium.modulelab.data

/**
 * Encapsulates the live state of the underlying Root environment.
 */
data class RootEnvironment(
    val isRooted: Boolean,
    val engineName: String,
    val versionString: String,
    val suPath: String,
    val isSELinuxEnforcing: Boolean,
    val hasDataAdb: Boolean,
    val isZygiskEnabled: Boolean
)
