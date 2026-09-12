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
* [x] Non-functional LunarisDolby user app purged; official Qualcomm/OnePlus Audio HAL, Dirac GEF, and sound trigger preserved.
* [x] Curated Chinese font collection integrated (11 OFL styles, ThemePicker compatible).
* [x] Curated system wallpaper collection integrated (27 high-res 1440x3120 WebP wallpapers, WallpaperPicker partner app).
* [x] Native Status Bar Capsule & Super Island (Ongoing Activity Island) integrated into SystemUI with OnePlus 6 notch adaptation and Avium Settings.


---

## 👤 Maintainer

* **Maintainer**: LoMo 洛陌

---

## 🏝️ Native Status Bar Capsule & Super Island / 原生状态栏胶囊与超级岛

A fully native, hardware-aware Ongoing Activity experience built directly into SystemUI for the OnePlus 6 (`enchilada`).

### Key Highlights
- **100% Native SystemUI Implementation**: Built inside `frameworks/base/packages/SystemUI`, eliminating third-party overlay services, accessibility hacks, or floating window latency.
- **OnePlus 6 Notch Alignment**: Geometry tailored for the 1080x2280 AMOLED display and center physical cutout (366px wide, 80px high). The expanded island envelopes the notch seamlessly with pure OLED black/frosted glass, ensuring no text or controls are ever occluded.
- **Prioritized Activity Queue**:
  1. **Privacy & Security**: High-sensitivity indicators (mic/camera/location/recording).
  2. **Phone Calls**: Live ongoing call pill with real-time duration chronometer and end-call action.
  3. **Screen Recording**: Real-time recording indicator, live elapsed timer, and quick-stop control.
  4. **Timers**: Active countdown chronometer and reset/dismiss controls.
  5. **Charging & Dash Charge**: Real-time battery %, OnePlus Dash / Warp fast-charging detection, and transient animated pop-up.
  6. **Headphones**: Wired 3.5mm jack & Bluetooth audio connect banner with device identification.
  7. **Media Playback**: Live track title (marquee), artist, album artwork, dynamic 3-bar animated equalizer, and playback controls (prev/pause/next).
  8. **Flashlight**: Active flashlight status and one-tap shutoff.
- **Material Expressive Motion**: Smooth spring damping (`PathInterpolator(0.18, 0.9, 0.2, 1.05)`) with gesture dismiss (swipe up to collapse, horizontal swipe to cycle multiple events).
- **SurfaceFlinger Window Blur**: Automatically detects `ro.surface_flinger.supports_background_blur`. Renders real-time RenderEffect blur when enabled, with crisp semi-translucent dark OLED fallback when disabled.
- **Battery-Friendly (Zero Standby Overhead)**: Automatically unhooks animation loops and chronometers on screen-off via `WakefulnessLifecycle` and `KeyguardUpdateMonitor`.
- **Customization**: Managed via `Avium Settings -> Status Bar -> Capsule & Super Island` (or `设置 -> 状态栏 -> 胶囊与超级岛`), with display mode selection (Capsule only, Island only, or Linked), per-event toggles, and blur switches.


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

## 🛡️ Pure Linux 4.19 Kernel Architecture

* **Kernel Version**: Verified Linux 4.19.325 baseline (`avium-16.2.1-enchilada-4.19-working`).
* **SELinux Mode**: Maintained strictly in **Enforcing** mode.
* **Partition Integrity**: Physical Legacy A/B (`/system_a`, `/system_b`, `/vendor_a`, `/vendor_b`), Zero Super, Zero Retrofit Dynamic Partitions.
* **Security & Stability**: Unmodified core Linux 4.19 LTS baseline, ensuring zero syscall hook overhead, full VoLTE/IMS compatibility, stable camera HAL, and clean upstream security patches.

---

## 🎵 Audio Architecture & Audio HAL

* **Dolby Audio Stack**: The non-functional user-space `LunarisDolby` APK has been completely removed to prevent crashes. The underlying Qualcomm/OnePlus hardware audio HAL, mixer paths, sound trigger, and Dirac GEF configurations are strictly preserved and verified stable.
* **Audio Stability**: Android 16 QPR2 (API 36) enforces strict AIDL audio effect interfaces (`android.hardware.audio.effect`) and strict `audioserver` SELinux domains. System audio, telephony, VoLTE in-call audio, and Bluetooth A2DP operate reliably within SELinux Enforcing policy.

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
