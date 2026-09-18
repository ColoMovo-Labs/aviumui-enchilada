# LoMoLab vs. AviumUI Customization Conflict Audit & Architecture Matrix

> **Target Device**: OnePlus 6 (enchilada / Snapdragon 845)  
> **Target OS**: Android 16 QPR2 (AviumUI 16.2.1)  
> **Maintainer**: LoMo 洛陌  
> **Audit Status**: **VERIFIED — ZERO CONFLICTS DETECTED**

---

## 1. Architectural Principles & Ownership Boundaries

1. **Upstream First (AviumUI Ownership)**:  
   AviumUI upstream retains exclusive ownership over baseline theming, QS styles, lockscreen clock layouts, and native status bar capsules.
2. **LoMoLab Additive Ownership**:  
   LoMoLab (`org.lomolab.settings`) retains exclusive ownership over device-specific enhancements (OnePlus 6 RGB LED / LoMo HiLight, 11 Chinese/global runtime font selection overlays, AI Wallpaper safe invocation, screen-off animations).
3. **Zero Duplicate Keys (`0 duplicate key`)**:  
   All LoMoLab-private preferences are prefixed with `lomolab_*`. Where LoMoLab exposes controls for upstream features (e.g. Super Island, Control Center style), it writes directly to AviumUI's official settings keys. No redundant secondary settings keys exist.
4. **Zero Competing Observers (`0 competing observer`)**:  
   SystemUI observers in `packages/SystemUI` observe settings keys. LoMoLab does not register competing background observers for AviumUI subsystems. LoMo HiLight is solely event-driven by Android framework audio callbacks.

---

## 2. Comprehensive Conflict Audit Matrix

| Category | Feature Name | Owner | Settings Table & Key | Observer | Backend / Implementation | Conflict Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Appearance & Fonts** | System Font Manager | LoMoLab | `secure:theme_customization_overlay_packages` (`android.theme.customization.font`) & `system:lomolab_custom_font` | SystemUI `ThemeOverlayController` | AOSP RRO & `OverlayManager` | **Clean (0 Conflict)**: Uses standard AOSP theme customization category |
| **Appearance & Fonts** | Avium Personalization Deep-link | AviumUI | N/A (Intent Launch) | None | Explicit Intent to `org.exthm.featuresettings` | **Clean (0 Conflict)**: Deep-links to native activity |
| **Status Bar** | Status Bar Capsule | AviumUI | `system:status_bar_capsule_enabled` | SystemUI `IslandSettings` | SystemUI `CapsuleController` | **Clean (0 Conflict)**: Reuses AviumUI native key |
| **Status Bar** | Real-time Network Traffic | LoMoLab | `system:lomolab_status_bar_network_traffic` | SystemUI `NetworkTraffic` | SystemUI Status Bar controller | **Clean (0 Conflict)**: Dedicated `lomolab_*` key |
| **Status Bar** | Battery Icon Style | LoMoLab | `system:lomolab_status_bar_battery_style` | SystemUI `BatteryMeterView` | SystemUI Battery controller | **Clean (0 Conflict)**: Dedicated `lomolab_*` key |
| **Super Island** | Super Island Expansion | AviumUI | `system:super_island_enabled` | SystemUI `IslandSettings` | SystemUI `IslandWindowController` | **Clean (0 Conflict)**: Reuses AviumUI native key |
| **Super Island** | Island Display Mode | AviumUI | `system:island_display_mode` | SystemUI `IslandSettings` | SystemUI `IslandWindowController` | **Clean (0 Conflict)**: Reuses AviumUI native key |
| **Super Island** | Super Island Blur Removal | AviumUI | `system:island_blur_enabled` | None (Deprecated) | **Removed**: Permanent content RenderEffect blur purged | **Clean (0 Conflict)**: UI switch removed, defaults false |
| **Super Island** | Media / Charging / Call Events | AviumUI | `system:island_event_*` | SystemUI `IslandSettings` | SystemUI `IslandEventMonitor` | **Clean (0 Conflict)**: Reuses AviumUI native keys |
| **Control Center** | QS Panel Style | AviumUI | `system:avium_control_center_style` | SystemUI `CentralSurfacesImpl` | AOSP unified / Elixir split QS layout | **Clean (0 Conflict)**: Reuses AviumUI native key |
| **Control Center** | QS Backdrop Blur | AviumUI | `system:avium_control_center_blur` | SystemUI QS Panel | SurfaceFlinger / WindowManager blur | **Clean (0 Conflict)**: Reuses AviumUI native key |
| **Control Center** | QS Blur Intensity | AviumUI | `system:avium_control_center_blur_intensity`| SystemUI QS Panel | SurfaceFlinger blur radius | **Clean (0 Conflict)**: Reuses AviumUI native key |
| **Control Center** | Quick Pulldown | LoMoLab | `system:lomolab_control_center_quick_pulldown` | SystemUI `NotificationPanelView` | Edge pull detection | **Clean (0 Conflict)**: Dedicated `lomolab_*` key |
| **Animations** | Screen-off Animation | LoMoLab | `system:lomolab_screen_off_animation` | Display power controller | WindowManager / SurfaceFlinger | **Clean (0 Conflict)**: Dedicated `lomolab_*` key |
| **Animations** | Window / Transition Scales | AOSP | `global:window_animation_scale`, `transition_animation_scale` | WindowManagerService | AOSP WMS framework | **Clean (0 Conflict)**: Standard AOSP global keys |
| **Pixel Features** | AI Wallpaper Launcher | LoMoLab | `lomolab_ai_wallpaper` (Dynamic) | None | Safe Intent probe via `PackageManager` + Graceful fallback | **Clean (0 Conflict)**: Zero-crash isolation |
| **Pixel Features** | Photos Unlimited Storage | AviumUI | `ro.product.model` spoof (Photos UID) | Framework zygote / build hook | Per-app property hook (`Pixel XL`) | **Clean (0 Conflict)**: Read-only informational UI |
| **Gemini & HiLight**| LoMo HiLight Enable | LoMoLab | `system:lomolab_hilight_enabled` | `HiLightService` ContentObserver | `org.lomolab.settings.hilight.HiLightService` | **Clean (0 Conflict)**: Dedicated `lomolab_*` key |
| **Gemini & HiLight**| Assistant Recording / Playback | LoMoLab | `system:lomolab_hilight_listening_enabled`, `thinking`, `responding` | `AudioManager` callbacks | Framework audio recording/playback callbacks | **Clean (0 Conflict)**: Event-driven audio callbacks |
| **Gemini & HiLight**| Hardware Lights Arbitration | LoMoLab | `system:lomolab_hilight_disable_charging`, `screen_off_only` | `LightsManager.LightsSession` | AOSP `android.hardware.lights.LightsManager` | **Clean (0 Conflict)**: Standard HAL session auto-restore |
| **Gemini & HiLight**| Test RGB LED | LoMoLab | Transient selection | Main Handler timer (2500ms) | `LightsSession.requestLights` -> auto close | **Clean (0 Conflict)**: Zero state persistence |
| **Experimental** | Memory Compaction | LoMoLab | `system:lomolab_exp_memory_compaction` | ActivityManager compaction | Kernel zRAM compaction | **Clean (0 Conflict)**: Dedicated `lomolab_*` key |
| **Experimental** | Touch Sampling Tuning | LoMoLab | `system:lomolab_exp_game_touch_tuning` | InputManagerService | Touch HAL boost | **Clean (0 Conflict)**: Dedicated `lomolab_*` key |
| **About LoMoLab** | Baseline Audit Info | LoMoLab | Read-only sysprop & build info | None | Static Information | **Clean (0 Conflict)**: Diagnostic read-only |

---

## 3. Summary of Compliance

- **Duplicate Ownership Count**: `0`
- **Duplicate Key Count**: `0`
- **Competing Observer Count**: `0`
- **AviumUI Native Preserved**: `100%` (Personalization remains intact and deep-linked)
- **Settings Main Page Access**: Seamlessly accessible via AOSP `IA_SETTINGS` and top-level settings tile.
