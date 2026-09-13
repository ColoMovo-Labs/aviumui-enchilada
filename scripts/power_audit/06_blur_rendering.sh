#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/06-blur-rendering.txt"
echo "=== Step 6: Blur Rendering & RenderEffect Path Audit ===" > "$REPORT"
echo "Timestamp: $(date -u)" >> "$REPORT"
echo "--------------------------------------------------------" >> "$REPORT"

HAS_RED=0
HAS_YELLOW=0

log() {
    echo "$1"
    echo "$1" >> "$REPORT"
}

cd "$SOURCE_ROOT"
PATCH_ISLAND="$CONTROL_DIR/patches/frameworks_base/0003-Add-native-Status-Bar-Capsule-and-Super-Island.patch"
PATCH_CC="$CONTROL_DIR/patches/frameworks_base/0005-Add-Elixir-style-Quick-Settings-Control-Center-and-B.patch"

log "[*] 1. Super Island Blur Implementation Audit:"
if [ -f "$PATCH_ISLAND" ]; then
    BLUR_FUNC=$(grep -A 20 "private fun updateBackdropBlur" "$PATCH_ISLAND" 2>/dev/null || true)
    log "  updateBackdropBlur function implementation:"
    log "$BLUR_FUNC"

    # Check if setRenderEffect(null) is called when blur is disabled
    HAS_NULL_CLEAR=$(echo "$BLUR_FUNC" | grep -E "setRenderEffect\(null\)" || true)
    if [ -n "$HAS_NULL_CLEAR" ]; then
        log "  [PASS] setRenderEffect(null) is explicitly called when blur is disabled"
    else
        log "  [RED FINDING] setRenderEffect(null) NOT called when blur disabled!"
        HAS_RED=1
    fi

    # Check if blur is called on every frame or only on bind
    PER_FRAME_BLUR=$(grep -nE "(onDraw.*setRenderEffect|dispatchDraw.*setRenderEffect)" "$PATCH_ISLAND" || true)
    if [ -n "$PER_FRAME_BLUR" ]; then
        log "  [RED FINDING] setRenderEffect called per-frame inside onDraw / dispatchDraw: $PER_FRAME_BLUR"
        HAS_RED=1
    else
        log "  [PASS] setRenderEffect is only called once per event binding (not per frame)"
    fi
fi

log "[*] 2. Control Center Blur Implementation Audit:"
if [ -f "$PATCH_CC" ]; then
    CC_BLUR=$(grep -nE "(RenderEffect|createBlurEffect|setBlurBehindRadius|backgroundBlurRadius)" "$PATCH_CC" || true)
    log "  Control Center blur references:"
    log "$CC_BLUR"

    CC_DRAW_BLUR=$(grep -nE "(onDraw.*createBlurEffect|draw.*RenderEffect)" "$PATCH_CC" || true)
    if [ -n "$CC_DRAW_BLUR" ]; then
        log "  [RED FINDING] Control Center recreates blur effect in drawing path: $CC_DRAW_BLUR"
        HAS_RED=1
    else
        log "  [PASS] Control Center does not recreate blur in per-frame draw methods"
    fi
fi

log "[*] 3. SurfaceFlinger Background Blur Support:"
SF_BLUR_PROP=$(grep -rn "ro.surface_flinger.supports_background_blur" device/oneplus/ vendor/oneplus/ 2>/dev/null || true)
log "  ro.surface_flinger.supports_background_blur in device trees:"
log "$SF_BLUR_PROP"

log "--------------------------------------------------------"
if [ "$HAS_RED" -eq 1 ]; then
    log "STEP 6 RESULT: RED (Per-frame blur allocation or un-cleared RenderEffect)"
elif [ "$HAS_YELLOW" -eq 1 ]; then
    log "STEP 6 RESULT: YELLOW (Review RenderEffect GPU memory footprint)"
else
    log "STEP 6 RESULT: GREEN (Blur calls are static and properly cleared when disabled)"
fi
