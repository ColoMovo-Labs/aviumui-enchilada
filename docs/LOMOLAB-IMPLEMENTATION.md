# LoMoLab Implementation & Module Architecture Specification

> **Module Name**: `LoMoLab`  
> **Package Identifier**: `org.lomolab.settings`  
> **Application Type**: Privileged Platform System Application (`privileged: true`, `platform_apis: true`, `certificate: "platform"`)  
> **Source Location**: `packages/apps/LoMoLab`  
> **Install Partition**: Product (`product_specific: true`, destination: `/product/priv-app/LoMoLab/LoMoLab.apk`)  
> **Maintainer**: LoMo 洛陌  
> **Target OS**: AviumUI 16.2.1 (Android 16 QPR2) for OnePlus 6 (`enchilada`)

---

## 1. Overview & Objectives

LoMoLab is an independent customization center and experimental laboratory created specifically for AviumUI on OnePlus 6 (`enchilada`). It adheres strictly to the Golden Baseline:
- Zero disruption to upstream AviumUI components (AviumUI Personalization is preserved).
- Physical Legacy A/B partition integrity (no Super, no Dynamic Partitions).
- Linux 4.19 pure kernel without KernelSU.
- Standard AOSP and hardware abstraction APIs (LightsManager, OverlayManager, RoleManager).

---

## 2. Directory Layout & Key Artifacts

```
packages/apps/LoMoLab/
├── Android.bp                                 # Soong build definition + privapp permissions rule
├── AndroidManifest.xml                        # Main manifest with IA_SETTINGS dynamic homepage export
├── privapp-permissions-org.lomolab.settings.xml # System privapp whitelist
├── res/
│   ├── drawable/                              # High-precision vector assets for all 9 categories
│   │   ├── ic_lomolab.xml                     # Brand icon
│   │   ├── ic_appearance_fonts.xml
│   │   ├── ic_status_bar.xml
│   │   ├── ic_super_island.xml
│   │   ├── ic_control_center.xml
│   │   ├── ic_animations.xml
│   │   ├── ic_pixel_features.xml
│   │   ├── ic_gemini_hilight.xml
│   │   ├── ic_experimental.xml
│   │   └── ic_about_lomolab.xml
│   ├── layout/
│   │   ├── activity_lomolab.xml               # Main dashboard container with MaterialToolbar
│   │   └── activity_sub_settings.xml          # Sub-page container with back navigation
│   ├── values/
│   │   ├── arrays.xml                         # Font overlays, display modes, LED test values
│   │   ├── colors.xml                         # Accent colors (Cyan #00E5FF, Purple #9C27B0, Blue #2979FF)
│   │   ├── strings.xml                        # International English localization
│   │   └── styles.xml                         # DayNight Material theme
│   ├── values-zh-rCN/
│   │   └── strings.xml                        # Simplified Chinese localization (Microsoft + Google + Apple blend)
│   └── xml/
│       ├── lomolab_main.xml                   # 9-category primary dashboard
│       ├── appearance_fonts_settings.xml
│       ├── status_bar_settings.xml
│       ├── super_island_settings.xml
│       ├── control_center_settings.xml
│       ├── animations_settings.xml
│       ├── pixel_features_settings.xml
│       ├── gemini_hilight_settings.xml
│       ├── experimental_settings.xml
│       └── about_lomolab_settings.xml
└── src/org/lomolab/settings/
    ├── LoMoLabActivity.kt                     # Main entry activity & fragment dispatcher
    ├── SubSettingsActivity.kt                 # Modular sub-page host activity
    ├── AppearanceFontsFragment.kt             # Font selector & Personalization deep link
    ├── StatusBarFragment.kt                   # Status bar capsule & speed monitor
    ├── SuperIslandFragment.kt                 # Super Island events & modes
    ├── ControlCenterFragment.kt               # QS styles, blur & quick pulldown
    ├── AnimationsFragment.kt                  # Screen-off animation & timing
    ├── PixelFeaturesFragment.kt               # AI Wallpaper probe & Photos backup status
    ├── GeminiHiLightFragment.kt               # HiLight triggers, assistant probe & LED test
    ├── ExperimentalFragment.kt                # Memory compaction & touch tuning
    ├── AboutLoMoLabFragment.kt                # Baseline diagnostics & build information
    ├── fonts/
    │   └── FontManager.kt                     # RRO & THEME_CUSTOMIZATION_OVERLAY_PACKAGES engine
    ├── hilight/
    │   ├── HiLightController.kt               # LightsManager LightsSession hardware abstraction
    │   ├── HiLightService.kt                  # Event-driven audio callbacks & state machine
    │   └── BootCompletedReceiver.kt           # On-boot listener
    ├── pixel/
    │   └── AiWallpaperController.kt           # Component probe with zero-crash guarantee
    └── utils/
        └── SettingsHelper.kt                  # Type-safe System/Secure/Global bindings
```

---

## 3. Settings App Entry Integration

LoMoLab is exposed on the Android Settings homepage through a dual-channel architecture:
1. **Dynamic Information Architecture (`IA_SETTINGS`)**:
   In `AndroidManifest.xml`, `LoMoLabActivity` declares:
   ```xml
   <intent-filter>
       <action android:name="android.intent.action.MAIN" />
       <action android:name="org.lomolab.settings.MAIN" />
       <action android:name="com.android.settings.action.IA_SETTINGS" />
       <category android:name="android.intent.category.DEFAULT" />
   </intent-filter>
   <meta-data
       android:name="com.android.settings.category"
       android:value="com.android.settings.category.ia.homepage" />
   <meta-data
       android:name="com.android.settings.title"
       android:resource="@string/lomolab_app_name" />
   <meta-data
       android:name="com.android.settings.summary"
       android:resource="@string/lomolab_summary" />
   <meta-data
       android:name="com.android.settings.icon"
       android:resource="@drawable/ic_lomolab" />
   <meta-data
       android:name="com.android.settings.order"
       android:value="-90" />
   ```
2. **Static Dashboard Integration (`top_level_settings.xml`)**:
   `fix_known_blockers.sh` safely injects `top_level_lomolab` into `packages/apps/Settings/res/xml/top_level_settings.xml` pointing to `org.lomolab.settings.LoMoLabActivity`, accompanied by the corresponding drawable and localized strings.
3. **AviumUI Personalization Preservation**:
   AviumUI's native `org.exthm.featuresettings` remains untouched and functional on the Settings homepage. Users can navigate freely between AviumUI Personalization and LoMoLab.

---

## 4. Nine Primary Functional Pillars

1. **Appearance & Fonts**:
   Manages the 11 registered Chinese and global font families via standard Android runtime overlays (`android.theme.customization.font`). Includes live preview samples and deep-linking to AviumUI themes.
2. **Status Bar**:
   Manages the status bar capsule, real-time download/upload speed meter, and battery icon geometries.
3. **Super Island**:
   Exposes controls for the Super Island expansion system across media, charging, headset, call, recording, timer, and flashlight events. Content `RenderEffect` blur has been permanently eliminated to preserve text, icon, and album art sharpness.
4. **Control Center**:
   Provides quick switching between Stock AOSP unified Quick Settings and the Elixir split control center, with backdrop blur intensity controls and quick pulldown thresholds.
5. **Animations**:
   Features screen-off visual effects (Default Fade, Retro CRT TV, Scale Down) and global system transition scalers.
6. **Pixel-style Features**:
   Houses the safe AI Wallpaper probe and Google Photos unlimited original quality cloud backup status monitor.
7. **Gemini & HiLight**:
   Drives the OnePlus 6 RGB notification LED in response to Assistant microphone recording, thinking, and audio response states via `android.hardware.lights.LightsManager.LightsSession`.
8. **Experimental**:
   Houses aggressive zRAM memory compaction triggers and gaming touch polling latency optimizations.
9. **About LoMoLab**:
   Displays hardware diagnostics, OnePlus 6 `enchilada` specifications, and verifies the pure Linux 4.19 golden baseline integrity.
