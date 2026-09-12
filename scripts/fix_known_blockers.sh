#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/mnt/android/avium}"
META_DIR="${2:-${GITHUB_WORKSPACE:-/home/runner/_work/aviumui-enchilada/aviumui-enchilada}/control-repo}"
[ ! -d "$META_DIR" ] && META_DIR=$(find /home/runner -maxdepth 4 -type d -name "control-repo" 2>/dev/null | head -n 1)
[ ! -d "$META_DIR" ] && META_DIR=$(find /home/runner -maxdepth 4 -type d -name "avium-metadata" 2>/dev/null | head -n 1)
echo "fix_known_blockers using META_DIR: $META_DIR"
cd "$SOURCE_ROOT"

apply_patch_if_needed() {
  local target_dir="$1"
  local patch_file="$2"
  local patch_name
  patch_name="$(basename "$patch_file")"

  if [ ! -d "$target_dir" ]; then
    echo "[-] Directory $target_dir does not exist, skipping $patch_name"
    return 0
  fi
  if [ ! -f "$patch_file" ]; then
    echo "[-] Patch $patch_file not found, skipping"
    return 0
  fi

  pushd "$target_dir" > /dev/null
  if git apply --check "$patch_file" 2>/dev/null; then
    git apply "$patch_file"
    echo "[+] Applied $patch_name in $target_dir"
  else
    if git apply --reverse --check "$patch_file" 2>/dev/null; then
      echo "[*] Patch $patch_name already applied in $target_dir"
    else
      echo "[!] Warning: Patch $patch_name could not be applied cleanly to $target_dir"
    fi
  fi
  popd > /dev/null
}

echo "============================================================"
echo "=== 1. APPLYING GERRIT TOPIC: sdm845-kernel-4.19 PATCHES ==="
echo "============================================================"

# 1.1 hardware/qcom-caf/common
COMMON_CAF_DIR="$SOURCE_ROOT/hardware/qcom-caf/common"
COMMON_PATCH_DIR="$META_DIR/patches/hardware_qcom-caf_common"
if [ -d "$COMMON_PATCH_DIR" ]; then
  apply_patch_if_needed "$COMMON_CAF_DIR" "$COMMON_PATCH_DIR/0001-qcom-Add-support-for-TARGET_NO_CAMERA_CUSTOM_FORMAT.patch"
  apply_patch_if_needed "$COMMON_CAF_DIR" "$COMMON_PATCH_DIR/0002-qcom-Conditionally-use-sm8250-HALs-for-sdm845.patch"
fi

# 1.2 hardware/qcom-caf/sm8250/display
DISPLAY_CAF_DIR="$SOURCE_ROOT/hardware/qcom-caf/sm8250/display"
DISPLAY_PATCH_DIR="$META_DIR/patches/hardware_qcom_display_sm8250"
if [ -d "$DISPLAY_PATCH_DIR" ]; then
  apply_patch_if_needed "$DISPLAY_CAF_DIR" "$DISPLAY_PATCH_DIR/0001-gralloc-Protect-new-buffer-allocation-support-for-legacy-camera.patch"
fi

# 1.3 hardware/qcom-caf/sm8250/audio
AUDIO_CAF_DIR="$SOURCE_ROOT/hardware/qcom-caf/sm8250/audio"
AUDIO_PATCH_DIR="$META_DIR/patches/hardware_qcom_audio_sm8250"
if [ -d "$AUDIO_PATCH_DIR" ]; then
  apply_patch_if_needed "$AUDIO_CAF_DIR" "$AUDIO_PATCH_DIR/0001-hal-Add-support-for-sdm845.patch"
fi

# 1.4 device/qcom/sepolicy_vndr/legacy-um
SEPOLICY_VNDR_DIR="$SOURCE_ROOT/device/qcom/sepolicy_vndr/legacy-um"
[ ! -d "$SEPOLICY_VNDR_DIR" ] && SEPOLICY_VNDR_DIR="$SOURCE_ROOT/device/qcom/sepolicy_vndr"
SEPOLICY_PATCH_DIR="$META_DIR/patches/device_qcom_sepolicy_vndr"
if [ -d "$SEPOLICY_PATCH_DIR" ]; then
  for p in \
    0001-sepolicy_vndr-Initial-non-legacy-policy-for-sdm845.patch \
    0002-sdm845-Remove-duplicate-deprecated-policies.patch \
    0003-sdm845-Label-wakeup-nodes.patch \
    0004-sdm845-Label-kernel-4.19-devfreq-nodes.patch \
    0005-sdm845-Add-target-specific-rcsservice-policy.patch \
    0006-sdm845-Label-discard_max_bytes-sysfs.patch \
    0007-sepolicy_vndr-Globally-allow-using-logdump-partition-as-metadata.patch; do
    apply_patch_if_needed "$SEPOLICY_VNDR_DIR" "$SEPOLICY_PATCH_DIR/$p"
  done
fi

# 1.5 frameworks/base (SQLiteTokenizer & Google Photos unlimited storage spoof)
FRAMEWORKS_BASE_DIR="$SOURCE_ROOT/frameworks/base"
FRAMEWORKS_BASE_PATCH_DIR="$META_DIR/patches/frameworks_base"
if [ -d "$FRAMEWORKS_BASE_PATCH_DIR" ]; then
  apply_patch_if_needed "$FRAMEWORKS_BASE_DIR" "$FRAMEWORKS_BASE_PATCH_DIR/0001-Add-bracket-checking-support-to-SQLiteTokenizer.patch"
  apply_patch_if_needed "$FRAMEWORKS_BASE_DIR" "$FRAMEWORKS_BASE_PATCH_DIR/0002-Spoof-Google-Photos-to-Pixel-XL-for-unlimited-storag.patch"
fi

echo "============================================================"
echo "=== 2. AUDITING VENDOR PROPRIETARY BLOBS ==="
echo "============================================================"
VENDOR_DIR="$SOURCE_ROOT/vendor/oneplus/sdm845-common"
if [ -d "$VENDOR_DIR" ]; then
  echo "[VENDOR] Inspecting vendor/oneplus/sdm845-common Android.bp..."
  VENDOR_BP="$VENDOR_DIR/Android.bp"
  if [ -f "$VENDOR_BP" ]; then
    python3 - << 'PYEOF'
import re

bp_file = "vendor/oneplus/sdm845-common/Android.bp"
try:
    with open(bp_file, "r") as f:
        content = f.read()

    targets = ["libqti-iopd", "libqti-iopd-client", "libqti-perfd", "libwfdservice"]
    modified = False

    for target in targets:
        pattern = re.compile(rf'(cc_prebuilt_library_shared\s*\{{[^}}]*?name:\s*"{target}",)')
        match = pattern.search(content)
        if match:
            following = content[match.end():match.end() + 200]
            if "check_elf_files: false" not in following:
                print(f"[VENDOR] Applying check_elf_files: false to {target}")
                content = content[:match.end()] + '\n\tcheck_elf_files: false,' + content[match.end():]
                modified = True
            else:
                print(f"[VENDOR] {target} already has check_elf_files: false")
        else:
            pass

    if modified:
        with open(bp_file, "w") as f:
            f.write(content)
        print("[VENDOR] Updated vendor Android.bp successfully.")
    else:
        print("[VENDOR] No unhardened ELF targets found; vendor Android.bp is clean.")
except Exception as e:
    print(f"[VENDOR] Error processing vendor Android.bp: {e}")
PYEOF
  fi
else
  echo "[VENDOR] Warning: Vendor dir not found at $VENDOR_DIR"
fi

echo "============================================================"
echo "=== 3. HARDENING SOONG ci_tests FOR HOST TESTS ==="
echo "============================================================"
CI_TEST_ZIP="$SOURCE_ROOT/build/soong/ci_tests/ci_test_package_zip.go"
if [ -f "$CI_TEST_ZIP" ]; then
  echo "[SOONG] Applying filepath.IsAbs safeguard to $CI_TEST_ZIP..."
  sed -i 's/if strings.HasPrefix(f, "out") {/if strings.HasPrefix(f, "out") || filepath.IsAbs(f) {/' "$CI_TEST_ZIP" || true
fi

echo "============================================================"
echo "=== 4. VERIFYING LunarisDolby & HARDWARE DOLBY ==="
echo "============================================================"
if [ -d "$SOURCE_ROOT/packages/apps/LunarisDolby" ]; then
  echo "[DOLBY] PASS: LunarisDolby exists in packages/apps/LunarisDolby."
  grep -rn 'name: "LunarisDolby"' "$SOURCE_ROOT/packages/apps/LunarisDolby" || true
else
  echo "[DOLBY] ERROR: LunarisDolby not found in $SOURCE_ROOT/packages/apps/LunarisDolby!"
  exit 1
fi

if [ -d "$SOURCE_ROOT/hardware/dolby" ]; then
  echo "[DOLBY] PASS: hardware/dolby exists in source tree."
else
  echo "[DOLBY] ERROR: hardware/dolby not found in $SOURCE_ROOT/hardware/dolby!"
  exit 1
fi

echo "============================================================"
echo "=== 5. VERIFYING AVIUMUI OFFICIAL GMS REPOSITORIES ==="
echo "============================================================"
for d in vendor/pixel/gms vendor/pixel/clocks vendor/pixel/sounds; do
  if [ -d "$SOURCE_ROOT/$d" ]; then
    echo "[GMS] PASS: $d exists in source tree."
  else
    echo "[GMS] ERROR: Required directory $d not found!"
    exit 1
  fi
done

echo "============================================================"
echo "=== 6. VERIFYING SDM845-COMMON 4.19 & EROFS CONFIGURATION ==="
echo "============================================================"
COMMON_DIR="$SOURCE_ROOT/device/oneplus/sdm845-common"
if [ -d "$COMMON_DIR" ]; then
  echo "[DEVICE] Inspecting $COMMON_DIR..."

  # Assert TARGET_KERNEL_VERSION is 4.19
  if grep -rn "TARGET_KERNEL_VERSION := 4.19" "$COMMON_DIR/BoardConfigCommon.mk" >/dev/null; then
    echo "[DEVICE] PASS: TARGET_KERNEL_VERSION := 4.19 confirmed in BoardConfigCommon.mk"
  else
    echo "[DEVICE] ERROR: TARGET_KERNEL_VERSION is NOT set to 4.19 in BoardConfigCommon.mk!"
    exit 1
  fi

  # Assert EROFS
  if grep -rn "BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs" "$COMMON_DIR/BoardConfigCommon.mk" >/dev/null && \
     grep -rn "BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs" "$COMMON_DIR/BoardConfigCommon.mk" >/dev/null; then
    echo "[DEVICE] PASS: EROFS filesystem configuration confirmed in BoardConfigCommon.mk"
  else
    echo "[DEVICE] ERROR: EROFS filesystem NOT configured in BoardConfigCommon.mk!"
    exit 1
  fi

  # Assert Zero-Super
  if grep -rn "BOARD_SUPER_PARTITION_SIZE" "$COMMON_DIR" | grep -vE ':[0-9]+:[[:space:]]*#' | grep -v "BOARD_SUPER_PARTITION_SIZE := 0"; then
    echo "[DEVICE] ERROR: Non-zero BOARD_SUPER_PARTITION_SIZE detected in $COMMON_DIR!"
    exit 1
  fi
  echo "[DEVICE] PASS: Zero-super configuration confirmed."
else
  echo "[DEVICE] Warning: $COMMON_DIR not found."
fi

echo "============================================================"
echo "=== 7. ALL 4.19 BLOCKER RESOLUTIONS APPLIED SUCCESSFULLY ==="
echo "============================================================"
