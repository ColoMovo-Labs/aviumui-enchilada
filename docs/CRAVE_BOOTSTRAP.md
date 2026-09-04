# Crave.io Build #1 Bootstrap Guide

This guide describes how to reproduce and resume Build #1 on **Crave.io Team Aosp** infrastructure without reliance on Depot-private storage or caches.

---

## 1. Prerequisites
- Crave CLI installed and authenticated (`crave -h`)
- DevSpace or Project configured with minimum 32GB RAM / 8+ vCPUs

---

## 2. Source Initialization

```bash
# 1. Initialize AviumUI 16.2 base repository
repo init -u https://github.com/AviumUI/manifest.git -b avium-16.2 --git-lfs

# 2. Add ColoMovo-Labs local manifest for Enchilada
mkdir -p .repo/local_manifests
curl -sL https://raw.githubusercontent.com/ColoMovo-Labs/aviumui-enchilada-manifests/main/enchilada.xml -o .repo/local_manifests/enchilada.xml

# 3. Synchronize repositories
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

---

## 3. Verify Pinned Forks, Branches & Commit SHAs

Before building, verify that the synchronized repos match the Build #1 verified SHAs:

| Repository Path | Remote URL | Branch | Verified Commit SHA | Description |
|---|---|---|---|---|
| `device/oneplus/sdm845-common` | `https://github.com/ColoMovo-Labs/android_device_oneplus_sdm845-common` | `avium-16.2-build1` | `f94d5eeb1b411dfbb4ecfafea5d04ea31e5e0a35` | Contains all 5 Build #1 sepolicy & display HAL fixes |
| `vendor/oneplus/sdm845-common` | `https://github.com/ColoMovo-Labs/proprietary_vendor_oneplus_sdm845-common` | `avium-16.2` | `256177534d7f8fd531336814984fabbfca8a9442` | Source perf client & namespace visibility fixes |
| `kernel/oneplus/sdm845` | `https://github.com/AviumUI-Devices/kernel_oneplus_sdm845` | `avium-16.2` | `2830f53eb774a38f4a1faee9f0970ad70f803c68` | Standalone kernel compile PASS |
| `device/oneplus/enchilada` | `https://github.com/LineageOS/android_device_oneplus_enchilada` | `lineage-23.2` | `f3e5db70e9a8f420e10b14467554904a44b9423b` | OnePlus 6 device configuration |
| `hardware/oneplus` | `https://github.com/LineageOS/android_hardware_oneplus` | `lineage-23.2` | `9b36ea7b4202302faaa6d724945d7d74e21a48c5` | OnePlus hardware HALs |
| `hardware/dolby` | `https://github.com/AviumUI-Devices/hardware_dolby` | `avium-16.2` | `d72e73708d7e97424ad4f61f744e23114ae39f28` | Dolby audio framework support |

---

## 4. Staged Build Execution

```bash
# 1. Set up build environment
source build/envsetup.sh
lunch lineage_enchilada-bp4a-userdebug

# 2. Stage A: Validate Soong graph and Ninja dependencies
m nothing

# 3. Stage B: Resume full target build
m bacon
```

---

## 5. Current Pending Blocker Notice
Build #1 is frozen at:
- **File**: `device/oneplus/sdm845-common/sepolicy/vendor/hal_camera_default.te:15`
- **Blocker**: `unknown type vendor_xdsp_device`
- **Status**: `PENDING / NOT YET APPLIED`
- **Recommended Action**: Modify `vendor_xdsp_device` -> `xdsp_device` before or upon encountering this checkpolicy error.
