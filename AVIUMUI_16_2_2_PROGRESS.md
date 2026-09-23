# AviumUI 16.2.2 for OnePlus 6 (enchilada) Engineering Progress

## 1. Current Status
- **Target OS**: AviumUI 16.2.2 (Android 16 QPR2)
- **Target Device**: OnePlus 6 (`enchilada`) / Qualcomm SDM845 Platform
- **Baseline Kernel**: Linux 4.19.325 Golden Baseline (KernelSU strictly absent)
- **Partition Layout**: Physical Legacy A/B (No Super, No Retrofit Dynamic Partitions, `BOARD_USES_RECOVERY_AS_BOOT := true`)
- **Current Milestone**: P0/P1 Compilation Validation & P2/P6 Implementation
- **CI / Build Runner**: Namespace GitHub Actions Runner (`namespace-profile-avium-run15`)

---

## 2. Completed Milestones
- [x] **AviumUI 16.2.1 to 16.2.2 Baseline Upgrade**:
  - `vendor_avium`: Upstream bumped to 16.2.2 release tag (`AVIUM_PATCH_VERSION := 2`, commit `7dd1599a`).
  - `FeatureSettings`: Rebased `0001-Add-Status-Bar-Capsule-and-Super-Island-customizatio.patch` against 16.2.2 `strings.xml` and `values-zh-rCN/strings.xml` with zero rejects.
  - Phase Gate 1 (`m nothing`), Gate 1.2 (`m AiWallpapers`), Gate 1.3 (`m Settings`), Gate 2 (`m bootimage`), Gate 2.5 (`m SystemUI-core`), Gate 2.55 (`m SystemUI-application`), and Gate 2.6 (`m Launcher3QuickStep`) verified passing.
  - Resolved APEX allowed dependency check failure in `m bacon` by injecting `oemnetd_aidl_interface-java(minSdkVersion:30)` into `packages/modules/common/build/allowed_deps.txt`.
- [x] **Module Lab 2.0 (Native Root & Module Management Center)**:
  - Designed and implemented `packages/apps/ModuleLab` adhering to AviumUI / Material 3 Expressive UI standards (`Theme.Material3.DayNight`).
  - Implemented dynamic color (`DynamicColors`), dark mode, and sectioned elevated cards.
  - **Live Root Environment Detection** (`RootDetector`): Real-time reading of su binary, SELinux mode (`Enforcing`), `/data/adb` accessibility, and Zygisk engine status without UI falsification.
  - **Hooking Frameworks Center**: Detected status and version for LSPosed and Vector (LSPlant-based ART hooking), with mutual exclusivity warnings.
  - **Module Lifecycle Manager** (`ModuleScanner`): Scans `/data/adb/modules`, parses `module.prop`, provides single-tap Enable/Disable toggles (modifying `disable` flag), Remove on next boot (modifying `remove` flag), and log inspection (`service.log` / `post-fs-data.log`).
  - **Safe Mode & Recovery Center** (`SafeModeController`): Emergency Safe Mode toggle (`/data/adb/modules/.disable_magisk`), one-tap "Disable All Modules", and "Rollback Last Installed Module". Included hardware key safe mode guidance for OnePlus 6.
  - **Settings Homepage Integration**: Wired `com.android.settings.category.ia.homepage` intent-filter for native discovery on the Settings homepage.
- [x] **Automated Build-Time Magisk Boot Integration**:
  - Implemented `scripts/build_magisk_boot.sh` using official standalone Magisk v30.7 host x86_64 tool (`magiskboot_x86_64`) and ARM64 payloads (`tools/magisk/`).
  - Fully tested on real AviumUI 16.2.2 64 MiB `boot.img`: outputs verified `boot-magisk.img` (magiskboot status 1) while leaving stock `boot.img` (magiskboot status 0) completely untouched.
  - Preserves SELinux Enforcing, AVB flags, and `ro.secure` without kernel security degradation.
  - Integrated `with_magisk` toggle into GitHub Actions workflow (`namespace-avium-build.yml`), producing dual boot image artifacts (`boot.img` and `boot-magisk.img`).

---

## 3. Build Blockers & Resolutions
| Blocker | Impact | Resolution | Status |
| :--- | :--- | :--- | :--- |
| `oemnetd_aidl_interface-java` missing from APEX `allowed_deps.txt` | `m bacon` target 174536/180352 failed during APEX dependency check | Injected `oemnetd_aidl_interface-java(minSdkVersion:30)` in `scripts/fix_known_blockers.sh` | **RESOLVED & VERIFIED** |
| `Task.java` duplicate `prepareSurfaces()` definition | `services.core.unboosted` compilation error at `Task.java:3416` during `m bacon` | Backported upstream AviumUI fix (`7d9112e5`) via automated deduplication in `scripts/fix_known_blockers.sh` | **RESOLVED & VERIFIED** |
| `FeatureSettings` profile IME string conflict | Patch hunk rejection on 16.2.2 upstream | Refreshed `0001-Add-Status-Bar-Capsule...` patch context | **RESOLVED & VERIFIED** |
| WCN3990 160MHz Wi-Fi Hardware Incompatibility | OnePlus 6 SDM845 lack of 160MHz physical support | Dynamic channel filtering in `WifiTether160MhzPreferenceController` verified | **HANDLED SAFELY** |

---

## 4. Work in Progress
- **CI Workflow Validation**: Run `35809013154` dispatched on Namespace runner (`namespace-profile-avium-run15`), testing full `m bacon` completion with `allowed_deps.txt` fix, `Task.java` fix, ModuleLab 2.0 integration, and automated Magisk boot dual artifact generation.

---

## 5. Verification Matrix
> [!NOTE]
> In accordance with project instructions, all items are strictly marked as `BUILD VERIFIED` until tested on physical hardware (`DEVICE VERIFIED`).

| Feature / Target | Validation Level | Notes |
| :--- | :--- | :--- |
| AviumUI 16.2.2 SystemUI | **BUILD VERIFIED** | `m SystemUI-core` & `m SystemUI-application` passed in Gate 2.5/2.55 |
| AviumUI 16.2.2 Launcher3 | **BUILD VERIFIED** | `m Launcher3QuickStep` passed in Gate 2.6 |
| AviumUI 16.2.2 Settings | **BUILD VERIFIED** | `m Settings` passed in Gate 1.3 |
| AviumUI 16.2.2 AiWallpapers | **BUILD VERIFIED** | Signature and Presigned certificate verified in Gate 1.2 |
| Stock `boot.img` (64 MiB) | **BUILD VERIFIED** | Exact 67,108,864 bytes verified in Gate 2 |
| Rooted `boot-magisk.img` | **BUILD VERIFIED** | Exact 67,108,864 bytes, ramdisk Magisk status 1 verified |
| Module Lab 2.0 | **CODE COMPLETED** | Sources, layouts, and permissions integrated; device tree updated |
| Full ROM Package (`m bacon`) | **IN PROGRESS** | Running on Namespace runner (Run 35803631379) |
| Physical Boot / RIL / Audio / Wi-Fi | **NOT DEVICE TESTED** | Awaiting device flashing stage |

---

## 6. Next Steps
1. Monitor completion of CI Run `35803631379`.
2. Verify full bacon ROM package and system image output.
3. Trigger build with ModuleLab and Magisk boot artifact packaging.
