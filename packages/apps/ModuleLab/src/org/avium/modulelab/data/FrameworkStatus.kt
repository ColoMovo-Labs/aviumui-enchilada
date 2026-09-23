package org.avium.modulelab.data

/**
 * State for ART hooking engines (LSPosed and Vector).
 */
data class FrameworkStatus(
    val isLSPosedActive: Boolean,
    val lsposedVersion: String,
    val isVectorActive: Boolean,
    val vectorVersion: String,
    val hasConflict: Boolean
)
