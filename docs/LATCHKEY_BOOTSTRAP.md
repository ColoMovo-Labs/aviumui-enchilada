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
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags

# 3. Build target
source build/envsetup.sh
lunch lineage_enchilada-bp4a-userdebug
m bacon
```
