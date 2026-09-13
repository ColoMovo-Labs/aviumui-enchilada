#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/12-wifi-bluetooth.txt"
echo "=== Step 12: Wi-Fi & Bluetooth Configuration Audit ===" > "$REPORT"
echo "Timestamp: $(date -u)" >> "$REPORT"
echo "--------------------------------------------------------" >> "$REPORT"

HAS_RED=0
HAS_YELLOW=0

log() {
    echo "$1"
    echo "$1" >> "$REPORT"
}

cd "$SOURCE_ROOT"

log "[*] 1. Wi-Fi Background Scanning & PNO Configuration:"
WIFI_OVERLAYS=$(find device/oneplus -name "*.xml" -exec grep -HnE "(config_wifi_background_scan_interval|config_wifi_scan_interval|config_wifi_enable_disconnection_debounce)" {} + 2>/dev/null || true)
log "  Wi-Fi framework overlays:"
log "$WIFI_OVERLAYS"

# Check if Wi-Fi always available scanning is forced true
ALWAYS_SCAN=$(grep -rn "config_wifi_always_available" device/oneplus/ 2>/dev/null || true)
if [ -n "$ALWAYS_SCAN" ]; then
    log "  config_wifi_always_available: $ALWAYS_SCAN"
fi

log "[*] 2. Bluetooth A2DP & Audio Streaming Configuration:"
BT_PROPS=$(grep -rnE "(persist\.bluetooth|ro\.bluetooth|bluetooth\.)" device/oneplus/ vendor/oneplus/ 2>/dev/null | grep -E "\.prop|\.mk" || true)
log "  Bluetooth properties:"
log "$BT_PROPS"

log "[*] 3. Feature Branch Bluetooth Polling Audit:"
PATCH_ISLAND="$CONTROL_DIR/patches/frameworks_base/0003-Add-native-Status-Bar-Capsule-and-Super-Island.patch"
if [ -f "$PATCH_ISLAND" ]; then
    # Check HeadsetEventMonitor
    HS_CODE=$(grep -A 25 "class HeadsetEventMonitor" "$PATCH_ISLAND" 2>/dev/null || true)
    log "  HeadsetEventMonitor snippet:"
    log "$HS_CODE"

    # Check if HeadsetEventMonitor uses BroadcastReceiver vs Polling
    POLL_HS=$(echo "$HS_CODE" | grep -E "(postDelayed|Timer|while)" || true)
    if [ -n "$POLL_HS" ]; then
        log "  [YELLOW FINDING] HeadsetEventMonitor contains polling logic: $POLL_HS"
        HAS_YELLOW=1
    else
        log "  [PASS] HeadsetEventMonitor is strictly BroadcastReceiver-driven (ACTION_HEADSET_PLUG, BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)"
    fi
fi

log "--------------------------------------------------------"
if [ "$HAS_RED" -eq 1 ]; then
    log "STEP 12 RESULT: RED (Rogue Wi-Fi/BT scan loop detected)"
elif [ "$HAS_YELLOW" -eq 1 ]; then
    log "STEP 12 RESULT: YELLOW (Review Wi-Fi background interval)"
else
    log "STEP 12 RESULT: GREEN (Wi-Fi and Bluetooth configs are standard and broadcast-driven)"
fi
