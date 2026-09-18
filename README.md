# AviumUI 16.2 Bring-up for OnePlus 6 (enchilada)

[简体中文](README.zh-CN.md)

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
* [x] Native Status Bar Capsule & Super Island integrated into SystemUI with OnePlus 6 notch adaptation.
* [x] Super Island RenderEffect blur formally purged; crisp OLED translucent styling with zero visual artifacts.
* [x] 27 bundled wallpapers unbundled to liberate critical physical A/B system partition headroom (~15 MB).
* [x] Standalone privileged **LoMoLab** (`org.lomolab.settings`) customization suite added with 9 feature categories.
* [x] 11 curated Chinese & global fonts integrated into LoMoLab Font Manager with dynamic RRO switching.
* [x] **LoMo HiLight** hardware RGB notification LED assistant integration implemented via `LightsSession`.
* [x] GMS AI Wallpaper audited with zero-crash runtime capability detection and graceful fallback.

---

## 👤 Maintainer

* **Maintainer**: LoMo 洛陌

---

## 🧪 LoMoLab Customization Center / 洛陌实验室

**LoMoLab** (`org.lomolab.settings`) is a standalone, privileged system customization suite built specifically for AviumUI on OnePlus 6. Seamlessly accessible from the top level of Android Settings, LoMoLab consolidates system tweaks into 9 modular categories:

1. **Appearance & Fonts (外观与字体)**: Integrated Font Manager offering 11 curated fonts with instant dynamic switching, icon pack styling, and shape controls.
2. **Status Bar (状态栏)**: Battery percentage styles, network speed traffic monitor, custom icon toggles, and clock position adjustments.
3. **Super Island (超级岛)**: Full configuration for ongoing activities, display mode (Capsule / Island / Linked), and per-event notification filters.
4. **Control Center (控制中心)**: Quick Settings tile grid columns, quick pull-down configuration, and brightness slider style choices.
5. **Animations (动画与手势)**: System-wide transition speed multipliers, three-finger screenshot gesture, and Back-to-Home motion curves.
6. **Pixel Features (Pixel 体验)**: Unlimited Google Photos storage spoofing, Pixel navigation bar styling, and AI Wallpaper capability status.
7. **Gemini & LoMo HiLight (呼吸灯与助手联动)**: Dynamic OnePlus 6 RGB notification LED integration for Google Assistant / Gemini interactions.
8. **Experimental Lab (实验特性)**: Game Space performance profiles, edge touch rejection tuning, and aggressive background battery optimization.
9. **About LoMoLab (关于与系统信息)**: Complete build provenance, hardware platform diagnostics, and maintainer credits.

---

## 🏝️ Native Status Bar Capsule & Super Island / 原生状态栏胶囊与超级岛

A fully native, hardware-aware Ongoing Activity experience built directly into SystemUI for the OnePlus 6 (`enchilada`).

### Key Highlights
- **100% Native SystemUI Implementation**: Built inside `frameworks/base/packages/SystemUI`, eliminating third-party overlay services, accessibility hacks, or floating window latency.
- **OnePlus 6 Notch Alignment**: Geometry tailored for the 1080x2280 AMOLED display and center physical cutout (366px wide, 80px high). The expanded island envelopes the notch seamlessly with pure OLED black/translucent styling, ensuring no text or controls are ever occluded.
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
- **Pure OLED Translucent Styling (Zero Blur Artifacts)**: The legacy `View.setRenderEffect` blur implementation has been formally purged. Super Island now renders with a refined semi-translucent dark OLED background (`#F0101012`), 1dp subtle stroke (`#33FFFFFF`), and rounded corners (`PathProvider`), delivering pristine text clarity without bleed or rectangular artifacts.
- **Battery-Friendly (Zero Standby Overhead)**: Automatically unhooks animation loops and chronometers on screen-off via `WakefulnessLifecycle` and `KeyguardUpdateMonitor`.
- **Customization**: Managed via `Settings -> LoMoLab -> Super Island` (or `设置 -> 洛陌实验室 -> 超级岛`), with display mode selection (Capsule only, Island only, or Linked) and per-event toggles.


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

---

## 🔤 Chinese Font Pack & Font Manager (中文字体扩展包与字体管理)

Integrated 11 high-quality, open-source OFL Chinese fonts accessible natively via **LoMoLab -> Appearance & Fonts** (or **Settings -> Wallpaper & style -> Fonts**):

| Font Name | Style / 风格 | License | Characteristics |
| :--- | :--- | :--- | :--- |
| **得意黑 (Smiley Sans)** | 现代无衬线 / 几何黑体 | SIL OFL 1.1 | 现代窄体几何黑体，视觉张力出众，排版极具现代感 |
| **霞鹜文楷 (LXGW WenKai)** | 文艺书卷 / 楷体 | SIL OFL 1.1 | 温润典雅的书卷楷体，专为屏幕阅读优化，长文排版舒适 |
| **霞鹜新晰黑 (LXGW Neo XiHei)** | 极简 UI 黑体 / 人文黑体 | SIL OFL 1.1 | 现代清爽黑体，笔画分明，与系统界面完美契合 |
| **小赖圆体 (Xiaolai Rounded)** | 治愈圆体 / 手写风 | SIL OFL 1.1 | 柔和亲切的圆体手写风，视觉轻松温和 |
| **思源宋体 (Noto Serif SC)** | 典雅宋体 / 明朝体 | SIL OFL 1.1 | 经典人文衬线宋体，骨肉停匀，适合文艺与阅读场景 |
| **站酷庆科黄油体 (ZCOOL HuangYou)** | 醒目圆角标题体 / 海报设计 | SIL OFL 1.1 | 饱满有力的圆角笔画，现代感与辨识度极高的标题字体 |
| **站酷小薇体 (ZCOOL XiaoWei)** | 纤细秀丽清雅体 / 典雅刻本 | SIL OFL 1.1 | 笔触纤细灵动，传承传统刻本气韵，清秀素雅 |
| **站酷快乐体 (ZCOOL KuaiLe)** | 活泼明快趣味体 / 趣味手写 | SIL OFL 1.1 | 结构活泼跳跃，风格萌动趣味，适合个性化轻松场景 |
| **马善政毛笔体 (Ma Shan Zheng)** | 雄浑毛笔体 / 写意中国风 | SIL OFL 1.1 | 挥毫泼墨的行楷气韵，笔力遒劲，尽显国风意境 |
| **龙藏体 (Long Cang)** | 潇洒连笔行书 / 传统书法 | SIL OFL 1.1 | 行气连绵流畅，笔墨生动，传统手写书法美感 |
| **志莽行书 (Zhi Mang Xing)** | 狂放肆意草书 / 钟齐书法 | SIL OFL 1.1 | 奔放不羁的行草风貌，笔势生动，视觉冲击力强 |

* **LoMoLab Font Manager**: Features an interactive visual font previewer and one-tap RRO runtime switching via `OverlayManager` and `android.theme.customization.font`.
* **Fallback Safety**: Registered via `/product/etc/fonts_customization.xml`. Unspecified glyphs (emoji, rare symbols, multi-language scripts) cleanly fall back to Android system fonts without missing glyphs or layout truncation.
* **Storage Footprint**: Total font binaries ~101 MiB uncompressed, compressed to ~48–52 MiB under EROFS (`lz4hc,9`), well within the partition budget (>1.0 GiB remaining margin).

---

## 💡 LoMo HiLight (硬件呼吸灯与智能助手协同)

LoMo HiLight brings the iconic physical RGB notification LED of the OnePlus 6 back to life, elevating it from a simple blinker into an ambient status indicator for AI interactions:

* **Official LightsManager Session Architecture**: Built entirely on `android.hardware.lights.LightsManager.openSession()`. When an event begins, a high-priority `LightsSession` requests precise hex RGB colors (`#FF4285F4` Gemini Blue, `#FF9C27B0` Violet pulse). Upon completion or screen turn-on, the session is cleanly closed, allowing the framework to automatically restore default charging/notification LED states.
* **Zero Polling & Battery-First Design**: Utilizes reactive audio recording and playback state callbacks via `AudioManager.AudioRecordingCallback` and `AudioPlaybackCallback`. Employs dynamic assistant role discovery via `RoleManager.ROLE_ASSISTANT`.
* **No Permanent Wakelocks**: Wakes the LED solely during active speech input or playback; releases all hardware locks instantly when the assistant interaction terminates.
* **Full User Customization**: Configured inside `Settings -> LoMoLab -> Gemini & LoMo HiLight`, including master toggle, assistant color presets, and pulse cadence.

---

## 🖼️ System Wallpapers & Storage Optimization (壁纸解绑与系统空间释放)

In earlier revisions, 27 bundled static wallpapers (~15 MB) were included in the device tree. To strictly safeguard the physical A/B system partition headroom (>50 MiB margin required for OTA/runtime stability):

* **Clean Storage Architecture**: The static bundled wallpapers have been unbundled from the core ROM image. This preserves crucial system partition space for GMS services and Android 16 QPR2 framework components.
* **Flexible Personalization**: Users can personalize lockscreen and homescreen wallpapers via the standard Android Wallpaper & style picker, third-party wallpaper applications, or direct gallery images.

---

## 🤖 AI Wallpaper Capability Audit (AI 生成壁纸兼容性说明)

* **Architecture Audit**: Google AI Wallpaper generation relies on proprietary on-device machine learning components (`AICore` and Tensor-specific NPU acceleration).
* **Graceful Degradation**: On the Snapdragon 845 platform, AICore is absent. In **LoMoLab -> Pixel Features**, AI Wallpaper status is monitored at runtime without throwing crashes (`ActivityNotFoundException`). If tapped when the underlying service is absent, a clean Material explanation dialog informs the user gracefully without crashing the UI.

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
├── README.zh-CN.md         # Simplified Chinese project overview
├── docs/
│   ├── PLAN.md             # 7-stage bring-up roadmap and comprehensive test matrix
│   ├── SOURCES.md          # Upstream source tracking and branch mapping
│   ├── LOMOLAB-IMPLEMENTATION.md # LoMoLab architecture and preference schema
│   ├── LOMOLAB-CONFLICT-AUDIT.md # Settings key ownership & observer collision audit
│   ├── FONT-MANAGER-VALIDATION.md# Font overlay, RRO validation & fallback spec
│   ├── AI-WALLPAPER-INTEGRATION.md# AI Wallpaper legal/capability audit & degraded mode
│   └── LOMO-HILIGHT-DESIGN.md    # OnePlus 6 RGB LED & Assistant state machine
├── local_manifests/
│   └── enchilada.xml       # Manifest for Namespace runner sync
├── packages/
│   └── apps/
│       └── LoMoLab/        # Standalone LoMoLab privileged settings suite
├── patches/
│   └── README.md           # Upstream-first patch guidelines and conventions
└── scripts/
    └── fix_known_blockers.sh # Pre-build environment and target injector script
```

---

## 💖 Acknowledgements & Special Thanks / 鸣谢

We would like to express our deepest gratitude to the following projects, organizations, and infrastructure sponsors:

* **[Namespace](https://namespace.so)**: **Special thanks to Namespace for generously providing the high-performance computing runners that made compiling the complete AviumUI 16.2.1 Android ROM (`m bacon`) possible.**  
  Powered by Namespace's 32 vCPU AMD EPYC Zen 4, 62 GiB RAM, and high-speed NVMe cloud instances (`namespace-profile-avium-run15`), our pipeline was able to handle full AOSP repo syncs, high-throughput build caching, and complete ROM compilation in record time.
* **[LineageOS Project](https://lineageos.org/)**: For providing the rock-solid device, kernel, and hardware trees for OnePlus 6 (`enchilada`) and SDM845 platform.
* **[AviumUI Team](https://github.com/AviumUI)**: For the expressive, modern Android UI design and platform framework.
* **[AOSP (Android Open Source Project)](https://source.android.com/)**: For the open Android foundation.
* **[OnePlus](https://www.oneplus.com/) & [Qualcomm](https://www.qualcomm.com/)**: For releasing the open-source kernel and device hardware references.
* **EdwinMoq & uwugl**: For pioneering SDM845 modern Android bring-up research and community references.

---

## ⚖️ License & Disclaimers

* **Source License**: Project orchestration files and custom bring-up scripts in this repository are licensed under the [Apache License 2.0](LICENSE).
* **Disclaimers**: OnePlus and the OnePlus 6 logo are trademarks of OnePlus Technology (Shenzhen) Co., Ltd. Android is a trademark of Google LLC. This project is not affiliated with, endorsed by, or associated with OnePlus or Google.
