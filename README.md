# AviumUI 16.2 Bring-up for OnePlus 6 (enchilada)

[![Status: Experimental](https://img.shields.io/badge/Status-Experimental%20%2F%20Unofficial-orange.svg)](#status)
[![Android Version](https://img.shields.io/badge/Android-16%20QPR2-blue.svg)](#android-version)
[![Target Device](https://img.shields.io/badge/Device-OnePlus%206%20(enchilada)-red.svg)](#target-device)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

An unofficial, experimental bring-up project of **AviumUI 16.2.x** (based on **Android 16 QPR2**) for the **OnePlus 6 (`enchilada`)** smartphone (Qualcomm Snapdragon 845).

---

## 🎯 Project Overview & Scope

* **Target OS**: AviumUI 16.2.x (Android 16 QPR2)
* **Target Device**: OnePlus 6 (`enchilada`) / SDM845 Common Platform
* **Release Nature**: Unofficial & Experimental
* **Phase 1 Build Target**: **Vanilla Build** (clean AOSP/AviumUI stack without Google Mobile Services / MicroG pre-installed, ensuring reproducible debugging).
* **Baseline Device Stack**: Planned on **LineageOS 23.2** (`lineage-23.2` device, common, kernel, and hardware trees).
* **Repository Role**: This repository hosts only local manifests, bring-up documentation, patches, and build orchestration scripts. **Full Android source trees and proprietary binary blobs are strictly NOT stored in this repository**.

---

## 🚦 Current Status

> **Current Phase**: `Namespace Cloud Runner Bring-up & Verification`

* [x] Project architecture and bring-up roadmap defined ([docs/PLAN.md](docs/PLAN.md)).
* [x] Upstream source provenance and branch mapping verified ([docs/SOURCES.md](docs/SOURCES.md)).
* [x] Validated physical A/B local manifest created ([local_manifests/enchilada.xml](local_manifests/enchilada.xml)).
* [x] Namespace 32 vCPU / 62 GiB Runner connected and verified (`namespace-profile-avium-run15`).
* [x] Baseline Linux 4.19 bring-up booted and verified on hardware (tagged `avium-16.2.1-enchilada-4.19-working`).
* [x] Official AviumUI GMS stack integrated.
* [x] Essential customizations implemented (Unlimited Photos, advanced reboot, volume skip, QS controls).

---

## 👤 Maintainer

* **Maintainer**: LoMo 洛陌

---

## ⚠️ Known Issues

- Fingerprint enrollment is currently limited to a maximum of two fingerprints.
  Fingerprint authentication itself works normally and is stable.
  This does not affect normal daily use, so the issue is currently considered low priority.
  Contributions or patches addressing the enrollment limit are welcome.

## 已知问题

- 当前最多只能录入 2 个指纹。
- 指纹识别与解锁功能本身工作正常，稳定性无明显问题。
- 该限制暂不影响日常使用，因此目前列为低优先级问题。
- 欢迎有兴趣的开发者提交修复方案或 Patch。

---

## 🛠️ Development & Build Workflow

Due to workstation resource constraints (local node operates with ~8GB RAM and ~256GB storage), the development workflow utilizes dedicated cloud runners:

```text
+-------------------------------------------------------------+
|                     Local Machine (Fedora)                  |
|  * Manifest orchestration   * Patch authoring               |
|  * Upstream tracking        * Fastboot/ADB flashing & test  |
+------------------------------+------------------------------+
                               |
                               | git push origin main
                               v
+-------------------------------------------------------------+
|           Namespace GitHub Actions Runner (Primary)         |
|  * Label: namespace-profile-avium-run15                     |
|  * 32 vCPU AMD EPYC Zen 4, 62 GiB RAM                       |
|  * 284 GiB NVMe root filesystem + 121 GiB persistent /cache |
|  * Pipeline: repo sync -> static audit -> m nothing         |
|              -> m bootimage -> m bacon                      |
+-------------------------------------------------------------+
```

---

## 📂 Repository Layout

```text
aviumui-enchilada/
├── .gitignore              # Ignores build artifacts, caches, and raw images
├── LICENSE                 # Apache License 2.0
├── README.md               # Project overview and current status
├── docs/
│   ├── PLAN.md             # 7-stage bring-up roadmap and comprehensive test matrix
│   └── SOURCES.md          # Upstream source tracking and branch mapping
├── local_manifests/
│   └── enchilada.xml       # Draft repo local manifest for Crave / local sync
├── patches/
│   └── README.md           # Upstream-first patch guidelines and conventions
└── scripts/
    └── README.md           # Future Crave build helper and tooling scripts
```

---

## ⚖️ License & Disclaimers

* **Source License**: Project orchestration files and custom bring-up scripts in this repository are licensed under the [Apache License 2.0](LICENSE).
* **Disclaimers**: OnePlus and the OnePlus 6 logo are trademarks of OnePlus Technology (Shenzhen) Co., Ltd. Android is a trademark of Google LLC. This project is not affiliated with, endorsed by, or associated with OnePlus or Google.
