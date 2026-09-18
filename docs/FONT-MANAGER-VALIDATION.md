# Font Manager Architecture & Validation Report

> **Target Device**: OnePlus 6 (enchilada / Snapdragon 845)  
> **ROM Base**: AviumUI 16.2.1 (Android 16 QPR2)  
> **Font Engine**: Runtime Resource Overlay (RRO) + AOSP Theme Customization Category + Android `OverlayManager`  
> **Validation Status**: **PASS — 11/11 CURATED FONTS SELECTABLE & VERIFIED**

---

## 1. Registered Fonts & Overlay Mapping

Every font is physically prebuilt in the product partition (`/product/fonts/`), registered with named families and medium/bold aliases in `fonts_customization.xml`, and packaged with a dedicated RRO targeting category `android.theme.customization.font`.

| # | Font Name (CN / EN) | Family Name (`fonts_customization.xml`) | Overlay Package Name | Prebuilt Binary Path in `/product/fonts/` |
| :-: | :--- | :--- | :--- | :--- |
| **0** | **System Default** | `sans-serif` (Roboto / Noto Sans) | `android` (Default) | System standard fallback font chain |
| **1** | 得意黑 (Smiley Sans) | `smiley-sans` | `org.avium.overlay.font.smileysans` | `SmileySans-Oblique.ttf` |
| **2** | 霞鹜文楷 (LXGW WenKai) | `lxgw-wenkai` | `org.avium.overlay.font.lxgwwenkai` | `LXGWWenKaiLite-Regular.ttf` |
| **3** | 霞鹜新晰黑 (LXGW Neo XiHei) | `lxgw-neoxihei` | `org.avium.overlay.font.lxgwneoxihei` | `LXGWNeoXiHei.ttf` |
| **4** | 小赖圆体 (Xiaolai Rounded) | `xiaolai-rounded` | `org.avium.overlay.font.xiaolai` | `Xiaolai-Regular.ttf` |
| **5** | 思源宋体 (Noto Serif SC) | `noto-serif-sc` | `org.avium.overlay.font.notoserifsc` | `NotoSerifSC.ttf` |
| **6** | 站酷庆科黄油体 (ZCOOL QingKe) | `zcool-qingke-huangyou` | `org.avium.overlay.font.zcoolqingkehuangyou`| `ZCOOLQingKeHuangYou-Regular.ttf` |
| **7** | 站酷小薇体 (ZCOOL XiaoWei) | `zcool-xiaowei` | `org.avium.overlay.font.zcoolxiaowei` | `ZCOOLXiaoWei-Regular.ttf` |
| **8** | 站酷快乐体 (ZCOOL KuaiLe) | `zcool-kuaile` | `org.avium.overlay.font.zcoolkuaile` | `ZCOOLKuaiLe-Regular.ttf` |
| **9** | 马善政毛笔体 (Ma Shan Zheng) | `mashanzheng` | `org.avium.overlay.font.mashanzheng` | `MaShanZheng-Regular.ttf` |
| **10**| 龙藏体 (Long Cang) | `longcang` | `org.avium.overlay.font.longcang` | `LongCang-Regular.ttf` |
| **11**| 志莽行书 (Zhi Mang Xing) | `zhimangxing` | `org.avium.overlay.font.zhimangxing` | `ZhiMangXing-Regular.ttf` |

---

## 2. Runtime Font Switching Mechanism

### 2.1 AOSP Secure Settings Transaction
When a user selects a font in LoMoLab -> **Appearance & Fonts**:
1. `FontManager.applyFont(...)` retrieves `Settings.Secure.THEME_CUSTOMIZATION_OVERLAY_PACKAGES`.
2. It parses the stored JSON object:
   ```json
   {
     "android.theme.customization.font": "org.avium.overlay.font.smileysans"
   }
   ```
   For **System Default**, the `"android.theme.customization.font"` key is stripped or set to `"android"`.
3. SystemUI's `ThemeOverlayController` is woken by the `ContentObserver` on this secure setting. It automatically calls `OverlayManagerTransaction` to enable the target overlay and disable the previous overlay.

### 2.2 Direct Privileged OverlayManager Fallback
Because `LoMoLab` runs with privileged status and holds `android.permission.CHANGE_OVERLAY_PACKAGES`:
`FontManager` simultaneously instructs `OverlayManager.setEnabled(targetPkg, true, userHandle)` and disables all other 10 font overlays. This ensures instant font application across running processes without requiring a reboot or SystemUI restart.

---

## 3. Typographical Fallback & Crash Prevention Verification

### 3.1 Glyph Fallback Integrity
- **Chinese Characters**: Rendered by the chosen font family if glyph exists.
- **Latin & Numerical Characters**: Included directly in modern Chinese font binaries (Smiley Sans, LXGW WenKai, LXGW Neo XiHei) or seamlessly fall back to Roboto/Noto Sans via Android's fallback font XML mechanism.
- **Emoji Fallback**: Google Noto Color Emoji remains intact at the root of `fonts.xml` and is unaffected by font overlays. Emoji renders in full color across all apps.
- **No Tofu (□)**: Every font overlay inherits standard Android XML fallback chain rules. Characters not supported by decorative calligraphic fonts (e.g. Long Cang, Zhi Mang Xing) fall back cleanly to system Noto Sans SC instead of missing-glyph boxes.

### 3.2 Stability Assertions
- **Zero Copying**: No runtime `cp` to `/system` or `/product`.
- **Zero Root / Magisk**: Operates 100% within SELinux Enforcing boundaries using native Android OS overlay APIs.
- **Process Stability**: Tested and verified that font overlay switching does not cause crashes in:
  - `com.android.settings` (Settings)
  - `com.android.systemui` (SystemUI)
  - `com.android.launcher3` (Launcher3QuickStep)
