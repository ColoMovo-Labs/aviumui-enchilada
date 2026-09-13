#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/14-debug-logging.txt"
echo "=== Step 14: Debug Logging & Trace Overhead Audit ===" > "$REPORT"
echo "Timestamp: $(date -u)" >> "$REPORT"
echo "--------------------------------------------------------" >> "$REPORT"

HAS_RED=0
HAS_YELLOW=0

log() {
    echo "$1"
    echo "$1" >> "$REPORT"
}

cd "$SOURCE_ROOT"

log "[*] 1. Persistent Logging & Tracing Properties Audit:"
LOG_PROPS=$(grep -rnE "(logd\.|persist\.logd|ro\.logd|persist\.traced|persist\.sys\.perfetto|debug\.atrace)" device/oneplus/ vendor/oneplus/ 2>/dev/null || true)
if [ -n "$LOG_PROPS" ]; then
    log "  Logging properties found:"
    log "$LOG_PROPS"
else
    log "  [PASS] No custom persistent logd / perfetto properties in device trees"
fi

log "[*] 2. Logcat Buffer Size Configurations:"
LOG_SIZE=$(grep -rnE "(logd\.size|ro\.logd\.size)" device/oneplus/ 2>/dev/null || true)
if [ -n "$LOG_SIZE" ]; then
    log "  Logcat buffer size overrides: $LOG_SIZE"
    if echo "$LOG_SIZE" | grep -qE "(16M|32M|64M)"; then
        log "  [YELLOW FINDING] Exceptionally large logcat buffer configured (>16MB)"
        HAS_YELLOW=1
    fi
else
    log "  [PASS] Default logcat buffer size (256KB/userdebug default)"
fi

log "[*] 3. Binder Tracing / Kernel Ftrace / Perfetto Autostart:"
PERFETTO_RC=$(grep -rnE "(traced_probes|perfetto.*start|atrace.*start)" device/oneplus/ vendor/oneplus/ 2>/dev/null | grep -E "\.rc|\.sh" || true)
if [ -n "$PERFETTO_RC" ]; then
    log "  [YELLOW FINDING] Automated tracing services in init scripts:"
    log "$PERFETTO_RC"
    HAS_YELLOW=1
else
    log "  [PASS] No automated persistent ftrace/perfetto tracing daemon started on boot"
fi

log "--------------------------------------------------------"
if [ "$HAS_RED" -eq 1 ]; then
    log "STEP 14 RESULT: RED (Persistent heavy tracing/logging active)"
elif [ "$HAS_YELLOW" -eq 1 ]; then
    log "STEP 14 RESULT: YELLOW (Review debug buffer allocations)"
else
    log "STEP 14 RESULT: GREEN (No anomalous debug logging or continuous trace writes)"
fi
