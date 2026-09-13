#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

TARGET_SCRIPT="$OUT_DIR/avium-runtime-power-capture.sh"

cat << 'EOF' > "$TARGET_SCRIPT"
#!/bin/bash
# ==============================================================================
# AviumUI 16.2.1 Real-Device Runtime Power & Diagnostic Capture Script
# Strictly Read-Only. Safe for physical device execution.
# ==============================================================================

set -u

LABEL="${1:-capture_$(date +%Y%m%d_%H%M%S)}"
OUT_DIR="./power_dumps/$LABEL"
mkdir -p "$OUT_DIR"

echo "=================================================="
echo "Starting AviumUI Runtime Power Capture -> $OUT_DIR"
echo "=================================================="

# Helper function
run_dump() {
    local cmd="$1"
    local outfile="$2"
    echo "[*] Collecting: $cmd"
    eval "$cmd" > "$OUT_DIR/$outfile" 2>&1 || echo "[-] Skipped (not available)" >> "$OUT_DIR/$outfile"
}

# 1. Android Framework Dumpsys
run_dump "adb shell dumpsys batterystats" "dumpsys_batterystats.txt"
run_dump "adb shell dumpsys power" "dumpsys_power.txt"
run_dump "adb shell dumpsys deviceidle" "dumpsys_deviceidle.txt"
run_dump "adb shell dumpsys alarm" "dumpsys_alarm.txt"
run_dump "adb shell dumpsys jobscheduler" "dumpsys_jobscheduler.txt"
run_dump "adb shell dumpsys location" "dumpsys_location.txt"
run_dump "adb shell dumpsys thermalservice" "dumpsys_thermalservice.txt"
run_dump "adb shell dumpsys battery" "dumpsys_battery.txt"
run_dump "adb shell dumpsys SurfaceFlinger" "dumpsys_surfaceflinger.txt"
run_dump "adb shell dumpsys activity processes" "dumpsys_processes.txt"
run_dump "adb shell dumpsys netstats detail" "dumpsys_netstats.txt"

# 2. Kernel Wakelocks & Wakeup Sources
run_dump "adb shell cat /proc/wakelocks" "kernel_proc_wakelocks.txt"
run_dump "adb shell su -c 'cat /sys/kernel/debug/wakeup_sources'" "kernel_wakeup_sources.txt"

# 3. Battery & Power Supply Sysfs Nodes
run_dump "adb shell ls -la /sys/class/power_supply/battery/" "sysfs_battery_nodes_list.txt"
run_dump "adb shell 'for f in /sys/class/power_supply/battery/*; do [ -f \"\$f\" ] && echo \"=== \$f ===\" && cat \"\$f\" 2>/dev/null; done'" "sysfs_battery_all_values.txt"
run_dump "adb shell 'for f in /sys/class/power_supply/usb/*; do [ -f \"\$f\" ] && echo \"=== \$f ===\" && cat \"\$f\" 2>/dev/null; done'" "sysfs_usb_all_values.txt"

# 4. CPU Frequency & Idle State Residency
run_dump "adb shell 'for c in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do echo \"\$c: \$(cat \$c 2>/dev/null)\"; done'" "cpu_cur_frequencies.txt"
run_dump "adb shell 'for c in /sys/devices/system/cpu/cpu*/cpufreq/stats/time_in_state; do echo \"=== \$c ===\"; cat \"\$c\" 2>/dev/null; done'" "cpu_time_in_state.txt"
run_dump "adb shell 'for i in /sys/devices/system/cpu/cpu*/cpuidle/state*/time; do echo \"\$i: \$(cat \$i 2>/dev/null)\"; done'" "cpu_idle_times.txt"

# 5. GPU Frequencies & Thermal Zones
run_dump "adb shell cat /sys/class/kgsl/kgsl-3d0/devfreq/cur_freq" "gpu_cur_freq.txt"
run_dump "adb shell 'for t in /sys/class/thermal/thermal_zone*/temp; do echo \"\$t: \$(cat \$t 2>/dev/null)\"; done'" "thermal_zone_temps.txt"

echo "=================================================="
echo "Capture Completed. All logs stored in $OUT_DIR"
echo "=================================================="
EOF

chmod +x "$TARGET_SCRIPT"
echo "Generated $TARGET_SCRIPT successfully."
