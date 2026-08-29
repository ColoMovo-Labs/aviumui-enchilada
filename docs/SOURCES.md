# Upstream Sources & Provenance Matrix

This document tracks all upstream repositories, branches, roles, and rationale adopted for the **Candidate A** bring-up tree of AviumUI 16.2.x (Android 16 QPR2) on the OnePlus 6 (`enchilada`).

---

## 📦 Candidate A Source Repository Mapping

Following comprehensive dependency closure and static compatibility analysis, **Candidate A** is selected as the baseline architecture for the first bring-up build (#1):

| Subsystem | Target Repository | Target Revision | Role & Selection Rationale |
| :--- | :--- | :--- | :--- |
| **ROM Base Manifest** | [`AviumUI/android_manifests`](https://github.com/AviumUI/android_manifests) | `avium-16.2` | Core Android 16 QPR2 AOSP & AviumUI framework manifests |
| **Device Tree (OnePlus 6)** | [`LineageOS/android_device_oneplus_enchilada`](https://github.com/LineageOS/android_device_oneplus_enchilada) | `lineage-23.2` | Clean LineageOS 23.2 device baseline without legacy 16.0 GMS / Official / fake-prop overrides |
| **Common Device Tree** | [`AviumUI-Devices/device_oneplus_sdm845-common`](https://github.com/AviumUI-Devices/device_oneplus_sdm845-common) | `avium-16.2` | Dedicated AviumUI 16.2 common layer with 4.19 kernel & Retrofit Super dynamic partitions (`odm product system system_ext vendor`) |
| **Kernel Source** | [`AviumUI-Devices/kernel_oneplus_sdm845`](https://github.com/AviumUI-Devices/kernel_oneplus_sdm845) | `avium-16.2` | Linux 4.19.325 LTS kernel paired with `vendor/enchilada_defconfig` |
| **Hardware HALs** | [`LineageOS/android_hardware_oneplus`](https://github.com/LineageOS/android_hardware_oneplus) | `lineage-23.2` | OnePlus hardware HAL interfaces (Tri-State key, Touch, Biometrics) |
| **Vendor Blobs (Device)** | [`TheMuppets/proprietary_vendor_oneplus_enchilada`](https://github.com/TheMuppets/proprietary_vendor_oneplus_enchilada) | `lineage-22.2` | Device-specific camera and radio binary blobs (100% identical proprietary-files footprint) |
| **Vendor Blobs (Common)** | [`TheMuppets/proprietary_vendor_oneplus_sdm845-common`](https://github.com/TheMuppets/proprietary_vendor_oneplus_sdm845-common) | `lineage-22.2` | Shared SDM845 proprietary Qualcomm HAL binaries and firmware (89.9% common entry overlap) |

---

## 🎯 Architecture Decision & Candidate A Rationale

1. **Why not Avium `device_oneplus_enchilada@avium-16` (Candidate B)?**:
   * Comparative analysis demonstrated that `device_oneplus_enchilada@avium-16` and `LineageOS/android_device_oneplus_enchilada@lineage-23.2` are 100% identical across 26 out of 28 files.
   * The sole difference is `avium-16` appending `include avium_enchilada.mk`, which hardcodes `WITH_GMS := true`, `AVIUM_IS_OFFICIAL := true`, and legacy fake-prop overrides.
   * To achieve a clean, reproducible **Vanilla (no GMS) + Unofficial + Minimal Modifications** first build, adopting LineageOS 23.2 device tree avoids upstream build-system interference while preserving identical hardware definitions.

2. **Why not full LineageOS 23.2?**:
   * Upstream investigation revealed that LineageOS officially supports `enchilada` on `lineage-22.2`. While `lineage-23.2` device and common branches exist, `android_kernel_oneplus_sdm845` and TheMuppets vendor repositories do not have `lineage-23.2` branches published yet.
   * Attempting full 23.2 would result in missing kernel and vendor remote refs.

3. **Why Avium 16.2 Common & 4.19 Kernel?**:
   * `AviumUI-Devices/device_oneplus_sdm845-common@avium-16.2` has already been fully refactored for Android 16.2:
     * Wired to `TARGET_KERNEL_VERSION := 4.19` (Linux 4.19.325 LTS).
     * Configured for EROFS + Retrofit dynamic partitions (`BOARD_SUPER_PARTITION_BLOCK_DEVICES := odm system vendor`).
     * AIDL HAL and modern SEPolicy transitions are in place.

---

## 📌 Reproducibility Record (Validated HEAD Hashes)

* `LineageOS/android_device_oneplus_enchilada` @ `lineage-23.2`: `11af130c3356ae736b16fd788a1070d9a1e3fad9`
* `AviumUI-Devices/device_oneplus_sdm845-common` @ `avium-16.2`: `7603ce417d389af060a64088bd972d142056c42c`
* `AviumUI-Devices/kernel_oneplus_sdm845` @ `avium-16.2`: `53b798328231b5e75ff1df2b6b031a8618ac8084`
* `LineageOS/android_hardware_oneplus` @ `lineage-23.2`: `c70600ebefcdb7db75ab2505abaad0ea71faca2b`
* `TheMuppets/proprietary_vendor_oneplus_enchilada` @ `lineage-22.2`: `2dedc8d1099e0b4d3e507c0049ee9bdcf12d77f0`
* `TheMuppets/proprietary_vendor_oneplus_sdm845-common` @ `lineage-22.2`: `3d6b72f093ccfb99e8bfc17af204441b6e6322aa`
