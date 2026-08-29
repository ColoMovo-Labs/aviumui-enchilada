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

> **Current Phase**: `Preparation / Crave Account Pending`

* [x] Project architecture and bring-up roadmap defined ([docs/PLAN.md](docs/PLAN.md)).
* [x] Upstream source provenance and branch mapping verified ([docs/SOURCES.md](docs/SOURCES.md)).
* [x] Initial draft local manifest created ([local_manifests/enchilada.xml](local_manifests/enchilada.xml)).
* [ ] Crave.io build pipeline authorization & environment setup.
* [ ] Upstream source alignment and manifest validation against AviumUI 16.2 base trees.
* [ ] Initial tree bring-up & first vanilla compilation.

---

## 🛠️ Development & Build Workflow

Due to workstation resource constraints (local node operates with ~8GB RAM and ~256GB storage), the development workflow is structured as follows:

```text
+-------------------------------------------------------------+
|                     Local Machine (Fedora)                  |
|  * Manifest orchestration   * Patch authoring               |
|  * Upstream tracking        * Fastboot/ADB flashing & test  |
+------------------------------+------------------------------+
                               |
                               | crave run / git push
                               v
+-------------------------------------------------------------+
|                     Remote Cloud (Crave.io)                 |
|  * Full AOSP/AviumUI sync   * High-concurrency ninja build  |
|  * ccache compilation cache * Artifact export (ROM zip/img) |
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
