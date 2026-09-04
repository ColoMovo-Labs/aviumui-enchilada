# AviumUI 16.2.1 Enchilada Build #1 State & Bring-Up Ledger

- **Last Updated**: 2026-09-04
- **Target Device**: OnePlus 6 (`enchilada`)
- **Common Device Tree**: `device/oneplus/sdm845-common`
- **SoC**: Qualcomm Snapdragon 845 (SDM845)
- **Base Platform**: Android 16 QPR2 / BP4A (`BP4A.251205.006`)
- **ROM Variant**: AviumUI 16.2.1 (Unofficial, Vanilla, `WITH_GMS=false`)
- **Lunch Target**: `lineage_enchilada-bp4a-userdebug`

---

## 1. Verified Working Stages (Milestones)

1. **Source Synchronization**:
   - Status: `PASS`
   - Full 120GB AOSP BP4A + LineageOS tree synchronized via repo manifest.
2. **Standalone Kernel Compilation**:
   - Status: `PASS`
   - Toolchain: Clang 20.0.0 (`prebuilts/clang/host/linux-x86/clang-r547379`), `LLVM=1 LLVM_IAS=1`
   - Target: `vendor/enchilada_defconfig`, Kernel: Linux 4.19.325
   - Verified Output: `Image.gz-dtb` (SHA256: `11a9861ed6a659132e21434cfa5d04490b8b22948da8dc17e0494e3ae1631c13`)
3. **Soong Build Graph & Ninja Rules**:
   - Status: `PASS`
   - Full dependency graph generated cleanly without OOM (284 Soong rules, 326 Make rules, 455 checkpolicy inputs).
4. **Initial Ninja Build Execution**:
   - Status: `PASS`
   - Reached ~149,500+ build rules, advanced past all core system modules and entered device recovery SEPolicy compilation.

---

## 2. Resolved Build Blockers in Build #1

| # | Blocker | Symptom / Error | Resolution / Fix | Commit / Reference |
|---|---|---|---|---|
| 1 | Missing `hardware/dolby` | Build stopped due to missing dependency `hardware/dolby` | Added `AviumUI-Devices/hardware_dolby@avium-16.2` to local manifest (`enchilada.xml`) | `enchilada.xml` |
| 2 | Duplicate `libqti-perfd-client` | Soong duplicate module error between prebuilt and source | Forked vendor repository to `ColoMovo-Labs/proprietary_vendor_oneplus_sdm845-common@avium-16.2` and removed duplicate prebuilt | `8bfac869e42d237585bd802ec60e4f3cd11480d3` |
| 3 | Namespace Visibility | Dependent modules could not find `libqti-perfd-client` across namespaces | Added `"hardware/qcom-caf/common/libqti-perfd-client"` into `soong_namespace.imports` in vendor `Android.bp` | `256177534d7f8fd531336814984fabbfca8a9442` |
| 4 | SEPolicy `dashd.te` supply types | `checkpolicy: unknown type vendor_sysfs_battery_supply` | Replaced `vendor_sysfs_battery_supply` and `vendor_sysfs_usb_supply` with native legacy-um `sysfs_battery_supply` and `sysfs_usb_supply` | `9dad3ae3c06497144e9845182e23dda80ece7937` |
| 5 | SEPolicy Camera Perf types | `checkpolicy: unknown type vendor_hal_perf_default` | Replaced `vendor_hal_perf_default` and `vendor_hal_perf_hwservice` with native `hal_perf_default` and `hal_perf_hwservice` in `hal_cameraHIDL_default.te` | `976f86714a5212067a19a89792d4c8f5608b7c4c` |
| 6 | Legacy QCOM SEPolicy alignment | `unknown type vendor_hal_perf_default` in other HALs | Aligned `hal_fingerprint_device.te`, `hal_ifaa_default.te` and `file_contexts` to native un-prefixed legacy-um types | `77184f1578e577b4ea7803c218b791ea7e0fec02` |

---

## 3. Current Blocker

* **Target File**: `device/oneplus/sdm845-common/sepolicy/vendor/hal_camera_default.te:12`
* **Error**:
  ```text
  device/oneplus/sdm845-common/sepolicy/vendor/hal_camera_default.te:12:ERROR 'unknown type vendor_persist_file' at token ';' on line 149565:
  allow hal_camera_default vendor_persist_file:dir { open search write add_name remove_name lock };
  checkpolicy: error(s) encountered while parsing configuration
  ```
* **Root Cause**:
  In Qualcomm SDM845 legacy-um (`device/qcom/sepolicy_vndr/legacy-um/legacy/vendor/common/file.te`), the persist directory type is `persist_file`, not `vendor_persist_file`.
  LineageOS 22.2 upstream uses `allow hal_camera_default mnt_vendor_file:dir search;` and does not reference `vendor_persist_file`.

---

## 4. Authoritative Pinned Repositories & Forks

* **Manifests**: `https://github.com/ColoMovo-Labs/aviumui-enchilada-manifests` (branch: `main`, SHA: `5e7e5120d165a7983ae71adc2733eed3933f900a`)
* **Device Tree (`sdm845-common`)**: `https://github.com/ColoMovo-Labs/android_device_oneplus_sdm845-common` (branch: `avium-16.2-build1`)
* **Device Tree (`enchilada`)**: `https://github.com/LineageOS/android_device_oneplus_enchilada` (branch: `lineage-23.2`)
* **Kernel Tree**: `https://github.com/LineageOS/android_kernel_oneplus_sdm845` (branch: `lineage-23.2`)
* **Vendor Tree**: `https://github.com/ColoMovo-Labs/proprietary_vendor_oneplus_sdm845-common` (branch: `avium-16.2`, SHA: `256177534d7f8fd531336814984fabbfca8a9442`)
* **Hardware Dolby**: `https://github.com/AviumUI-Devices/hardware_dolby` (branch: `avium-16.2`)
* **Main Repo / CI**: `https://github.com/ColoMovo-Labs/aviumui-enchilada` (branch: `main`)
