#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/02-kernel-power.txt"
echo "=== Step 2: Kernel Power Management Audit ===" > "$REPORT"
echo "Timestamp: $(date -u)" >> "$REPORT"
echo "--------------------------------------------------------" >> "$REPORT"

HAS_RED=0
HAS_YELLOW=0

log() {
    echo "$1"
    echo "$1" >> "$REPORT"
}

cd "$SOURCE_ROOT"
KERNEL_DIR="kernel/oneplus/sdm845"
DEFCONFIGS=("$KERNEL_DIR/arch/arm64/configs/vendor/sdm845-perf_defconfig" "$KERNEL_DIR/arch/arm64/configs/vendor/enchilada.config")

log "[*] 1. Kernel Power Management Defconfig Audit:"
for cfg in "${DEFCONFIGS[@]}"; do
    if [ -f "$cfg" ]; then
        log "  Found defconfig: $cfg"
        for opt in CONFIG_CPU_FREQ CONFIG_CPU_IDLE CONFIG_PM_SLEEP CONFIG_SUSPEND CONFIG_PM_WAKELOCKS CONFIG_PM_AUTOSLEEP CONFIG_DEVFREQ_GOV_PERFORMANCE CONFIG_CPU_FREQ_GOV_PERFORMANCE CONFIG_CPU_FREQ_GOV_SCHEDUTIL CONFIG_SCHED_WALT CONFIG_UCLAMP_TASK; do
            MATCH=$(grep -E "^${opt}=" "$cfg" || true)
            if [ -n "$MATCH" ]; then
                log "    $MATCH"
            else
                log "    # $opt is not set"
            fi
        done
    else
        log "  [WARN] Defconfig $cfg not found"
        HAS_YELLOW=1
    fi
done

# Check if performance governor is set as default
DEF_GOV=$(grep -rn "CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y" "$KERNEL_DIR/arch/arm64/configs" 2>/dev/null || true)
if [ -n "$DEF_GOV" ]; then
    log "  [RED FINDING] CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE enabled in kernel configs: $DEF_GOV"
    HAS_RED=1
else
    log "  [PASS] Default governor is NOT performance"
fi

log "[*] 2. Device Init RC Power & Frequency Audit:"
DEVICE_INIT_DIRS=("device/oneplus/sdm845-common/init" "device/oneplus/enchilada")
for idir in "${DEVICE_INIT_DIRS[@]}"; do
    if [ -d "$idir" ]; then
        log "  Auditing $idir..."
        # Search for abnormal min_freq pinning or performance governor
        PERF_GOV=$(grep -rnE "scaling_governor[[:space:]]+performance" "$idir" 2>/dev/null || true)
        if [ -n "$PERF_GOV" ]; then
            log "  [RED FINDING] performance governor set in init script: $PERF_GOV"
            HAS_RED=1
        else
            log "  [PASS] No permanent performance governor in $idir"
        fi

        # Check for abnormal min_freq pinning
        MIN_FREQ=$(grep -rnE "scaling_min_freq" "$idir" 2>/dev/null || true)
        log "  Inspecting scaling_min_freq writes in $idir:"
        if [ -n "$MIN_FREQ" ]; then
            log "$MIN_FREQ"
        else
            log "    (No static scaling_min_freq writes found)"
        fi

        # Check for permanent input_boost or boostpulse without timeout
        BOOST_CONFIGS=$(grep -rnE "(input_boost|sched_boost|boostpulse)" "$idir" 2>/dev/null || true)
        log "  Inspecting CPU boost configs in $idir:"
        if [ -n "$BOOST_CONFIGS" ]; then
            log "$BOOST_CONFIGS"
        fi
    fi
done

log "[*] 3. Vendor Power / Perf Daemon Audit:"
PERF_DAEMONS=$(grep -rnE "(perfd|vendor\.perf|msm_performance)" device/oneplus vendor/oneplus 2>/dev/null | grep -E "\.rc|\.sh" || true)
if [ -n "$PERF_DAEMONS" ]; then
    log "  Active perf daemon references in device/vendor scripts:"
    log "$PERF_DAEMONS"
else
    log "  [PASS] No rogue vendor performance daemons"
fi

log "--------------------------------------------------------"
if [ "$HAS_RED" -eq 1 ]; then
    log "STEP 2 RESULT: RED (Suspicious governor or frequency locking)"
elif [ "$HAS_YELLOW" -eq 1 ]; then
    log "STEP 2 RESULT: YELLOW (Potential tuning items found)"
else
    log "STEP 2 RESULT: GREEN (Kernel power configuration is normal)"
fi
