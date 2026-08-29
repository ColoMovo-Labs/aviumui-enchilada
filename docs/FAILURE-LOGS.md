# Triage & Diagnostic Log Collection Guide

This guide defines the standardized procedures for capturing, isolating, and triaging logs across the three primary failure scenarios encountered during the AviumUI 16.2.x bring-up on the OnePlus 6 (`enchilada`).

---

## 🛑 Scenario 1: Compile Failure (Cloud / Local Build)

When a build fails during Soong, Blueprint, Ninja, or Clang execution:

### 1. Capture Full & Tail Build Logs
```bash
# Save complete compilation log
tee build_full.log

# Extract the concluding 300 lines containing the final failure summary
tail -n 300 build.log > build_failure_tail.log
```

### 2. Identify the Primary Root Cause (First FAILED Target)
Ninja executes parallel jobs; the final lines in a failed build often show cascading secondary failures. Always search upwards for the **first `FAILED:` block**:
```bash
# Locate the initial target failure and the preceding command line
grep -n -B 3 -A 15 "^FAILED:" build.log | head -n 30 > build_first_error.log
```

### 3. Key Compile-Time Diagnostic Patterns
* **Soong / Blueprint**: `error: ... unresolved dependency` or `module ... missing variant`.
* **Clang / C++**: `#include <...>` missing header, `error: no member named`, `incompatible type`.
* **SEPolicy**: `neverallow` violations or syntax errors in `.te` policy files.
* **AIDL / HIDL**: Interface hash mismatch or missing `@export` annotations.

---

## ⚡ Scenario 2: Boot Failure Before Boot Animation (Early Kernel / Init Panic)

When the device vibrates on power-on but hangs on the bootloader splash (`1+` logo) or reboots to Qualcomm CrashDump / Fastboot:

### 1. Recovery ADB Access
Attempt to boot into recovery (`lineage_recovery` / TWRP) to query the device:
```bash
adb devices
adb shell
```

### 2. Extract Kernel Crash Logs via pstore / ramoops
SDM845 preserves the panic buffer across warm resets in RAM:
```bash
# Extract console ramoops from previous kernel crash
adb shell cat /sys/fs/pstore/console-ramoops-0 > ramoops_crash.log
adb shell cat /sys/fs/pstore/console-ramoops > ramoops_crash.log

# Check persistent message log
adb shell cat /dev/pmsg0 > pmsg_crash.log

# Check legacy last_kmsg if mounted
adb shell cat /proc/last_kmsg > last_kmsg.log
```

### 3. Common Early Boot Root Causes
* **Device Tree (DTB/DTBO)**: Incompatible panel timing, regulator voltage crash, or pinmux error.
* **Kernel Command Line**: Missing `androidboot.boot_devices=soc/1d84000.ufshc` or missing EROFS mount flags.
* **Init Ramdisk**: Missing dynamic partition mounting rules in `init.target.rc` / `fstab.qcom`.

---

## 📱 Scenario 3: Boot Animation or Android Runtime Failure (Bootloop / Soft Brick)

When the device reaches the AviumUI boot animation but loops indefinitely, crashes back to recovery, or crashes SystemUI:

### 1. Stream Full Logcat & Kernel Ring Buffer
Connect the device over USB with ADB enabled (`userdebug` builds have ADB root enabled by default):
```bash
# Capture full logcat buffer from boot start
adb wait-for-device
adb logcat -b all -d > logcat_full.log

# Capture dmesg kernel buffer
adb shell dmesg > dmesg_runtime.log
```

### 2. Extract Java & Native Crash Tombstones
```bash
# Pull native crash dumps and stack traces
adb pull /data/tombstones/ ./tombstones/
adb pull /data/anr/ ./anr/
adb pull /data/system/dropbox/ ./dropbox/
```

### 3. Filter for Fatal Exceptions & System Server Crashes
```bash
# Filter for critical Android runtime exceptions
grep -E "FATAL EXCEPTION|AndroidRuntime|SystemServer|SIGSEGV|SIGBUS" logcat_full.log > logcat_fatal.log

# Filter for SELinux permission denials
grep "avc: denied" logcat_full.log > selinux_denials.log
grep "avc: denied" dmesg_runtime.log > selinux_dmesg_denials.log
```

---

## 📤 Submission Protocol

When archiving logs for team review:
1. Attach `build_first_error.log` (for build issues) or `logcat_fatal.log` + `dmesg_runtime.log` (for boot issues).
2. Note the tested commit hash of `aviumui-enchilada-manifests` and the target lunch flavor (`lineage_enchilada-bp4a-userdebug`).
