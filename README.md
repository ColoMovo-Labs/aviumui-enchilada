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
* [x] Official AviumUI GMS stack integrated (`WITH_GMS := true`).
* [x] Essential customizations implemented (Unlimited Photos, advanced reboot, volume skip, QS controls).
* [x] System window blurs forced by default (`TARGET_FORCE_ENABLE_BLUR := true`).
* [x] KernelSU Next built into Linux 4.19 kernel (`CONFIG_KSU=y`, `CONFIG_KPROBES=y`).
* [x] Non-functional LunarisDolby user app purged; ViPER4Android supported via KernelSU systemless module.
* [x] Curated Chinese font collection integrated (5 OFL styles, ThemePicker compatible).
* [x] Curated system wallpaper collection integrated (16 high-res 1440x3120 WebP wallpapers, WallpaperPicker partner app).

---

## 👤 Maintainer

* **Maintainer**: LoMo 洛陌

---

## ⚠️ Known Issues / 已知问题

### Known Issues
- Fingerprint enrollment is currently limited to a maximum of two fingerprints.
  Fingerprint authentication itself works normally and is stable.
  This does not affect normal daily use, so the issue is currently considered low priority.
  Contributions or patches addressing the enrollment limit are welcome.

### 已知问题
- 当前系统最多只能录入 / 添加 2 个指纹。
- 指纹录入、识别与解锁功能本身工作正常，稳定性无明显问题。
- 实测日常使用（如左右手各录入 1 个指纹）完全正常，可作为 daily driver 正常使用，因此目前列为低优先级。
- 欢迎有兴趣的开发者提交针对指纹录入上限的修复方案或 Patch。

---

## 🛡️ KernelSU Next Integration

* **Kernel Driver**: Built directly into Linux 4.19.325 kernel (`CONFIG_KSU=y`, `CONFIG_KPROBES=y`, `CONFIG_HAVE_KPROBES=y`, `CONFIG_KPROBE_EVENTS=y`, `CONFIG_OVERLAY_FS=y`).
* **SELinux Mode**: Maintained strictly in **Enforcing** mode.
* **Partition Integrity**: Zero dynamic partitions, zero retrofit super partition changes.
* **Working Baseline**: Golden baseline preserved at tag `avium-16.2.1-enchilada-4.19-working`. The KernelSU integration is committed as an isolated, easily-revertible commit on top.
* **Manager APK**: Install the official [KernelSU Next Manager (v3.3.0+)](https://github.com/KernelSU-Next/KernelSU-Next/releases) to manage root permissions and modules.

---

## 🎵 Audio Enhancements & ViPER4Android

* **Dolby Audio Stack**: The non-functional user-space `LunarisDolby` APK has been completely removed to avoid application crashes. The underlying Qualcomm/OnePlus hardware audio HAL, mixer paths, sound trigger, and Dirac GEF configurations are strictly preserved and verified stable.
* **ViPER4Android Evaluation**:
  - Android 16 QPR2 (API 36) enforces strict AIDL audio effect interfaces (`android.hardware.audio.effect`) and strict `audioserver` SELinux domains.
  - Compiling legacy ViPER4Android directly into `/system` carries severe risks of `audioserver` linker failure, SELinux policy rejections, silent telephony audio, and potential bootloops.
  - **Recommended & Supported Path**: ViPER4Android is supported seamlessly as a **KernelSU systemless module** (`ViPER4Android-RE` or `Audio Modification Library`).
  - **Installation Instructions**:
    1. Open KernelSU Next Manager.
    2. Flash the latest `ViPER4Android-RE` Magisk/KSU module.
    3. Reboot the device. The effect driver binds systemlessly without altering `/system` or compromising SELinux Enforcing.

---

## 🔤 Chinese Font Pack (中文字体扩展包)

Integrated 5 high-quality, open-source OFL Chinese fonts accessible via **Settings -> Wallpaper & style -> Fonts**:

| Font Name | Style / 风格 | License | Characteristics |
| :--- | :--- | :--- | :--- |
| **得意黑 (Smiley Sans)** | 现代无衬线 / 几何黑体 | SIL OFL 1.1 | 现代窄体几何黑体，视觉张力出众，排版极具现代感 |
| **霞鹜文楷 (LXGW WenKai)** | 文艺书卷 / 楷体 | SIL OFL 1.1 | 温润典雅的书卷楷体，专为屏幕阅读优化，长文排版舒适 |
| **霞鹜新晰黑 (LXGW Neo XiHei)** | 极简 UI 黑体 / 人文黑体 | SIL OFL 1.1 | 现代清爽黑体，笔画分明，与系统界面完美契合 |
| **小赖圆体 (Xiaolai Rounded)** | 治愈圆体 / 手写风 | SIL OFL 1.1 | 柔和亲切的圆体手写风，视觉轻松温和 |
| **思源宋体 (Noto Serif SC)** | 典雅宋体 / 明朝体 | SIL OFL 1.1 | 经典人文衬线宋体，骨肉停匀，适合文艺与阅读场景 |

* **Fallback Safety**: Registered via `/product/etc/fonts_customization.xml`. Unspecified glyphs (emoji, rare symbols, multi-language scripts) cleanly fall back to Android system fonts without missing glyphs or layout truncation.
* **Storage Footprint**: Total font binaries ~69 MiB uncompressed, compressed to ~32 MiB under EROFS (`lz4hc,9`), well within the 150 MiB partition budget.

---

## 🖼️ Curated System Wallpapers (精选系统壁纸)

Integrated 16 curated high-definition wallpapers natively into **WallpaperPicker2 / ThemePicker** via `AviumWallpapersPartner`:

* **Resolution & Format**: 1440 × 3120 (19.5:9 modern flagship aspect ratio), encoded in high-quality WebP with dedicated low-latency thumbnails.
* **Diverse Aesthetics**:
  1. **极简风景 & 唯美自然**: Yosemite Mountain (优胜美地), Mojave Desert Night (莫哈韦), Catalina Coast (卡特琳娜), Sequoia Forest (红杉深林), Sonoma Dusk (索诺玛).
  2. **抽象几何 & 灵动光影**: Windows Bloom Light/Dark (绽放), Aurora Glow (极光), Captured Motion (流光), Monterey Canyon (峡谷).
  3. **深色系质感 (OLED Dark)**: Monochrome Obsidian (曜石黑), Midnight Azure (暗夜深蓝), Cyber Violet (赛博紫).
  4. **晨曦流动 (Flow & Sunrise)**: Sunrise Vista (晨光), Fluid Flow (涓流), Solar Amber (暖阳).
* **System Integration**: Native discovery via `com.android.launcher3.action.PARTNER_CUSTOMIZATION`. Displays under "On-device wallpapers" without replacing AviumUI's official default wallpaper.
* **Storage Footprint**: All 16 wallpapers + thumbnails take only **3.0 MiB** total.

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
