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

| # | Blocker / Fix Area | Error / Symptom | Resolution / Fix | Commit / Reference |
|---|---|---|---|---|
| 1 | Missing `hardware/dolby` | Build stopped due to missing dependency `hardware/dolby` | Added `AviumUI-Devices/hardware_dolby@avium-16.2` to local manifest (`enchilada.xml`) | `enchilada.xml` |
| 2 | Duplicate `libqti-perfd-client` | Soong duplicate module error between prebuilt and source | Forked vendor repository to `ColoMovo-Labs/proprietary_vendor_oneplus_sdm845-common@avium-16.2` and removed duplicate prebuilt | `8bfac869e42d237585bd802ec60e4f3cd11480d3` |
| 3 | Namespace Visibility | Dependent modules could not find `libqti-perfd-client` across namespaces | Added `"hardware/qcom-caf/common/libqti-perfd-client"` into `soong_namespace.imports` in vendor `Android.bp` | `256177534d7f8fd531336814984fabbfca8a9442` |
| 4 | SEPolicy `dashd.te` supply types | `checkpolicy: unknown type vendor_sysfs_battery_supply` | Replaced `vendor_sysfs_battery_supply` and `vendor_sysfs_usb_supply` with native legacy-um `sysfs_battery_supply` and `sysfs_usb_supply` | `a96c755` (git) / `9dad3ae` (depot) |
| 5 | SEPolicy Camera Perf types | `checkpolicy: unknown type vendor_hal_perf_default` | Replaced `vendor_hal_perf_default` and `vendor_hal_perf_hwservice` with native `hal_perf_default` and `hal_perf_hwservice` in `hal_cameraHIDL_default.te` | `8330b63` (git) / `976f867` (depot) |
| 6 | Legacy QCOM SEPolicy alignment | `unknown type vendor_hal_perf_default` in other HALs | Aligned `hal_fingerprint_device.te`, `hal_ifaa_default.te` and `file_contexts` to native un-prefixed legacy-um types | `9e6cf2e` (git) / `77184f1` (depot) |
| 7 | SEPolicy Camera Persist type | `checkpolicy: unknown type vendor_persist_file` in `hal_camera_default.te:12` | Replaced `vendor_persist_file` with native legacy-um `persist_file` in `hal_camera_default.te` | `e484f3c` (git) / `b5bba75` (depot) |
| 8 | Display HAL Package Selection | Mismatch between AIDL mapper/composer and SDM845 HIDL HAL | Corrected `common.mk` display packages to `mapper@2.0`, `gralloc.sdm845`, `hwcomposer.qcom`, `allocator@1.0-service` | `f94d5ee` (`sdm845-common`) |

---

## 3. Current Blocker & Pending Audit Items

### Current First Blocker
* **Target File**: `device/oneplus/sdm845-common/sepolicy/vendor/hal_camera_default.te:15`
* **Error**:
  ```text
  device/oneplus/sdm845-common/sepolicy/vendor/hal_camera_default.te:15:ERROR 'unknown type vendor_xdsp_device' at token ';' on line 149568:
  allow hal_camera_default vendor_xdsp_device:chr_file { getattr open read ioctl lock map watch watch_reads };
  checkpolicy: error(s) encountered while parsing configuration
  ```
* **Status**: `PENDING / NOT YET APPLIED` (Frozen for migration)
* **Proposed Resolution**:
  Change `vendor_xdsp_device` to `xdsp_device` in `hal_camera_default.te:15` (matching LineageOS 22.2 upstream).

### Pending Static Audit Items (To be addressed post-migration)
1. `hal_fingerprint_device.te`: lines 23-26 (`vendor_qdsp_device` -> `qdsp_device`, `vendor_xdsp_device` -> `xdsp_device`, `vendor_adsprpc_prop` -> `adsprpc_prop`)
2. `rild.te`: line 13 (`vendor_diag_device` -> `diag_device`)
3. `thermal-engine.te`: lines 1, 3 (`vendor_thermal-engine` -> `thermal-engine`, `vendor_sysfs_devfreq` -> `sysfs_devfreq`)
4. `file_contexts`: lines 10-12, 19 (`vendor_rawdump_block_device`, `vendor_modem_efs_partition_device`, `vendor_efs_boot_dev`)

---

## 4. Authoritative Pinned Repositories & Forks

* **Manifests**: `https://github.com/ColoMovo-Labs/aviumui-enchilada-manifests` (branch: `main` / `build1`, SHA: `885178b3dfbb7241f70e8fe07c6916e64c20e1f3`)
* **Device Tree (`sdm845-common`)**: `https://github.com/ColoMovo-Labs/android_device_oneplus_sdm845-common` (branch: `avium-16.2-build1`, HEAD: `f94d5eeb1b411dfbb4ecfafea5d04ea31e5e0a35`)
* **Device Tree (`enchilada`)**: `https://github.com/LineageOS/android_device_oneplus_enchilada` (branch: `lineage-23.2`)
* **Kernel Tree**: `https://github.com/LineageOS/android_kernel_oneplus_sdm845` (branch: `lineage-23.2`)
* **Vendor Tree**: `https://github.com/ColoMovo-Labs/proprietary_vendor_oneplus_sdm845-common` (branch: `avium-16.2`, HEAD: `256177534d7f8fd531336814984fabbfca8a9442`)
* **Hardware Dolby**: `https://github.com/AviumUI-Devices/hardware_dolby` (branch: `avium-16.2`)
* **Main Repo / CI**: `https://github.com/ColoMovo-Labs/aviumui-enchilada` (branch: `main`)

---

## 5. Migration Freeze & Evacuation Deliverables

* **Divergence Resolution**: `100% IDENTICAL TREE` between GitHub and Depot (`f94d5eeb1b411dfbb4ecfafea5d04ea31e5e0a35`)
* **Portable State Archive**: `/mnt/avium-cache/evacuation/avium-build1-portable-state-20260904T140757Z.tar.zst`
  - Size: 110 KiB
  - SHA256: `c2ace37c3058658e9b08e71f6a35f25a42a3e1dbd03c355927808e1c451ae251`
* **Pinned Full Manifest**: `/mnt/avium-cache/evacuation/build1/manifest/build1-pinned-manifest.xml`
  - SHA256: `63d0026a3ea7557155fb1fc74c87c644cf2a23af6d0814021f18ec68e3cafff3`
* **OUT Checkpoint Status**: `NONE` (no artificial checkpoint created)
* **Log Index**: `log-index/index.tsv` (complete SHA256 and PASS/FAIL index of all attempts)
* **Migration Freeze Workflow**: Depot CI Run `16f3lzmjn7` (Status: `FINISHED`)
