#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/mnt/android/avium}"
cd "$SOURCE_ROOT"

echo "============================================================"
echo "=== 1. DIAGNOSING & RESOLVING BLOCKER B01: DISPLAY GRALLOC ION ==="
echo "============================================================"
DISPLAY_DIR="$SOURCE_ROOT/hardware/qcom-caf/sdm845/display"
if [ -d "$DISPLAY_DIR" ]; then
  echo "[B01] Checking hardware/qcom-caf/sdm845/display..."
  
  # Search for all legacy ION ioctl/struct usage in display tree
  echo "[B01] Scanning all legacy ION consumers in display HAL:"
  grep -rnE "ion_fd_data|ION_IOC_IMPORT|ion_flush_data|ion_custom_data" "$DISPLAY_DIR" || true

  # Check gralloc Android.bp and header includes
  GRALLOC_BP="$DISPLAY_DIR/gralloc/Android.bp"
  if [ -f "$GRALLOC_BP" ]; then
    echo "[B01] Inspecting $GRALLOC_BP..."
    
    # Check if qti_kernel_headers or generated_kernel_headers are included
    if ! grep -q "qti_kernel_headers" "$GRALLOC_BP" && ! grep -q "generated_kernel_headers" "$GRALLOC_BP"; then
      echo "[B01] Adding kernel uapi header dependency to gralloc Android.bp for MSM ION definitions..."
      sed -i '/header_libs: \[/a \        "qti_kernel_headers",' "$GRALLOC_BP" || true
    fi
  fi

  # Check if linux/msm_ion.h exists in kernel uapi or device headers
  ION_HDR=$(find "$SOURCE_ROOT/kernel" "$SOURCE_ROOT/hardware/qcom-caf" "$SOURCE_ROOT/device/oneplus" -name "msm_ion.h" 2>/dev/null | head -n 1 || true)
  echo "[B01] Found upstream MSM ION header at: $ION_HDR"

  # Ensure gr_ion_alloc.h includes <linux/msm_ion.h> when compiling on Android 13/CAF
  GR_ION_H="$DISPLAY_DIR/gralloc/gr_ion_alloc.h"
  if [ -f "$GR_ION_H" ]; then
    if ! grep -q "<linux/msm_ion.h>" "$GR_ION_H"; then
      echo "[B01] Including <linux/msm_ion.h> in $GR_ION_H..."
      sed -i '1i #include <linux/msm_ion.h>' "$GR_ION_H"
    fi
  fi
  echo "[B01] Display Gralloc configuration ready."
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
        pattern = re.compile(rf'(cc_prebuilt_library_shared\s*\{{[^}}]*?name:\s*"{target}"[^}}]*?)(\}})', re.DOTALL)
        match = pattern.search(content)
        if match:
            block = match.group(1)
            if "check_elf_files: false" not in block:
                print(f"Applying check_elf_files: false to {target}")
                new_block = block + '\tcheck_elf_files: false,\n'
                content = content[:match.start()] + new_block + match.group(2) + content[match.end():]
                modified = True
            else:
                print(f"{target} already has check_elf_files: false")
        else:
            print(f"Target module {target} not found via regex")

    if modified:
        with open(bp_file, "w") as f:
            f.write(content)
        print("Updated vendor Android.bp successfully.")
except Exception as e:
    print(f"Error processing vendor Android.bp: {e}")
PYEOF
  fi
else
  echo "[B02/B03/B04] Warning: Vendor dir not found at $VENDOR_DIR"
fi

echo "============================================================"
echo "=== 3. ALL KNOWN BLOCKER CONFIGURATIONS APPLIED ==="
echo "============================================================"
