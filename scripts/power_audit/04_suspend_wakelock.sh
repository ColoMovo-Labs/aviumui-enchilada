#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/04-suspend-wakelock-static.txt"
echo "=== Step 4: Suspend & Deep Sleep Static Audit ===" > "$REPORT"
echo "Timestamp: $(date -u)" >> "$REPORT"
echo "--------------------------------------------------------" >> "$REPORT"

HAS_RED=0
HAS_YELLOW=0

log() {
    echo "$1"
    echo "$1" >> "$REPORT"
}

cd "$SOURCE_ROOT"

log "[*] 1. Init Scripts Suspend & WakeLock Audit:"
INIT_WAKELOCKS=$(grep -rnE "(echo.*wake_lock|stay_awake|autosleep.*off)" device/oneplus vendor/oneplus 2>/dev/null | grep -E "\.rc|\.sh" || true)
if [ -n "$INIT_WAKELOCKS" ]; then
    log "  [RED FINDING] Suspicious wake_lock or stay_awake in init scripts:"
    log "$INIT_WAKELOCKS"
    HAS_RED=1
else
    log "  [PASS] No permanent wake_lock or stay_awake written by init scripts"
fi

log "[*] 2. Deep Sleep & Suspend Configuration in Device Trees:"
DEEP_SLEEP_CONFIGS=$(grep -rnE "(config_suspend|config_deep_sleep|device_idle)" device/oneplus/ 2>/dev/null || true)
if [ -n "$DEEP_SLEEP_CONFIGS" ]; then
    log "  Device suspend overlay configurations:"
    log "$DEEP_SLEEP_CONFIGS"
fi

log "[*] 3. WakeLock Usage in Feature Branch New Code (Patches & SystemUI):"
FEATURE_WAKELOCKS=$(grep -rnE "(acquire\(|acquireWakeLock|newWakeLock|PARTIAL_WAKE_LOCK|FULL_WAKE_LOCK|SCREEN_DIM_WAKE_LOCK)" "$CONTROL_DIR/patches" 2>/dev/null || true)
if [ -n "$FEATURE_WAKELOCKS" ]; then
    log "  [YELLOW FINDING] Feature patches reference WakeLock APIs:"
    log "$FEATURE_WAKELOCKS"
    HAS_YELLOW=1
else
    log "  [PASS] Zero WakeLock acquisitions in Feature Branch patches (Capsule, Super Island, Control Center)"
fi

log "[*] 4. Android Doze / DeviceIdle Overlays:"
DOZE_OVERLAYS=$(find device/oneplus -name "config.xml" -exec grep -Hn "config_enableAutoPowerModes" {} + 2>/dev/null || true)
if [ -n "$DOZE_OVERLAYS" ]; then
    log "  Doze auto power modes setting: $DOZE_OVERLAYS"
fi

log "--------------------------------------------------------"
if [ "$HAS_RED" -eq 1 ]; then
    log "STEP 4 RESULT: RED (Static condition blocking suspend detected)"
elif [ "$HAS_YELLOW" -eq 1 ]; then
    log "STEP 4 RESULT: YELLOW (WakeLock usage detected, verify release)"
else
    log "STEP 4 RESULT: GREEN (No static blockers for deep sleep)"
fi
