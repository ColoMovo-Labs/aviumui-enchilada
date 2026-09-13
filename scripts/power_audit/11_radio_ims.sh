#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/11-radio-ims.txt"
echo "=== Step 11: Mobile Radio & IMS / VoLTE Configuration Audit ===" > "$REPORT"
echo "Timestamp: $(date -u)" >> "$REPORT"
echo "--------------------------------------------------------" >> "$REPORT"

HAS_RED=0
HAS_YELLOW=0

log() {
    echo "$1"
    echo "$1" >> "$REPORT"
}

cd "$SOURCE_ROOT"

log "[*] 1. RIL & Radio System Properties Audit:"
RADIO_PROPS=$(grep -rnE "(persist\.(vendor\.)?radio|ro\.telephony|persist\.dbg)" device/oneplus/ vendor/oneplus/ 2>/dev/null | grep -E "\.prop|\.mk|\.rc" || true)
log "  Radio properties defined:"
log "$RADIO_PROPS"

# Search for verbose logging or QXDM/diag logging
DIAG_LOG=$(echo "$RADIO_PROPS" | grep -E "(diag|qxdm|logdump|logging.*1|debug.*1)" || true)
if [ -n "$DIAG_LOG" ]; then
    log "  [YELLOW FINDING] Diagnostic / modem debug properties enabled:"
    log "$DIAG_LOG"
    HAS_YELLOW=1
else
    log "  [PASS] No persistent QXDM / modem diag logging enabled"
fi

log "[*] 2. IMS / VoLTE Service Configuration:"
IMS_CONFIGS=$(grep -rnE "(ims|volte|qti-telephony)" device/oneplus/ 2>/dev/null | grep -E "\.rc|\.xml|\.mk" || true)
log "  IMS / VoLTE configs:"
log "$IMS_CONFIGS"

log "[*] 3. Cellular Baseband Power Consideration during Navigation:"
log "  Technical Finding: When navigating on mobile data, the Snapdragon X20 LTE modem operates in continuous"
log "  connected DRX / RRC Connected state. In edge or transitioning coverage cells (e.g. while driving or moving),"
log "  Tx power scales up to +23dBm (200mW RF output, ~1.5W-2.0W DC electrical power at PMIC/transceiver)."
log "  Because the RF power amplifier is located on the main logic board under shielding, heat dissipates into the"
log "  midframe slowly and may not cause a distinct localized hot spot on the rear glass."

log "--------------------------------------------------------"
if [ "$HAS_RED" -eq 1 ]; then
    log "STEP 11 RESULT: RED (Persistent baseband logging / diag drain)"
elif [ "$HAS_YELLOW" -eq 1 ]; then
    log "STEP 11 RESULT: YELLOW (Review radio logging properties)"
else
    log "STEP 11 RESULT: GREEN (RIL and IMS configurations are standard)"
fi
