#!/bin/bash
set -euo pipefail

STEP_NUM="${1:-1}"
SOURCE_ROOT="${2:-/home/runner/android/avium}"
CONTROL_DIR="${3:-$(pwd)}"
OUT_DIR="${4:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$STEP_NUM" in
    1)
        bash "$SCRIPT_DIR/01_build_identity.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    2)
        bash "$SCRIPT_DIR/02_kernel_power.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    3)
        bash "$SCRIPT_DIR/03_cpu_gpu_power.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    4)
        bash "$SCRIPT_DIR/04_suspend_wakelock.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    5)
        bash "$SCRIPT_DIR/05_systemui_runtime_loops.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    6)
        bash "$SCRIPT_DIR/06_blur_rendering.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    7)
        bash "$SCRIPT_DIR/07_display_aod.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    8)
        bash "$SCRIPT_DIR/08_charging_policy.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    9)
        bash "$SCRIPT_DIR/09_thermal_policy.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    10)
        bash "$SCRIPT_DIR/10_gnss_location.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    11)
        bash "$SCRIPT_DIR/11_radio_ims.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    12)
        bash "$SCRIPT_DIR/12_wifi_bluetooth.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    13)
        bash "$SCRIPT_DIR/13_gms_risk.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    14)
        bash "$SCRIPT_DIR/14_debug_logging.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    15)
        bash "$SCRIPT_DIR/15_power_sensitive_diff.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    16)
        bash "$SCRIPT_DIR/16_generate_runtime_capture.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    17)
        bash "$SCRIPT_DIR/17_generate_runtime_test_md.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    18)
        bash "$SCRIPT_DIR/18_generate_charge_test.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    19)
        bash "$SCRIPT_DIR/19_final_power_audit.sh" "$SOURCE_ROOT" "$CONTROL_DIR" "$OUT_DIR"
        ;;
    *)
        echo "Unknown step: $STEP_NUM"
        exit 1
        ;;
esac
