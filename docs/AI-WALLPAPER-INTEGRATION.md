# AI Wallpaper Architecture & Legal Source Tree Audit

> **Target Device**: OnePlus 6 (enchilada / Snapdragon 845)  
> **Target OS**: AviumUI 16.2.1 (Android 16 QPR2)  
> **Status**: **LEGITIMATE SOURCE AUDIT COMPLETED — ZERO-CRASH ISOLATION ACTIVE**

---

## 1. Legal Audit of GMS & Proprietary Repositories

### 1.1 Source Tree Repositories Audited
1. `vendor/pixel/gms` (`proprietary_vendor_pixel_gms`):
   - Contains standard platform GMS prebuilts: GoogleTTS, LatinIMEGooglePrebuilt, MarkupGoogle, ModuleMetadataGoogle, NgaResources, SearchSelectorPrebuilt, SettingsIntelligenceGooglePrebuilt, TurboPrebuilt, WellbeingPrebuilt, Flipendo.
   - **AICore**: **ABSENT**. Google AICore is a Tensor-exclusive system package requiring native Gemini Nano NPU drivers not available on Snapdragon 845.
   - **Google AI Wallpapers (`AiWallpapers`)**: **ABSENT**. The proprietary APK is not provided in legal GMS trees for legacy devices and requires Google server entitlement.
2. `vendor/pixel/clocks` & `vendor/pixel/sounds`:
   - Contains Pixel clock widgets and notification sound assets. No wallpaper AI components present.

### 1.2 Compliance Rules Enforced
- **NO Third-Party APK Ingestion**: Prohibited downloading proprietary Google APKs from unauthorized websites or APK mirrors.
- **NO Re-signing or Cracking**: Prohibited re-signing Google binaries or bypassing Google server entitlement checks.
- **NO Fake Tensor Spoofing**: Avoided globally spoofing `ro.soc.manufacturer` or `ro.product.model` to Pixel 11 / Tensor to cheat server entitlement.

---

## 2. LoMoLab Runtime Detection & Graceful Handling

In LoMoLab -> **Pixel-style Features**, an entry titled **AI Wallpaper** is provided:
1. **Runtime Probe (`AiWallpaperController.kt`)**:
   Upon click, the application checks `PackageManager` for exported activities matching:
   - `com.google.android.apps.wallpaper / CategoryPickerActivity`
   - `com.google.android.apps.aiwallpapers / MainActivity`
   - `com.google.android.apps.wallpaper.nexus / NexusWallpaper`
2. **If Found**:
   Safely launches the activity via explicit intent with `FLAG_ACTIVITY_NEW_TASK`.
3. **If Unavailable (Current Expected State)**:
   Instead of crashing or throwing `ActivityNotFoundException`, LoMoLab catches the state and presents an informative Material Alert Dialog:
   > **Title**: AI 壁纸组件未就绪 (AI Wallpaper Unavailable)  
   > **Message**: Pixel AI 壁纸功能深度依赖本地 Google AICore 与 Google 服务端硬件凭证。本系统保持纯净开放的物理分区与合规架构，未预装专有 AI Wallpaper 私有软件包。系统已安全隔离检测，确保整体环境坚如磐石，零崩溃。

### 3. Impact Assessment
- **WallpaperPicker2**: Does not crash when opening Wallpaper & Style settings.
- **Settings**: Does not encounter broken resources or dangling preference keys.
- **SystemUI**: Does not experience missing component exceptions or loop restarts.
