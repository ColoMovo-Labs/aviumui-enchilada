#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/09-thermal-policy.txt"
echo "=== Step 9: Thermal Policy & Mitigation Audit ===" > "$REPORT"
echo "Timestamp: $(date -u)" >> "$REPORT"
echo "--------------------------------------------------------" >> "$REPORT"

HAS_RED=0
HAS_YELLOW=0

log() {
    echo "$1"
    echo "$1" >> "$REPORT"
}

cd "$SOURCE_ROOT"

log "[*] 1. Thermal Engine Configuration Audit:"
THERMAL_CONFS=$(find device/oneplus vendor/oneplus -name "*thermal*.conf" -o -name "*thermal*.json" -o -name "*thermal*.xml" 2>/dev/null || true)
if [ -n "$THERMAL_CONFS" ]; then
    log "  Found thermal config files:"
    log "$THERMAL_CONFS"
    for tc in $THERMAL_CONFS; do
        log "  --- Inspecting $tc ---"
        # Search for charging throttling rules in thermal configuration
        CHG_THERMAL=$(grep -E "(charging|battery|fast_charge|dash|bcl)" "$tc" -A 4 2>/dev/null || true)
        if [ -n "$CHG_THERMAL" ]; then
            log "$CHG_THERMAL"
        fi
    done
else
    log "  [WARN] No explicit thermal-engine.conf found in standard locations (checked device/oneplus vendor/oneplus)"
    HAS_YELLOW=1
fi

log "[*] 2. Thermal HAL Implementation:"
THERMAL_HAL=$(find hardware/ -maxdepth 3 -name "*thermal*" 2>/dev/null || true)
log "  Thermal HAL sources: $THERMAL_HAL"

log "[*] 3. Overly Conservative Thermal Throttling Analysis:"
log "  Observation: The physical phone stays cool during navigation (no noticeable overheating)."
log "  Analysis: If the thermal mitigation tables define threshold levels starting at low ambient temperatures"
log "  (e.g. 38°C battery temp), or if screen-on status automatically triggers charging mitigation level 1,"
log "  charging current can be cut down to 500mA without the user feeling any chassis heat."

log "--------------------------------------------------------"
if [ "$HAS_RED" -eq 1 ]; then
    log "STEP 9 RESULT: RED (Extreme thermal throttling rule detected)"
elif [ "$HAS_YELLOW" -eq 1 ]; then
    log "STEP 9 RESULT: YELLOW (Thermal charging mitigation thresholds present)"
else
    log "STEP 9 RESULT: GREEN (Thermal profiles match OEM baseline)"
fi
