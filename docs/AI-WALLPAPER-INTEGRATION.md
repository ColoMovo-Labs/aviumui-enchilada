# Google AiWallpapers Integration & Architecture Report

> **Target Device**: OnePlus 6 (`enchilada` / Snapdragon 845)  
> **Target OS**: AviumUI 16.2.1 (Android 16 QPR2)  
> **Status**: **OFFICIAL STANDALONE INTEGRATION COMPLETED — HARDWARE VERIFIED**

---

## 1. Package Specifications

Google AiWallpapers (`com.google.android.apps.aiwallpapers`) is officially integrated as a standalone product prebuilt application:

- **Source APK**: Extracted directly from validated hardware installation
- **Location**: `device/oneplus/enchilada/AiWallpapers/`
- **Build Rule**: `android_app_import` in `device/oneplus/enchilada/AiWallpapers/Android.bp`
- **Certificate**: `PRESIGNED` (maintains original Google official signature)
- **Target Partition**: Product (`product_specific: true`, non-privileged: `/product/app/AiWallpapers/`)
- **Required Libraries**: `optional_uses_libs: ["org.apache.http.legacy"]`
- **Privileged Permissions**: None required (runs safely without `privapp-permissions`)
- **Binary Size**: ~19.85 MB raw (~13 MiB in EROFS `lz4hc,9`)

---

## 2. System Discovery & Native UI Integration

1. **WallpaperPicker2 Discovery**:
   - `AiWallpapers` exposes `com.google.android.apps.aiwallpapers.service.AiWallpaperService` registered under `android.service.wallpaper.WallpaperService`.
   - Android's native `WallpaperPicker2` automatically discovers the service and presents "AI Wallpaper" directly inside the **Live Wallpapers (动态壁纸)** category in system personalization.
2. **Zero Spoofing & Zero Hacks**:
   - No Pixel device spoofing (`ro.soc.manufacturer` / `ro.product.model`) required.
   - No framework or WallpaperPicker2 patches required.
   - Generation verified functional on Snapdragon 845.
   - Generation backend status: `UNKNOWN / NEEDS OFFLINE TEST` (audited as standalone service).
