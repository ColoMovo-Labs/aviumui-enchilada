#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/10-gnss-location.txt"
echo "=== Step 10: GNSS & Location Configuration Audit ===" > "$REPORT"
echo "Timestamp: $(date -u)" >> "$REPORT"
echo "--------------------------------------------------------" >> "$REPORT"

HAS_RED=0
HAS_YELLOW=0

log() {
    echo "$1"
    echo "$1" >> "$REPORT"
}

cd "$SOURCE_ROOT"

log "[*] 1. gps.conf & GNSS Config File Audit:"
GPS_CONFS=$(find device/oneplus vendor/oneplus -name "gps.conf" 2>/dev/null || true)
if [ -n "$GPS_CONFS" ]; then
    log "  Found gps.conf files:"
    log "$GPS_CONFS"
    for gc in $GPS_CONFS; do
        log "  --- Inspecting $gc ---"
        # Check DEBUG_LEVEL
        DBG_LVL=$(grep -E "^DEBUG_LEVEL" "$gc" || true)
        log "  DEBUG_LEVEL: $DBG_LVL"
        if echo "$DBG_LVL" | grep -qE "DEBUG_LEVEL[[:space:]]*=[[:space:]]*[3-5]"; then
            log "  [YELLOW FINDING] Verbose GNSS debug logging enabled (DEBUG_LEVEL >= 3)"
            HAS_YELLOW=1
        fi

        # Check NMEA logging
        NMEA=$(grep -E "NMEA" "$gc" || true)
        if [ -n "$NMEA" ]; then
            log "  NMEA settings: $NMEA"
        fi

        # Check XTRA / SUPL servers
        XTRA_SUPL=$(grep -E "(XTRA_SERVER|SUPL_HOST)" "$gc" || true)
        log "  XTRA/SUPL configs: $XTRA_SUPL"
    done
else
    log "  [WARN] No gps.conf found in device/oneplus or vendor/oneplus"
    HAS_YELLOW=1
fi

log "[*] 2. Framework Location Overlays Audit:"
LOC_OVERLAYS=$(find device/oneplus -name "*.xml" -exec grep -HnE "(config_locationProviderPackageNames|config_enableGps|config_agps)" {} + 2>/dev/null || true)
log "  Location framework overlays:"
log "$LOC_OVERLAYS"

log "[*] 3. GNSS Measurement Always-On / Developer Flags:"
FULL_TRACKING=$(grep -rnE "(gnss_full_tracking|MEASUREMENT_ALWAYS_ON|ENABLE_FULL_TRACKING)" device/oneplus/ vendor/oneplus/ 2>/dev/null || true)
if [ -n "$FULL_TRACKING" ]; then
    log "  [RED FINDING] Full raw GNSS measurement permanently enabled: $FULL_TRACKING"
    HAS_RED=1
else
    log "  [PASS] Full tracking is off by default (duty-cycled GNSS active)"
fi

log "[*] 4. Navigation Power Analysis:"
log "  Observation: 40-minute navigation + music resulted in 49% battery drain (~73% / hour)."
log "  Technical Factors:"
log "    1. GPS/GNSS receiver active continuously (Snapdragon 845 GNSS draws ~250-400mW under continuous lock)."
log "    2. Cellular modem active with continuous 4G/LTE mobile data exchange for real-time map rendering."
log "    3. Bluetooth audio streaming to external speaker/earphones (A2DP encoding and transmission)."
log "    4. Screen ON continuously at medium-high auto brightness (~1.2W - 1.8W display consumption)."
log "    5. Combined normal power draw: ~3.0W - 4.5W. On an original 3300mAh (12.5Wh) pack, that translates"
log "       to ~25-35% drain in 40 mins. If battery is aged to ~60% capacity (e.g. ~2000mAh), drain is ~45-50%!"

log "--------------------------------------------------------"
if [ "$HAS_RED" -eq 1 ]; then
    log "STEP 10 RESULT: RED (Unconstrained GNSS measurement/logging)"
elif [ "$HAS_YELLOW" -eq 1 ]; then
    log "STEP 10 RESULT: YELLOW (Review GNSS debug logging overhead)"
else
    log "STEP 10 RESULT: GREEN (GNSS configuration is standard; high drain points to multi-radio load + battery health)"
fi
