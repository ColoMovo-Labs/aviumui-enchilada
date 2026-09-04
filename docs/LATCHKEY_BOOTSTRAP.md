# Latchkey OSS Build #1 Bootstrap Guide

This guide outlines steps for building AviumUI 16.2.1 on **Latchkey OSS** or standard Linux self-hosted runners.

---

## 1. Environment & Storage Requirements
- Linux (Ubuntu 22.04 / 24.04 or Debian 12)
- RAM: Minimum 32 GB RAM (or 16 GB RAM + 16 GB Swap) to support Soong AST dependency graph parsing.
- Disk: Minimum 250 GB available SSD storage.

---

## 2. Dependencies
```bash
sudo apt-get update && sudo apt-get install -y \
  bc bison build-essential ccache curl flex g++-multilib \
  gcc-multilib git git-lfs gnupg gperf imagemagick \
  lib32readline-dev lib32z1-dev libelf-dev liblz4-tool \
  libssl-dev libxml2 libxml2-utils lzop pngcrush \
  rsync schedtool squashfs-tools xsltproc zip zlib1g-dev \
  python3 python-is-python3 unzip wget zstd tar
```

---

## 3. Clone and Build Workflow
```bash
# 1. Setup repo tool
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH

# 2. Checkout source tree
mkdir -p ~/avium && cd ~/avium
repo init -u https://github.com/AviumUI/manifest.git -b avium-16.2 --git-lfs
mkdir -p .repo/local_manifests
curl -sL https://raw.githubusercontent.com/ColoMovo-Labs/aviumui-enchilada-manifests/main/enchilada.xml -o .repo/local_manifests/enchilada.xml
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

---

## 4. Verify Pinned Forks, Branches & Commit SHAs

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

## 5. Staged Build Execution

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

## 6. Current Pending Blocker Notice
Build #1 is frozen at:
- **File**: `device/oneplus/sdm845-common/sepolicy/vendor/hal_camera_default.te:15`
- **Blocker**: `unknown type vendor_xdsp_device`
- **Status**: `PENDING / NOT YET APPLIED`
- **Recommended Action**: Modify `vendor_xdsp_device` -> `xdsp_device` before or upon encountering this checkpolicy error.

