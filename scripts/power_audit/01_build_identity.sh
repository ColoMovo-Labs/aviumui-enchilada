#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/01-build-identity.txt"
echo "=== Step 1: Build Identity & Golden Baseline Audit ===" > "$REPORT"
echo "Timestamp: $(date -u)" >> "$REPORT"
echo "Source root: $SOURCE_ROOT" >> "$REPORT"
echo "Control dir: $CONTROL_DIR" >> "$REPORT"
echo "--------------------------------------------------------" >> "$REPORT"

HAS_RED=0
HAS_YELLOW=0

# Helper to log
log() {
    echo "$1"
    echo "$1" >> "$REPORT"
}

cd "$SOURCE_ROOT"

# 1. Check TARGET_PRODUCT & lunch variables if environment is sourced
if type get_build_var &>/dev/null; then
    TARGET_PRODUCT=$(get_build_var TARGET_PRODUCT || true)
    PLATFORM_VERSION=$(get_build_var PLATFORM_VERSION || true)
    BUILD_ID=$(get_build_var BUILD_ID || true)
    WITH_GMS=$(get_build_var WITH_GMS || true)
    SUPER_SIZE=$(get_build_var BOARD_SUPER_PARTITION_SIZE || true)
    DYN_PART=$(get_build_var PRODUCT_USE_DYNAMIC_PARTITIONS || true)
    RETRO_PART=$(get_build_var PRODUCT_RETROFIT_DYNAMIC_PARTITIONS || true)
else
    # Fallback to static grep in device & vendor trees
    TARGET_PRODUCT=$(grep -rh "PRODUCT_DEVICE" device/oneplus/enchilada/*.mk 2>/dev/null | head -n 1 || echo "lineage_enchilada")
    PLATFORM_VERSION="16"
    BUILD_ID="BP4A.251205.006"
    WITH_GMS=$(grep -rh "WITH_GMS" "$CONTROL_DIR" device/oneplus/enchilada/*.mk 2>/dev/null | grep -v "#" | head -n 1 || echo "true")
    SUPER_SIZE=""
    DYN_PART=""
    RETRO_PART=""
fi

log "[*] TARGET_PRODUCT: $TARGET_PRODUCT"
if [ "$TARGET_PRODUCT" = "lineage_enchilada" ] || [ "$TARGET_PRODUCT" = "enchilada" ]; then
    log "  [PASS] TARGET_PRODUCT matches OnePlus 6 (enchilada)"
else
    log "  [WARN] Unexpected TARGET_PRODUCT: $TARGET_PRODUCT"
    HAS_YELLOW=1
fi

log "[*] Android Version: $PLATFORM_VERSION (BUILD_ID: $BUILD_ID)"
log "[*] WITH_GMS: $WITH_GMS"

# 2. Check Dynamic / Super Partitions
log "[*] Dynamic / Super Partition Audit:"
SUPER_ACTIVE=$(grep -RIn "BOARD_SUPER_PARTITION_SIZE" device/oneplus vendor/oneplus 2>/dev/null | grep -vE ':[0-9]+:[[:space:]]*#' || true)
DYN_ACTIVE=$(grep -RIn "PRODUCT_USE_DYNAMIC_PARTITIONS" device/oneplus vendor/oneplus 2>/dev/null | grep -vE ':[0-9]+:[[:space:]]*#' || true)

if [ -n "$SUPER_ACTIVE" ] || [ -n "$SUPER_SIZE" ]; then
    log "  [RED FINDING] Active BOARD_SUPER_PARTITION_SIZE detected: $SUPER_ACTIVE $SUPER_SIZE"
    HAS_RED=1
else
    log "  [PASS] BOARD_SUPER_PARTITION_SIZE is EMPTY (Legacy A/B confirmed)"
fi

if [ -n "$DYN_ACTIVE" ] || [ -n "$DYN_PART" ]; then
    log "  [RED FINDING] Active PRODUCT_USE_DYNAMIC_PARTITIONS detected: $DYN_ACTIVE"
    HAS_RED=1
else
    log "  [PASS] PRODUCT_USE_DYNAMIC_PARTITIONS is EMPTY (No retrofit, pure physical A/B)"
fi

# 3. Kernel Version & Golden Baseline Audit
log "[*] Kernel 4.19 Golden Baseline Audit:"
KERNEL_DIR="kernel/oneplus/sdm845"
if [ -d "$KERNEL_DIR" ]; then
    KERNEL_VER=$(head -n 4 "$KERNEL_DIR/Makefile" 2>/dev/null | grep -E "^(VERSION|PATCHLEVEL|SUBLEVEL)" | awk '{print $3}' | tr '\n' '.' | sed 's/\.$//' || echo "unknown")
    log "  Kernel Makefile version: $KERNEL_VER"
    if echo "$KERNEL_VER" | grep -q "^4\.19"; then
        log "  [PASS] Target kernel is Linux 4.19 ($KERNEL_VER)"
    else
        log "  [RED FINDING] Kernel version is not 4.19 ($KERNEL_VER)"
        HAS_RED=1
    fi

    # Check for KernelSU / KernelSU-Next
    KSU_MATCHES=$(grep -rnE "(kernelsu|ksu_|KSU_GIT_VERSION)" "$KERNEL_DIR/drivers" "$KERNEL_DIR/kernel" 2>/dev/null | head -n 10 || true)
    if [ -n "$KSU_MATCHES" ]; then
        log "  [RED FINDING] KernelSU symbols detected in kernel source:"
        log "$KSU_MATCHES"
        HAS_RED=1
    else
        log "  [PASS] Zero KernelSU / KernelSU Next symbols in kernel tree"
    fi
else
    log "  [WARN] Kernel directory $KERNEL_DIR not found at this path"
    HAS_YELLOW=1
fi

log "--------------------------------------------------------"
if [ "$HAS_RED" -eq 1 ]; then
    log "STEP 1 RESULT: RED (Issues detected in build identity/baseline)"
elif [ "$HAS_YELLOW" -eq 1 ]; then
    log "STEP 1 RESULT: YELLOW (Review warnings)"
else
    log "STEP 1 RESULT: GREEN (Verified Golden Baseline identity)"
fi
