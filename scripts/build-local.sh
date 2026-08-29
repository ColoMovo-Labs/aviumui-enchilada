#!/usr/bin/env bash
# ==============================================================================
# Provider-Neutral Reference Build Script for AviumUI 16.2.x on OnePlus 6
# ==============================================================================
# NOTE: This script is intended for standalone build environments (e.g. dedicated
# high-performance servers, build VMs, or cloud runners with >=32GB RAM & 300GB SSD).
# DO NOT execute on resource-constrained local workstations without adequate swap/storage.
# ==============================================================================

set -euo pipefail

# 1. Environment & Parameters
export WORKSPACE_DIR="${WORKSPACE_DIR:-$(pwd)/avium_build}"
export THREADS="${THREADS:-$(nproc --all)}"
export TZ="${TZ:-Asia/Shanghai}"
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR="${CCACHE_DIR:-${HOME}/.ccache}"

echo ">>> [1/5] Initializing Build Workspace at: ${WORKSPACE_DIR}"
mkdir -p "${WORKSPACE_DIR}"
cd "${WORKSPACE_DIR}"

# 2. Manifest Initialization & Local Manifest Injection
echo ">>> [2/5] Initializing AviumUI 16.2 Manifest Tree..."
repo init \
    --depth=1 \
    --no-repo-verify \
    -u https://github.com/AviumUI/android_manifests \
    -b avium-16.2 \
    -g default,-mips,-darwin,-notdefault \
    --git-lfs

echo ">>> Injecting Candidate A OnePlus 6 (enchilada) Local Manifests..."
mkdir -p .repo/local_manifests
if [ -d ".repo/local_manifests/.git" ]; then
    git -C .repo/local_manifests pull --ff-only
else
    git clone https://github.com/ColoMovo-Labs/aviumui-enchilada-manifests.git --depth=1 .repo/local_manifests
fi

# 3. Source Synchronization
echo ">>> [3/5] Synchronizing Source Trees (Threads: ${THREADS})..."
repo sync \
    -c \
    --no-clone-bundle \
    --no-tags \
    --optimized-fetch \
    --prune \
    --force-sync \
    -j"${THREADS}"

# 4. Build Environment Setup & Lunch Target
echo ">>> [4/5] Setting up Build Environment..."
source build/envsetup.sh

echo ">>> Selecting Target: lineage_enchilada-bp4a-userdebug..."
lunch lineage_enchilada-bp4a-userdebug

# 5. Compilation
echo ">>> [5/5] Launching Compilation (m bacon with ${THREADS} threads)..."
m -j"${THREADS}" bacon

echo "=============================================================================="
echo ">>> Build Succeeded! Artifacts generated in: out/target/product/enchilada/"
echo "=============================================================================="
