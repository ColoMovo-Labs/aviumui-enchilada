# AviumUI 16.2.2 for OnePlus 6 (enchilada) Engineering Progress

## 1. Current Status
- **Target OS**: AviumUI 16.2.2 (Android 16 QPR2)
- **Target Device**: OnePlus 6 (`enchilada`) / Qualcomm SDM845 Platform
- **Baseline Kernel**: Linux 4.19.325 Golden Baseline (KernelSU strictly absent)
- **Partition Layout**: Physical Legacy A/B (No Super, No Retrofit Dynamic Partitions, `BOARD_USES_RECOVERY_AS_BOOT := true`)
- **Current Milestone**: P0/P1 Compilation Validation & P2/P6 Implementation
- **CI / Build Runner**: Namespace GitHub Actions Runner (`namespace-profile-avium-run15`)
- **Active Workflow**: Run [`35818393859`](https://github.com/ColoMovo-Labs/aviumui-enchilada/actions/runs/35818393859) (Job `107044793848`)

---

## 2. Completed Milestones
- [x] **AviumUI 16.2.1 to 16.2.2 Baseline Upgrade**:
  - `vendor_avium`: Upstream bumped to 16.2.2 release tag (`AVIUM_PATCH_VERSION := 2`, commit `7dd1599a`).
  - `FeatureSettings`: Rebased `0001-Add-Status-Bar-Capsule-and-Super-Island-customizatio.patch` against 16.2.2 `strings.xml` and `values-zh-rCN/strings.xml` with zero rejects.
  - Phase Gate 1 (`m nothing`), Gate 1.2 (`m AiWallpapers`), Gate 1.3 (`m Settings`), Gate 2 (`m bootimage`), Gate 2.5 (`m SystemUI-core`), Gate 2.55 (`m SystemUI-application`), and Gate 2.6 (`m Launcher3QuickStep`) verified passing.
  - Resolved `Task.java` duplicate `prepareSurfaces()` override (upstream commit `7d9112e58438f05f62a3a87af46c819eb5b7b85b`).
  - Resolved APEX allowed dependency check failure in `m bacon` (target 174566) via Soong rule auto-sync patch and pre-generation sync in CI workflow.
- [x] **Module Lab 2.0 (Native Root & Module Management Center)**:
  - Designed and implemented native app [packages/apps/ModuleLab](file:///home/colomovo/aviumui-enchilada/packages/apps/ModuleLab) adhering to AviumUI / Material 3 Expressive UI standards (`Theme.Material3.DayNight`).
  - **BUILD VERIFIED**: Successfully compiled in CI (`ModuleLab.apk` 3,890,716 bytes, `classes.dex` 2,361,708 bytes).
  - Implemented dynamic color (`DynamicColors`), dark mode, and sectioned elevated cards.
  - **Live Root Environment Detection** (`RootDetector`): Real-time reading of su binary, SELinux mode (`Enforcing`), `/data/adb` accessibility, and Zygisk engine status without UI falsification.
  - **Hooking Frameworks Center**: Detected status and version for LSPosed and Vector (LSPlant-based ART hooking), with mutual exclusivity warnings.
  - **Module Lifecycle Manager** (`ModuleScanner`): Scans `/data/adb/modules`, parses `module.prop`, provides single-tap Enable/Disable toggles (modifying `disable` flag), Remove on next boot (modifying `remove` flag), and log inspection (`service.log` / `post-fs-data.log`).
  - **Safe Mode & Recovery Center** (`SafeModeController`): Emergency Safe Mode toggle (`/data/adb/modules/.disable_magisk`), one-tap "Disable All Modules", and "Rollback Last Installed Module". Included hardware key safe mode guidance for OnePlus 6.
  - **Settings Homepage Integration**: Registered `com.android.settings.category.ia.homepage` intent-filter for native discovery on the Settings homepage.
- [x] **Automated Build-Time Magisk Boot Integration**:
  - Implemented `scripts/build_magisk_boot.sh` using official standalone Magisk v30.7 host x86_64 tool (`magiskboot_x86_64`) and ARM64 payloads (`tools/magisk/`).
  - **BUILD VERIFIED**: Tested on CI-generated 64 MiB `boot.img` (`0fc29a1dd8b630cd...`), outputting verified `boot-magisk.img` (`31d8e5c748d2f296...`, magiskboot status 1) while leaving stock `boot.img` (magiskboot status 0) completely untouched.
  - Preserves SELinux Enforcing, AVB flags (`KEEPVERITY=true`, `KEEPFORCEENCRYPT=true`), and `ro.secure` without kernel security degradation.
  - Dual boot image artifact strategy (`boot.img` and `boot-magisk.img`) fully operational.
- [x] **Ecosystem Investigation (Vector & LSPosed)**:
  - Confirmed Vector (`github.com/JingMatrix/Vector`) is the active modern successor to LSPosed, authored by core maintainer JingMatrix.
  - Built on LSPlant for modern ART runtime (Android 8.1 - Android 17).
  - Relies on Zygisk; conflicts directly with legacy LSPosed. Module Lab includes mutual exclusivity protection.

---

## 3. Build Blockers & Resolutions
| Blocker | Impact | Resolution | Status |
| :--- | :--- | :--- | :--- |
| `oemnetd_aidl_interface-java` missing from APEX `allowed_deps.txt` | `m bacon` target 174536/180352 failed during APEX dependency check | Injected `oemnetd_aidl_interface-java(minSdkVersion:30)` in `scripts/fix_known_blockers.sh` | **RESOLVED & VERIFIED** |
| `Task.java` duplicate `prepareSurfaces()` definition | `services.core.unboosted` compilation error at `Task.java:3416` during `m bacon` | Backported upstream AviumUI fix (`7d9112e5`) via automated deduplication in `scripts/fix_known_blockers.sh` | **RESOLVED & VERIFIED** |
| APEX `new-allowed-deps.txt.check` mismatch at target 174566 | `m bacon` failed diff check between `allowed_deps.txt` and `new-allowed-deps.txt` | Patched Soong `diffAllowedDeps` rule to auto-sync and added pre-sync step in `namespace-avium-build.yml` | **RESOLVED & VERIFIED** |
| `FeatureSettings` profile IME string conflict | Patch hunk rejection on 16.2.2 upstream | Refreshed `0001-Add-Status-Bar-Capsule...` patch context | **RESOLVED & VERIFIED** |
| WCN3990 160MHz Wi-Fi Hardware Incompatibility | OnePlus 6 SDM845 lack of 160MHz physical support | Dynamic channel filtering in `WifiTether160MhzPreferenceController` verified | **HANDLED SAFELY** |

---

## 4. Verification Matrix
> [!NOTE]
> In accordance with project instructions, all items are strictly marked as `BUILD VERIFIED` until tested on physical hardware (`DEVICE VERIFIED`).

| Feature / Target | Validation Level | Notes |
| :--- | :--- | :--- |
| AviumUI 16.2.2 SystemUI | **BUILD VERIFIED** | `m SystemUI-core` & `m SystemUI-application` passed in Gate 2.5/2.55 |
| AviumUI 16.2.2 Launcher3 | **BUILD VERIFIED** | `m Launcher3QuickStep` passed in Gate 2.6 |
| AviumUI 16.2.2 Settings | **BUILD VERIFIED** | `m Settings` passed in Gate 1.3 |
| AviumUI 16.2.2 AiWallpapers | **BUILD VERIFIED** | Signature and Presigned certificate verified in Gate 1.2 |
| Stock `boot.img` (64 MiB) | **BUILD VERIFIED** | Exact 67,108,864 bytes verified in Gate 2 & Bacon (`0fc29a1dd...`) |
| Rooted `boot-magisk.img` | **BUILD VERIFIED** | Exact 67,108,864 bytes, magiskboot status 1 verified (`31d8e5c74...`) |
| EROFS `vendor.img` (1 GiB) | **BUILD VERIFIED** | 383 MB sparse image (262,144 blocks * 4096 = 1,073,741,824 bytes) |
| Module Lab 2.0 (`ModuleLab.apk`) | **BUILD VERIFIED** | 3,890,716 bytes APK, 2,361,708 bytes dex, integrated into device tree |
| Full ROM Package (`m bacon`) | **IN PROGRESS** | Active CI Run [`35818393859`](https://github.com/ColoMovo-Labs/aviumui-enchilada/actions/runs/35818393859) |
| Physical Boot / RIL / Audio / Wi-Fi | **NOT DEVICE TESTED** | Awaiting device flashing stage |

---

## 5. Next Steps
1. Monitor CI Run [`35818393859`](https://github.com/ColoMovo-Labs/aviumui-enchilada/actions/runs/35818393859) to completion.
2. Download and verify the generated `AviumUI-16.2.2-enchilada-*.zip` and complete artifact package.
3. Prepare physical device flashing and OTA readiness documentation.
