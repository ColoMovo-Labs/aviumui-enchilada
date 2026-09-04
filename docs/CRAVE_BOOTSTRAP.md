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

## 3. Verify Pinned Forks & Branches

Ensure the local manifests pulled the verified ColoMovo-Labs branches:
- `vendor/oneplus/sdm845-common` -> `ColoMovo-Labs/proprietary_vendor_oneplus_sdm845-common` (`avium-16.2`)
- `device/oneplus/sdm845-common` -> `ColoMovo-Labs/android_device_oneplus_sdm845-common` (`avium-16.2-build1`)
- `hardware/dolby` -> `AviumUI-Devices/hardware_dolby` (`avium-16.2`)

---

## 4. Build Commands

```bash
# Set up environment
source build/envsetup.sh
lunch lineage_enchilada-bp4a-userdebug

# Execute build
m bacon
```
