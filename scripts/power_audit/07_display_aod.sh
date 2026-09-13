#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/07-display-aod.txt"
echo "=== Step 7: Display & SurfaceFlinger Refresh / AOD Audit ===" > "$REPORT"
echo "Timestamp: $(date -u)" >> "$REPORT"
echo "--------------------------------------------------------" >> "$REPORT"

HAS_RED=0
HAS_YELLOW=0

log() {
    echo "$1"
    echo "$1" >> "$REPORT"
}

cd "$SOURCE_ROOT"

log "[*] 1. Display Panel & Refresh Rate Configuration Audit (OnePlus 6 60Hz):"
REFRESH_PROPS=$(grep -rnE "(ro\.surface_flinger|config_defaultRefreshRate|config_peakRefreshRate|config_defaultMinRefreshRate)" device/oneplus/ 2>/dev/null || true)
log "  Device refresh rate properties & overlays:"
log "$REFRESH_PROPS"

# Check if 90Hz or 120Hz is inadvertently configured for enchilada
FORCED_HIGH_RR=$(echo "$REFRESH_PROPS" | grep -E "(90|120)" || true)
if [ -n "$FORCED_HIGH_RR" ]; then
    log "  [YELLOW FINDING] Non-60Hz refresh rate overlay detected on 60Hz panel: $FORCED_HIGH_RR"
    HAS_YELLOW=1
else
    log "  [PASS] Display operates at native 60Hz"
fi

log "[*] 2. SurfaceFlinger Composition & Debug Properties:"
DEBUG_COMP=$(grep -rnE "(debug\.sf|ro\.sf\.debug|debug\.composition\.type)" device/oneplus/ vendor/oneplus/ 2>/dev/null || true)
if [ -n "$DEBUG_COMP" ]; then
    log "  SurfaceFlinger debug properties found:"
    log "$DEBUG_COMP"
    
    # Check if GPU composition is forced everywhere (disabling Hardware Composer)
    FORCED_GPU=$(echo "$DEBUG_COMP" | grep -E "debug\.composition\.type.*(gpu|c2d)" || true)
    if [ -n "$FORCED_GPU" ]; then
        log "  [RED FINDING] HWC disabled, forced GPU composition: $FORCED_GPU"
        HAS_RED=1
    else
        log "  [PASS] Hardware Composer (HWC) is active"
    fi
else
    log "  [PASS] No debug/forced GPU composition properties"
fi

log "[*] 3. Always-On Display (AOD) / Doze Refresh Policy Audit:"
AOD_CONFIGS=$(find device/oneplus -name "*.xml" -exec grep -HnE "(config_dozeAlwaysOnDisplayAvailable|config_dozeSupport|doze_clock)" {} + 2>/dev/null || true)
log "  AOD / Doze overlay configs:"
log "$AOD_CONFIGS"

# Check if AOD has second-hand updates or rapid clock ticking
PATCH_AOD=$(grep -rnE "(Chronometer|TickReceiver|ACTION_TIME_TICK)" "$CONTROL_DIR/patches" 2>/dev/null || true)
log "  Time ticking references in Feature patches:"
log "$PATCH_AOD"

log "[*] 4. Status Bar Capsule Polling vs Event-Driven Audit:"
PATCH_ISLAND="$CONTROL_DIR/patches/frameworks_base/0003-Add-native-Status-Bar-Capsule-and-Super-Island.patch"
if [ -f "$PATCH_ISLAND" ]; then
    # Verify whether battery is polled or broadcast-driven
    BATTERY_EVENT=$(grep -A 20 "class ChargingEventMonitor" "$PATCH_ISLAND" 2>/dev/null | grep -E "(BatteryController\.BatteryStateChangeCallback|ACTION_BATTERY_CHANGED)" || true)
    if [ -n "$BATTERY_EVENT" ]; then
        log "  [PASS] ChargingEventMonitor is event-driven via BatteryController callback & ACTION_BATTERY_CHANGED (No polling)"
    else
        log "  [YELLOW FINDING] ChargingEventMonitor might rely on polling"
        HAS_YELLOW=1
    fi
fi

log "--------------------------------------------------------"
if [ "$HAS_RED" -eq 1 ]; then
    log "STEP 7 RESULT: RED (Abnormal refresh rate or disabled HWC)"
elif [ "$HAS_YELLOW" -eq 1 ]; then
    log "STEP 7 RESULT: YELLOW (Review AOD/Capsule tick behavior)"
else
    log "STEP 7 RESULT: GREEN (Display operates at native 60Hz, event-driven updates)"
fi
