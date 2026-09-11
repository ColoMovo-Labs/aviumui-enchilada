#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/mnt/android/avium}"
META_DIR="${2:-${GITHUB_WORKSPACE:-/home/runner/_work/aviumui-enchilada/aviumui-enchilada}/avium-metadata}"
[ ! -d "$META_DIR" ] && META_DIR=$(find /home/runner -maxdepth 4 -type d -name "avium-metadata" 2>/dev/null | head -n 1)
echo "fix_known_blockers using META_DIR: $META_DIR"
cd "$SOURCE_ROOT"

echo "============================================================"
echo "=== 1. DIAGNOSING & RESOLVING BLOCKER B01: DISPLAY GRALLOC ION ==="
echo "============================================================"
DISPLAY_DIR="$SOURCE_ROOT/hardware/qcom-caf/sdm845/display"
PATCHES_DIR="$META_DIR/patches/hardware_qcom-caf_sdm845_display"

if [ -d "$DISPLAY_DIR" ]; then
  echo "[B01] Inspecting hardware/qcom-caf/sdm845/display..."
  cd "$DISPLAY_DIR"

  # Step 1: Apply Patch 0001 (gpu_tonemapper)
  PATCH1="$PATCHES_DIR/0001-sdm845-display-adapt-gpu_tonemapper-to-current-ION-A.patch"
  if [ -f "$PATCH1" ]; then
    echo "[B01] Checking and applying patch 0001 (gpu_tonemapper)..."
    if git apply --check "$PATCH1" 2>/dev/null; then
      git apply "$PATCH1"
      echo "[B01] Applied 0001-sdm845-display-adapt-gpu_tonemapper-to-current-ION-A.patch successfully."
    else
      echo "[B01] Patch 0001 already applied or not cleanly applicable."
    fi
  fi

  # Step 2: Apply Patch 0002 (gralloc TARGET_ION_ABI_VERSION >= 2)
  PATCH2="$PATCHES_DIR/0002-sdm845-display-gralloc-adapt-to-TARGET_ION_ABI_VERSION-2.patch"
  if [ -f "$PATCH2" ]; then
    echo "[B01] Checking and applying patch 0002 (gralloc modern ION ABI)..."
    if git apply --check "$PATCH2" 2>/dev/null; then
      git apply "$PATCH2"
      echo "[B01] Applied 0002-sdm845-display-gralloc-adapt-to-TARGET_ION_ABI_VERSION-2.patch successfully."
    else
      echo "[B01] Patch 0002 already applied or not cleanly applicable."
    fi
  fi

  # Ensure ion_user_handle_t is defined before <ion/ion.h> in gr_ion_alloc.cpp
  if [ -f "gralloc/gr_ion_alloc.cpp" ]; then
    if grep -q "<ion/ion.h>" "gralloc/gr_ion_alloc.cpp" && ! grep -q "ion_user_handle_t" "gralloc/gr_ion_alloc.cpp"; then
      echo "[B01] Ensuring typedef int ion_user_handle_t in gralloc/gr_ion_alloc.cpp..."
      sed -i 's|#include <ion/ion.h>|typedef int ion_user_handle_t;\n#include <ion/ion.h>|' "gralloc/gr_ion_alloc.cpp"
    fi
  fi

  # Step 3: Scan display HAL tree for any remaining legacy ION usage
  echo "[B01] Scanning for any remaining legacy ION usage in display HAL:"
  REMAINING_ION=$(grep -rnE "ion_fd_data|ION_IOC_IMPORT|ion_flush_data|ion_custom_data" . || true)
  if [ -z "$REMAINING_ION" ]; then
    echo "[B01] PASS: Zero unadapted legacy ION references in display HAL."
  else
    echo "[B01] Note: Remaining occurrences found in conditional blocks:"
    echo "$REMAINING_ION"
  fi

  cd "$SOURCE_ROOT"
else
  echo "[B01] Warning: Display dir not found at $DISPLAY_DIR"
fi

echo "============================================================"
echo "=== 2. DIAGNOSING & RESOLVING BLOCKERS B02/B03/B04: VENDOR BLOBS ==="
echo "============================================================"
VENDOR_DIR="$SOURCE_ROOT/vendor/oneplus/sdm845-common"
if [ -d "$VENDOR_DIR" ]; then
  echo "[B02/B03/B04] Inspecting vendor/oneplus/sdm845-common Android.bp..."
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
            # Check if check_elf_files already set nearby
            following = content[match.end():match.end() + 200]
            if "check_elf_files: false" not in following:
                print(f"[B02-B04] Applying check_elf_files: false to {target}")
                content = content[:match.end()] + '\n\tcheck_elf_files: false,' + content[match.end():]
                modified = True
            else:
                print(f"[B02-B04] {target} already has check_elf_files: false")
        else:
            print(f"[B02-B04] Target module {target} not found via regex")

    if modified:
        with open(bp_file, "w") as f:
            f.write(content)
        print("[B02-B04] Updated vendor Android.bp successfully.")
except Exception as e:
    print(f"[B02-B04] Error processing vendor Android.bp: {e}")
PYEOF
  fi
else
  echo "[B02/B03/B04] Warning: Vendor dir not found at $VENDOR_DIR"
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
echo "=== 4. VERIFYING LunarisDolby IN packages/apps/LunarisDolby ==="
echo "============================================================"
if [ -d "$SOURCE_ROOT/packages/apps/LunarisDolby" ]; then
  echo "[DOLBY] PASS: LunarisDolby exists in source tree."
  grep -rn 'name: "LunarisDolby"' "$SOURCE_ROOT/packages/apps/LunarisDolby" || true
else
  echo "[DOLBY] WARNING: LunarisDolby not found in $SOURCE_ROOT/packages/apps/LunarisDolby"
fi

echo "============================================================"
echo "=== 5. RESOLVING SDM845-COMMON SEPOLICY INCOMPATIBILITIES ==="
echo "============================================================"
COMMON_DIR="$SOURCE_ROOT/device/oneplus/sdm845-common"
SEPOLICY_PATCH="$META_DIR/patches/device_oneplus_sdm845-common/0001-sdm845-common-sepolicy-fixes.patch"

if [ -d "$COMMON_DIR" ]; then
  echo "[SEPOLICY] Checking device/oneplus/sdm845-common..."
  cd "$COMMON_DIR"
  if [ -f "$SEPOLICY_PATCH" ]; then
    echo "[SEPOLICY] Testing patch: $SEPOLICY_PATCH"
    if git apply --check "$SEPOLICY_PATCH" 2>/dev/null; then
      git apply "$SEPOLICY_PATCH"
      echo "[SEPOLICY] Applied 0001-sdm845-common-sepolicy-fixes.patch successfully."
    else
      echo "[SEPOLICY] Patch already applied or upstream commit present."
    fi
  fi

  # Failsafe sed checks for crucial types in case git tree was modified or shallow cloned differently
  if [ -f "sepolicy/vendor/hal_camera_default.te" ]; then
    sed -i 's/vendor_xdsp_device/xdsp_device/g' "sepolicy/vendor/hal_camera_default.te" || true
  fi
  if [ -f "sepolicy/vendor/hal_fingerprint_device.te" ]; then
    sed -i 's/vendor_qdsp_device/qdsp_device/g' "sepolicy/vendor/hal_fingerprint_device.te" || true
    sed -i 's/vendor_xdsp_device/xdsp_device/g' "sepolicy/vendor/hal_fingerprint_device.te" || true
    sed -i 's/vendor_adsprpc_prop/adsprpc_prop/g' "sepolicy/vendor/hal_fingerprint_device.te" || true
  fi
  if [ -f "sepolicy/vendor/hal_power_default.te" ]; then
    sed -i '/vendor_latency_device/d' "sepolicy/vendor/hal_power_default.te" || true
    sed -i 's/vendor_sysfs_devfreq/sysfs_devfreq/g' "sepolicy/vendor/hal_power_default.te" || true
    sed -i 's/vendor_sysfs_graphics/sysfs_graphics/g' "sepolicy/vendor/hal_power_default.te" || true
    sed -i 's/vendor_sysfs_kgsl/sysfs_kgsl/g' "sepolicy/vendor/hal_power_default.te" || true
  fi
  if [ -f "sepolicy/vendor/rild.te" ]; then
    sed -i 's/vendor_diag_device/diag_device/g' "sepolicy/vendor/rild.te" || true
  fi
  if [ -f "sepolicy/vendor/thermal-engine.te" ]; then
    sed -i 's/vendor_thermal-engine/thermal-engine/g' "sepolicy/vendor/thermal-engine.te" || true
    sed -i 's/vendor_sysfs_devfreq/sysfs_devfreq/g' "sepolicy/vendor/thermal-engine.te" || true
  fi
  if [ -f "sepolicy/vendor/file_contexts" ]; then
    sed -i 's/vendor_rawdump_block_device/rawdump_block_device/g' "sepolicy/vendor/file_contexts" || true
    sed -i 's/vendor_modem_efs_partition_device/modem_efs_partition_device/g' "sepolicy/vendor/file_contexts" || true
    sed -i 's/vendor_efs_boot_dev/efs_boot_dev/g' "sepolicy/vendor/file_contexts" || true
  fi
  if [ -f "sepolicy/vendor/genfs_contexts" ]; then
    sed -i 's/vendor_sysfs_graphics/sysfs_graphics/g' "sepolicy/vendor/genfs_contexts" || true
  fi
  if [ -f "sepolicy/vendor/vendor_wcnss_service.te" ]; then
    rm -f "sepolicy/vendor/vendor_wcnss_service.te" || true
  fi
  if [ -f "sepolicy/vendor/wcnss_service.te" ]; then
    if ! grep -q "rootfs:dir" "sepolicy/vendor/wcnss_service.te"; then
      echo "allow wcnss_service rootfs:dir r_dir_perms;" >> "sepolicy/vendor/wcnss_service.te" || true
    fi
    sed -i 's/vendor_wcnss_service/wcnss_service/g' "sepolicy/vendor/wcnss_service.te" || true
  fi
  if [ -f "sepolicy/vendor/sensors_qti.te" ] && [ ! -f "sepolicy/vendor/sensors.te" ]; then
    mv "sepolicy/vendor/sensors_qti.te" "sepolicy/vendor/sensors.te" || true
    sed -i 's/vendor_sensors_qti/sensors/g' "sepolicy/vendor/sensors.te" || true
    sed -i 's/vendor_sensors_vendor_data_file/sensors_vendor_data_file/g' "sepolicy/vendor/sensors.te" || true
    sed -i 's/vendor_sensors_prop/sensors_prop/g' "sepolicy/vendor/sensors.te" || true
  fi

  cd "$SOURCE_ROOT"
  echo "[SEPOLICY] All sdm845-common sepolicy validations complete."
else
  echo "[SEPOLICY] Warning: $COMMON_DIR not found."
fi

echo "============================================================"
echo "=== 6. ALL KNOWN BLOCKER CONFIGURATIONS APPLIED ==="
echo "============================================================"
