# Bring-up Patch Management

This directory hosts localized patches and cherry-picks required for bringing up AviumUI 16.2 on OnePlus 6 (`enchilada`).

---

## 🎯 Core Principles

1. **Upstream-First**:
   * Always seek upstream resolutions first. If a bug or build error originates in LineageOS or AviumUI core repositories, submit fixes to upstream gerrit / pull requests rather than accumulating permanent local debt.
2. **Minimal Patches**:
   * Keep all patch sets isolated, strictly scoped, and minimal. Do not bundle unrelated changes or cosmetic refactors into bring-up patches.
3. **Do Not Fork Unnecessarily**:
   * Avoid creating and maintaining long-lived forks of upstream repositories. Use local git patch injection or dynamic build-script hooks whenever possible.

---

## 📁 Directory Structure Convention

When patches become necessary during the bring-up phase, organize them by their corresponding AOSP/Lineage repository paths:

```text
patches/
├── README.md
├── build_make/
│   └── 0001-Revert-obsolete-flag.patch
├── device_oneplus_sdm845-common/
│   └── 0001-Fix-audio-hal-compilation-on-16.2.patch
├── frameworks_base/
│   └── 0001-AviumUI-blur-fallback-for-adreno-630.patch
└── hardware_oneplus/
    └── 0001-Update-touch-hal-aidl-compat.patch
```

---

## 📝 Patch Header Guidelines

Every patch file must contain a clear commit message including:
* **Target Repository**: e.g., `device/oneplus/sdm845-common`
* **Reason / Root Cause**: Why the patch is needed for Android 16 QPR2 / AviumUI 16.2.
* **Upstream Link / Gerrit Change-Id**: Reference to related upstream discussions or commits where applicable.
