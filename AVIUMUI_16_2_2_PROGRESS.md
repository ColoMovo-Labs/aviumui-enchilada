# AviumUI 16.2.2 for OnePlus 6 (enchilada) Engineering Progress

## 1. Current Status
- **Target OS**: AviumUI 16.2.2 (Android 16 QPR2)
- **Target Device**: OnePlus 6 (`enchilada`) / Qualcomm SDM845 Platform
- **Baseline Kernel**: Linux 4.19.325 Golden Baseline (KernelSU absent)
- **Partition Layout**: Physical Legacy A/B (No Super, No Retrofit Dynamic Partitions)
- **Current Milestone**: P0 - Baseline Upgrade & Validation against AviumUI 16.2.2 Upstream
- **CI / Build Runner**: Namespace GitHub Actions Runner (`namespace-profile-avium-run15`)

---

## 2. Completed
- [x] Baseline audit of AviumUI 16.2.1 successful build artifacts and configuration.
- [x] Confirmed GitHub credentials and Namespace CI runner workflow (`namespace-avium-build.yml`).
- [x] Upstream AviumUI 16.2.2 change tracking:
  - `vendor_avium`: Bumped to `AVIUM_PATCH_VERSION := 2` (AviumUI 16.2.2 release tag).
  - `Settings`: Advanced hotspot controls, 160MHz / 5GHz options, per-device data tracking, client block/unblock.
  - `Wifi` / `Connectivity`: Tethering client bandwidth and disconnection support; dual-stack software accounting via `system/netd`.
  - `frameworks_base`: Profile IME sharing for Private Space, App-to-App launch grant permission dialog, Bubble TaskView launch persistence, audio multi-focus playback recovery.
  - `FeatureSettings`: Profile keyboard sharing preference in System category.
- [x] Upstream patch compatibility audit:
  - `Launcher3`: Smooth return-to-home patch verified clean.
  - `vendor_avium`: Version maintainer patch verified clean.
  - `FeatureSettings`: Detected string conflicts due to upstream profile IME additions; prepared clean adaptation.

---

## 3. Build Blockers & Solutions
- **Blocker 1 (Resolved in audit)**: `FeatureSettings` upstream added `profile_ime_*` strings at the end of `strings.xml` and `values-zh-rCN/strings.xml`, causing `0001-Add-Status-Bar-Capsule-and-Super-Island-customizatio.patch` hunk rejection.
  - *Fix*: Rebase/refresh `0001-Add-Status-Bar-Capsule-and-Super-Island-customizatio.patch` with context matching 16.2.2.
- **Hardware Constraint (OnePlus 6 / SDM845)**: 160MHz 5GHz Wi-Fi bandwidth is not physically supported by the WCN3990 Wi-Fi subsystem.
  - *Status*: Verified `WifiTether160MhzPreferenceController` queries `WifiManager.getAllowedChannels(WIFI_BAND_5_GHZ_WITH_DFS, OP_MODE_SAP)` dynamically, disabling the toggle safely without crashing.

---

## 4. Fixed Issues
- None yet in 16.2.2 compilation cycle (audit underway).

---

## 5. Known Issues
- Fingerprint enrollment is limited to a maximum of two fingerprints on hardware (baseline inherited issue; authentication works normally).
- *All features in this release cycle are currently `BUILD VERIFIED` or pending verification, NOT `DEVICE VERIFIED` until flashing on hardware.*

---

## 6. Module Lab 2.0 Progress
- **Architecture Plan**:
  - Independent Material 3 Expressive UI for root environment, modules, LSPosed, and system tweaks.
  - Native discovery of `/data/adb/modules` and `module.prop`.
  - Module state management: Enabled, Disabled, Update available, Needs reboot, Faulty.
  - Status cards: Root Environment (Magisk / KernelSU / APatch detection), Zygisk status, LSPosed status, SELinux mode.
  - Emergency Safe Mode / Recovery mechanism to recover from faulty modules causing bootloops.
- **Current Status**: Initial requirements analysis and UI architecture planning in progress.

---

## 7. Magisk Boot Integration Progress
- **Goal**: ROM build phase generates boot image with integrated Magisk capabilities (keeping `boot.img` and generating `boot-magisk.img`), avoiding manual user boot patching.
- **Research Scope**:
  - ROM post-processing script using official `magiskboot` / `boot_patch.sh` cleanly.
  - Maintain SELinux Enforcing policy without disabling global security.
  - Support build flag (e.g., `WITH_MAGISK := true`).
- **Current Status**: Architectural research in progress.

---

## 8. LSPosed Status
- Investigating Android 16 QPR2 compatibility with modern Zygisk-based LSPosed forks.
- *Status*: Researching upstream hooks and system_server loading. Not device tested.

---

## 9. Vector Status
- Clarifying project reference and Android 16 compatibility.
- *Status*: Preliminary investigation. Not device tested.

---

## 10. Device Testing Status
| Feature / Subsystem | Status | Note |
| :--- | :--- | :--- |
| AviumUI 16.2.2 Build | IN PROGRESS | P0 Compilation verification |
| SystemUI / Super Island | NOT DEVICE TESTED | Build verification in progress |
| Launcher3 | NOT DEVICE TESTED | Build verification in progress |
| Wi-Fi / Hotspot 5GHz | NOT DEVICE TESTED | Dynamic capability check verified |
| Audio / Multi-focus | NOT DEVICE TESTED | Pending build |
| Private Space Main Keyboard | NOT DEVICE TESTED | Upstream feature |
| App Launch Dialog | NOT DEVICE TESTED | Upstream feature |
| Magisk Integration | RESEARCH | P6 Goal |
| Module Lab 2.0 | IN PROGRESS | P2 Goal |

---

## 11. Next Priorities
1. **P0**: Complete patch alignment and trigger full AviumUI 16.2.2 build validation via Namespace CI runner.
2. **P1**: Confirm SystemUI, Launcher, bootimage, and ROM package generation.
3. **P2**: Implement Module Lab 2.0 Material 3 Expressive UI and detection engine.
4. **P3**: Robust `/data/adb/modules` reading, enable/disable/remove support.
5. **P4**: LSPosed status integration.
6. **P5**: Vector project verification.
7. **P6**: Automate Magisk boot patch in build pipeline with dual output (`boot.img` + `boot-magisk.img`).
8. **P7**: Safe Mode / bootloop recovery mechanism.
9. **P8**: Real device regression testing.
