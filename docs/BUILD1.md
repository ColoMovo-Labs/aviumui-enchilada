# Build #1 Specification: Candidate A Vanilla Bring-up

This document defines the exact baseline, scope, versioning, and provenance snapshot for the **first compilation and boot bring-up attempt (Build #1)** of AviumUI on the OnePlus 6 (`enchilada`).

---

## 🎯 Build #1 Baseline Parameters

* **Build Flavor**: **Vanilla** (strictly clean AOSP/AviumUI stack without Google Mobile Services / MicroG)
* **Release Type**: **Unofficial** (`AVIUM_IS_OFFICIAL := false`)
* **GMS Integration**: **None** (`WITH_GMS := false`)
* **Cleanliness Policy**: **No clean** (incremental build / ccache reuse enabled on remote builder)
* **Device Customization Policy**: **No device-specific Avium overrides** (clean LineageOS 23.2 device tree without legacy `avium_enchilada.mk` variables)
* **Target Android Version**: **Android 16 QPR2** (AviumUI branch: `avium-16.2`)
* **Build Target (Lunch)**: `lineage_enchilada-bp4a-userdebug`
* **Primary Phase Objective**: **Compile First, Then Boot Validation** (achieve a zero-error ninja artifact generation, produce flashable images, and proceed to early kernel / ADB boot triage).

---

## 🔍 AviumUI Display Version Investigation

Investigation of [`AviumUI/android_vendor_avium`](https://github.com/AviumUI/android_vendor_avium) on branch `avium-16.2` ([config/version.mk](https://raw.githubusercontent.com/AviumUI/android_vendor_avium/avium-16.2/config/version.mk)) confirms the following versioning scheme:

```makefile
AVIUM_MAJOR_VERSION := 16
AVIUM_MINOR_VERSION := 2
AVIUM_PATCH_VERSION := 1

AVIUM_VER := AviumUI-$(AVIUM_MAJOR_VERSION).$(AVIUM_MINOR_VERSION).$(AVIUM_PATCH_VERSION)-$(LINEAGE_BUILD)
```

### System Properties & Naming Output:
* `ro.avium.build.version`: **`16.2.1`**
* `ro.avium.display.version`: `AviumUI-16.2.1-enchilada-YYYYMMDD`
* `ro.avium.is_official`: `false`
* `ro.avium.gms_status`: `false`
* **ROM Package Filename**: `AviumUI-16.2.1-enchilada-YYYYMMDD-Unofficial-Vanilla.zip`
* **Lineage Compatibility Version**: `AviumUI-Unofficial-enchilada-YYYYMMDD`

**Conclusion**: Build #1 outputs will systematically identify as **AviumUI 16.2.1 (Vanilla Unofficial)**.

---

## 📌 Known-Good Investigation Snapshot (Auditable HEAD Hashes)

While the project manifest (`enchilada.xml`) tracks branch heads (`lineage-23.2`, `avium-16.2`, `lineage-22.2`) to integrate active upstream bug fixes, the exact validated commit hashes during dependency closure verification are recorded below:

| Subsystem Path | Tracked Upstream Repository | Target Branch | Validated Snapshot HEAD SHA |
| :--- | :--- | :--- | :--- |
| `device/oneplus/enchilada` | [`LineageOS/android_device_oneplus_enchilada`](https://github.com/LineageOS/android_device_oneplus_enchilada) | `lineage-23.2` | `11af130c3356ae736b16fd788a1070d9a1e3fad9` |
| `device/oneplus/sdm845-common` | [`AviumUI-Devices/device_oneplus_sdm845-common`](https://github.com/AviumUI-Devices/device_oneplus_sdm845-common) | `avium-16.2` | `7603ce417d389af060a64088bd972d142056c42c` |
| `kernel/oneplus/sdm845` | [`AviumUI-Devices/kernel_oneplus_sdm845`](https://github.com/AviumUI-Devices/kernel_oneplus_sdm845) | `avium-16.2` | `53b798328231b5e75ff1df2b6b031a8618ac8084` |
| `hardware/oneplus` | [`LineageOS/android_hardware_oneplus`](https://github.com/LineageOS/android_hardware_oneplus) | `lineage-23.2` | `c70600ebefcdb7db75ab2505abaad0ea71faca2b` |
| `vendor/oneplus/enchilada` | [`TheMuppets/proprietary_vendor_oneplus_enchilada`](https://github.com/TheMuppets/proprietary_vendor_oneplus_enchilada) | `lineage-22.2` | `2dedc8d1099e0b4d3e507c0049ee9bdcf12d77f0` |
| `vendor/oneplus/sdm845-common` | [`TheMuppets/proprietary_vendor_oneplus_sdm845-common`](https://github.com/TheMuppets/proprietary_vendor_oneplus_sdm845-common) | `lineage-22.2` | `3d6b72f093ccfb99e8bfc17af204441b6e6322aa` |

---

## 📦 Expected Build Output Artifacts

Upon successful ninja target completion (`m bacon`), the following core artifacts must be produced under `out/target/product/enchilada/`:
1. `boot.img` (Kernel 4.19.325 `Image.gz-dtb` + ramdisk)
2. `dtbo.img` (SDM845 device tree overlay compiled via `mkdtboimg`)
3. `super_empty.img` (Retrofit dynamic partitions descriptor)
4. `system.img`, `system_ext.img`, `product.img`, `vendor.img`, `odm.img` (EROFS payload partitions)
5. `AviumUI-16.2.1-enchilada-*-Unofficial-Vanilla.zip` (Signed flashable package)

---

## 🛠️ Host Environment & Build Dependencies

The following Ubuntu package dependencies are required on the build host (note: `cpio` is required for Linux kernel header compression):

```bash
sudo apt-get update && sudo apt-get install -y \
  bc bison build-essential ccache cpio curl flex g++-multilib gcc-multilib \
  git gnupg gperf imagemagick lib32readline-dev lib32z1-dev libelf-dev \
  liblz4-tool libncurses5-dev libncurses6 libsdl1.2-dev libssl-dev libxml2 \
  libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip \
  zlib1g-dev python3 time
```

---

## ✅ Verified Subsystem Bring-up: Standalone Kernel Build #1

The OnePlus 6 Linux 4.19 kernel (`kernel/oneplus/sdm845 @ avium-16.2`) has been successfully built and verified standalone using the Android 16 prebuilt LLVM/Clang toolchain:

* **Kernel Git Commit**: `53b798328231b5e75ff1df2b6b031a8618ac8084`
* **Defconfig**: `vendor/enchilada_defconfig` (arch/arm64/configs/vendor/enchilada_defconfig)
* **Compiler**: Android 16 prebuilt Clang 20.0.0 (`prebuilts/clang/host/linux-x86/clang-r547379/bin/clang`)
* **Cross-compilers**: GCC 4.9 `aarch64-linux-android-` & `arm-linux-androideabi-` + `LLVM=1 LLVM_IAS=1`
* **Build Duration**: 166s (~2m46s on 8 vCPU)
* **Peak Resident RSS**: ~2.18 GiB (0 OOM events, 100% stable)
* **Target Output**: `Image.gz-dtb` (20 MB, SHA-256: `11a9861ed6a659132e21434cfa5d04490b8b22948da8dc17e0494e3ae1631c13`)
* **Device Tree Overlays**: `enchilada-*-overlay.dtbo` generated successfully.
* **Persistent Artifacts**: Stored at `/workspaces/android/artifacts/kernel-build1/`
