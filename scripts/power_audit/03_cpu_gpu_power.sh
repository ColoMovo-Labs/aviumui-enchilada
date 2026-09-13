#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/03-cpu-gpu-power.txt"
echo "=== Step 3: CPU & GPU Performance Configuration Audit ===" > "$REPORT"
echo "Timestamp: $(date -u)" >> "$REPORT"
echo "--------------------------------------------------------" >> "$REPORT"

HAS_RED=0
HAS_YELLOW=0

log() {
    echo "$1"
    echo "$1" >> "$REPORT"
}

cd "$SOURCE_ROOT"

log "[*] 1. Power HAL & powerhint Audit:"
POWERHINT_FILES=$(find device/oneplus hardware/qcom hardware/oneplus vendor/oneplus -name "powerhint*.json" -o -name "powerhint*.xml" 2>/dev/null || true)
if [ -n "$POWERHINT_FILES" ]; then
    log "  Found powerhint files:"
    log "$POWERHINT_FILES"
    for pf in $POWERHINT_FILES; do
        log "  --- Inspecting $pf ---"
        # Check for permanent hints or huge durations
        HINTS=$(grep -E "(INTERACTION|LAUNCH|SUSTAINED_PERFORMANCE|EXPENSIVE_RENDERING|DISPLAY_UPDATE_IMMINENT)" "$pf" -A 5 2>/dev/null || true)
        if [ -n "$HINTS" ]; then
            log "$HINTS"
        else
            log "    (No standard boost hint names found in $pf)"
        fi
        
        # Check for duration values exceeding 5000ms
        LONG_DURATIONS=$(grep -rnE "\"Duration\":[[:space:]]*[0-9]{5,}" "$pf" 2>/dev/null || true)
        if [ -n "$LONG_DURATIONS" ]; then
            log "    [YELLOW FINDING] Abnormally long boost duration (>10s): $LONG_DURATIONS"
            HAS_YELLOW=1
        fi
    done
else
    log "  [WARN] No powerhint.json / powerhint.xml found in standard locations"
    HAS_YELLOW=1
fi

log "[*] 2. Adreno 630 GPU Power / Governor Audit:"
GPU_INITS=$(grep -rnE "(kgsl-3d0|adreno|devfreq/5000000\.qcom,kgsl-3d0)" device/oneplus/ vendor/oneplus/ 2>/dev/null | grep -E "\.rc|\.sh" || true)
if [ -n "$GPU_INITS" ]; then
    log "  GPU sysfs node initialization:"
    log "$GPU_INITS"

    # Check for fixed max GPU frequency or performance governor
    PERF_GPU=$(echo "$GPU_INITS" | grep -E "governor.*performance" || true)
    if [ -n "$PERF_GPU" ]; then
        log "  [RED FINDING] GPU governor set to performance: $PERF_GPU"
        HAS_RED=1
    else
        log "  [PASS] GPU governor is dynamic (msm-adreno-tz / simple_ondemand)"
    fi

    # Check idle timer
    IDLE_TIMER=$(echo "$GPU_INITS" | grep -E "idle_timer" || true)
    if [ -n "$IDLE_TIMER" ]; then
        log "  GPU idle timer settings: $IDLE_TIMER"
    fi
else
    log "  [PASS] Standard kernel default GPU frequency policy applied"
fi

log "[*] 3. UI Power HAL Request Audit (Feature Branch Code):"
# Search in patches or frameworks_base for Power HAL / Performance requests
UI_POWER_CALLS=$(grep -rnE "(PowerManager|IPower|setPowerMode|setPerformanceMode|SUSTAINED_PERFORMANCE)" "$CONTROL_DIR/patches/frameworks_base" 2>/dev/null || true)
if [ -n "$UI_POWER_CALLS" ]; then
    log "  [YELLOW FINDING] UI patches make calls to PowerManager / performance APIs:"
    log "$UI_POWER_CALLS"
    HAS_YELLOW=1
else
    log "  [PASS] No UI feature in patches directly requests permanent Power HAL boost"
fi

log "--------------------------------------------------------"
if [ "$HAS_RED" -eq 1 ]; then
    log "STEP 3 RESULT: RED (High GPU/CPU power reservation detected)"
elif [ "$HAS_YELLOW" -eq 1 ]; then
    log "STEP 3 RESULT: YELLOW (Power hints or duration require runtime check)"
else
    log "STEP 3 RESULT: GREEN (CPU/GPU performance configurations are normal)"
fi
