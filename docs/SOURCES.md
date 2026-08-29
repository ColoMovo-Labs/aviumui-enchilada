# Upstream Sources & Provenance Matrix

This document tracks all upstream repositories, branches, and roles required to assemble the AviumUI 16.2 (Android 16 QPR2) build tree for the OnePlus 6 (`enchilada`).

---

## 📦 Source Repository Mapping

| Subsystem | Upstream Repository | Target Branch / Tag | Purpose / Notes |
| :--- | :--- | :--- | :--- |
| **ROM Base Manifest** | [`AviumUI/android_manifests`](https://github.com/AviumUI/android_manifests) | `avium-16.2` | Core Android 16 QPR2 AOSP & AviumUI framework manifests |
| **Device Tree (OnePlus 6)** | [`LineageOS/android_device_oneplus_enchilada`](https://github.com/LineageOS/android_device_oneplus_enchilada) | `lineage-23.2` | Primary device-specific configuration, overlay, and init scripts |
| **Common Device Tree** | [`LineageOS/android_device_oneplus_sdm845-common`](https://github.com/LineageOS/android_device_oneplus_sdm845-common) | `lineage-23.2` | Shared Qualcomm SDM845 board configuration, audio/display HAL configs |
| **Kernel Source** | [`LineageOS/android_kernel_oneplus_sdm845`](https://github.com/LineageOS/android_kernel_oneplus_sdm845) | `lineage-23.2` | Linux 4.9 LTS downstream kernel tree patched for modern Android runtimes |
| **Hardware HALs** | [`LineageOS/android_hardware_oneplus`](https://github.com/LineageOS/android_hardware_oneplus) | `lineage-23.2` | OnePlus-specific hardware interfaces (Touch, Tri-State Slider, Biometrics) |
| **Vendor Blobs (Device)** | [`TheMuppets/proprietary_vendor_oneplus_enchilada`](https://github.com/TheMuppets/proprietary_vendor_oneplus_enchilada) | `lineage-23.2` | Proprietary camera, sensor, and radio firmware binary blobs for enchilada |
| **Vendor Blobs (Common)** | [`TheMuppets/proprietary_vendor_oneplus_sdm845-common`](https://github.com/TheMuppets/proprietary_vendor_oneplus_sdm845-common) | `lineage-23.2` | Shared SDM845 proprietary Qualcomm HAL binaries and firmware |

---

## 🔍 Reference Trees (Non-Baseline)

* **Legacy AviumUI OnePlus 6 (`avium-16`) Tree**:
  * **Role**: **Reference Only**.
  * **Policy**: The previous Android 16.0 / `avium-16` device tree serves exclusively as a reference for AviumUI-specific system properties, overlays, and custom UI configurations. It is **not** used directly as the 16.2 base tree to prevent carrying forward stale Android 16.0 QPR0/QPR1 technical debt. All baseline device bring-up is rooted on the fresh `lineage-23.2` stack.

---

## 🌐 Remote Definitions Reference

When constructing `local_manifests/enchilada.xml`, the following remote schemes are considered:

```xml
<!-- Default LineageOS / GitHub Remotes -->
<remote name="github-lineage"    fetch="https://github.com/LineageOS" />
<remote name="github-themuppets" fetch="https://github.com/TheMuppets" />
<remote name="github-generic"    fetch="https://github.com" />
```

> **Note**: Verify against `AviumUI/android_manifests/default.xml` before invoking `repo sync` on Crave to ensure no namespace collisions or duplicate remote errors occur.
