# uwuAOSP 16.2 for OnePlus 6 (enchilada) Engineering Progress

## 1. Project Overview & Current Status
- **Target OS**: uwuAOSP 16.2 (Android 16 QPR2 / `uwu-16.2`)
- **Target Device**: OnePlus 6 (`enchilada`) / Qualcomm Snapdragon 845 (SDM845)
- **Kernel Baseline**: Linux 4.19.325 Golden Baseline (KernelSU strictly absent)
- **Partition Layout**: Physical Legacy A/B (No Super, No Retrofit Dynamic Partitions, `BOARD_USES_RECOVERY_AS_BOOT := true`)
- **CI / Build Runner**: NameSpace GitHub Actions Runner (`namespace-profile-avium-run15`)
- **Control Repository**: [ColoMovo-Labs/aviumui-enchilada](https://github.com/ColoMovo-Labs/aviumui-enchilada)
- **Workflow Pipeline**: `.github/workflows/namespace-uwu-build.yml`
- **Current Milestone**: P0 Compilation Resolution — Clean uwuAOSP 16.2 Baseline Build

---

## 2. Phase Execution Matrix
| Phase | Goal | Status | Verification Level |
| :--- | :--- | :--- | :--- |
| **P0** | Clean uwuAOSP 16.2 enchilada compilation (`m uwu`) | **IN PROGRESS** | Blockers identified & patched |
| **P1** | Establish clean baseline checkpoint commit | **PENDING P0** | Awaiting green build |
| **P2** | Analyze uwuAOSP existing clock framework (`vendor/pixel/clocks`, `uwuClocks`) | **MAPPED** | Repositories & components identified |
| **P3** | Locate AviumUI "万象时钟" complete implementation across repos | **PENDING** | Next after P1 |
| **P4** | Port clock styles cleanly into uwuAOSP clock framework | **PENDING** | Next after P3 |
| **P5** | Build verification for integrated clocks | **PENDING** | Next after P4 |
| **P6** | Locate AviumUI Depth Wallpaper (景深壁纸) implementation | **PENDING** | Next after P5 |
| **P7** | Implement clean depth wallpaper with proper caching and fallback | **PENDING** | Next after P6 |
| **P8** | Snapdragon 845 performance optimization & safe AOD decoupling | **PENDING** | Next after P7 |
| **P9** | Full ROM package compilation (`m uwu`) | **PENDING** | Next after P8 |
| **P10** | Organize upstream-ready commits, credits, and licenses | **PENDING** | Next after P9 |
| **P11** | User decision for real physical device testing | **PENDING** | Device flashing stage |

---

## 3. Build Blockers & Resolutions
| Blocker | Impact | Root Cause | Resolution | Status |
| :--- | :--- | :--- | :--- | :--- |
| `PickupSensor.kt:43:30: error: unresolved reference 'wakeUpWithProximityCheck'` | `m uwu` failed at 44% (target 80877/182841) | `hardware/oneplus/packages/Doze` invokes LineageOS-proprietary `powerManager.wakeUpWithProximityCheck(...)`, which does not exist in standard AOSP / uwuAOSP `PowerManager`. | Created `patches/hardware_oneplus/0001-Doze-adapt-PickupSensor-wakeUp-for-uwuAOSP.patch` and programmatic regex replacement in `scripts/fix_known_blockers.sh` to use official `powerManager.wakeUp(SystemClock.uptimeMillis(), PowerManager.WAKE_REASON_GESTURE, TAG)`. | **RESOLVED & VERIFIED LOCALLY** |
| Dynamic Super / Retrofit Partitions | Boot failure on physical legacy A/B partition layout | Default generic target enables dynamic partitions | Enforced `BOARD_SUPER_PARTITION_SIZE := 0`, empty `PRODUCT_USE_DYNAMIC_PARTITIONS`, and verified pure physical partitions in `BoardConfigCommon.mk`. | **VERIFIED PASSING** (Gates 8 & 9) |
| APEX Allowed Dependencies Check | Ninja failure during APEX package generation | Upstream APEX dependency check requires all newly introduced AIDL interfaces in `allowed_deps.txt` | Pre-generation sync of `new-allowed-deps.txt` into `allowed_deps.txt` before full `m uwu`. | **VERIFIED PASSING** |

---

## 4. Build Gate Status (Run `35843018111`)
| Gate | Target | Status | Notes |
| :--- | :--- | :--- | :--- |
| Gate 1 | `m nothing` | **PASS** | Soong / Ninja graph generation valid |
| Gate 1.2 | `m AiWallpapers` | **PASS** | Built and presigned successfully |
| Gate 1.3 | `m Settings` | **PASS** | Settings app compiled cleanly |
| Gate 2 | `m bootimage` | **PASS** | Pure 4.19 Linux kernel boot.img (64 MiB) generated |
| Gate 2.5 | `m SystemUI-core` | **PASS** | SystemUI core framework compiled cleanly |
| Gate 2.6 | `m Launcher3` | **PASS** | Launcher3QuickStep compiled cleanly |
| Gate 3 | `m uwu` | **FAILED (44%)** | Blocker: `PickupSensor.kt` unresolved `wakeUpWithProximityCheck`. Patched for next run. |

---

## 5. Verification Matrix
> [!NOTE]
> All build artifacts and components are strictly marked as `BUILD VERIFIED` upon successful compilation until tested on physical hardware (`DEVICE VERIFIED`).

| Component | Validation Level | Notes |
| :--- | :--- | :--- |
| uwuAOSP 16.2 SystemUI | **BUILD VERIFIED** | `m SystemUI-core` passed |
| uwuAOSP 16.2 Launcher3 | **BUILD VERIFIED** | `m Launcher3` passed |
| uwuAOSP 16.2 Settings | **BUILD VERIFIED** | `m Settings` passed |
| Stock `boot.img` (64 MiB) | **BUILD VERIFIED** | Linux 4.19.325 Golden Baseline verified |
| Full ROM Package (`m uwu`) | **IN PROGRESS** | Triggering verification build with `PickupSensor` fix |
| Physical Hardware (Wi-Fi, RIL, Audio, Depth Wallpaper) | **NOT DEVICE TESTED** | Strictly awaiting hardware flashing phase |

---

## 6. Next Steps
1. Commit and push the `hardware/oneplus` Doze `PickupSensor` fix to `ColoMovo-Labs/aviumui-enchilada`.
2. Dispatch workflow `namespace-uwu-build.yml` via GitHub Actions on NameSpace Runner.
3. Monitor Phase Gate 3 (`m uwu`) to full package completion (`uwuAOSP_enchilada-*.zip`).
4. Establish clean baseline git checkpoint commit.
5. Begin Phase P2/P3 clock framework analysis.
