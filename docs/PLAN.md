# AviumUI 16.2 (Android 16 QPR2) Bring-up Plan

This document outlines the systematic engineering roadmap for bringing up **AviumUI 16.2 (Android 16 QPR2)** on the **OnePlus 6 (`enchilada`)**, spanning from early infrastructure readiness to daily-driver verification.

---

## 🗺️ 7-Stage Bring-up Roadmap

```mermaid
graph TD
    S1[1. Infrastructure] --> S2[2. Source Validation]
    S2 --> S3[3. First Build - Vanilla]
    S3 --> S4[4. Boot Bring-up]
    S4 --> S5[5. Hardware Validation Matrix]
    S5 --> S6[6. AviumUI Feature Validation]
    S6 --> S7[7. Daily-Driver Polish]
```

### Stage 1: Infrastructure
* [x] Set up the `aviumui-enchilada` Git orchestration skeleton.
* [x] Establish upstream source tracking matrix ([SOURCES.md](SOURCES.md)).
* [ ] Provision and authenticate Crave.io cloud build environment.
* [ ] Prepare local manifest injection scripts and dev keys handling.

### Stage 2: Source Validation
* [ ] Fetch AviumUI `avium-16.2` base manifest snippets and inspect remote definitions.
* [ ] Validate `local_manifests/enchilada.xml` against base manifest to eliminate conflicting/duplicate projects.
* [ ] Align LineageOS 23.2 device trees (`device/oneplus/enchilada`, `device/oneplus/sdm845-common`, `kernel/oneplus/sdm845`, `hardware/oneplus`).
* [ ] Verify proprietary vendor blob branch availability in TheMuppets repositories.
* [ ] Audit Android 16 QPR2 build flag deprecations and BoardConfig compatibility.

### Stage 3: First Build (Vanilla Target)
* [ ] Configure build environment for `avium_enchilada-userdebug` (or `lineage_enchilada-userdebug`).
* [ ] Execute initial cloud compilation on Crave.io with vanilla profile (no GMS).
* [ ] Debug and resolve Soong / Blueprint / Make build-time breakages.
* [ ] Resolve HIDL / AIDL interface mismatches and missing library dependencies.
* [ ] Produce initial flashable output: `boot.img`, `dtbo.img`, `system.img`, `vendor.img`, and full ROM zip.

### Stage 4: Boot Bring-up
* [ ] Flash image artifacts to test OnePlus 6 device via fastboot / recovery.
* [ ] Verify early kernel UART / ramoops / pmsg logs (`/dev/pmsg0` / `/sys/fs/pstore`).
* [ ] Bring up Android init and verify vendor/system partition mounting.
* [ ] Achieve functional ADB (`adbd`) over USB during early boot.
* [ ] Bring up SurfaceFlinger, DRM/KMS graphics drivers, and basic touch input.
* [ ] Reach Android boot animation and initialize `Zygote` / `SystemServer`.

### Stage 5: Hardware Validation
Systematic validation of hardware subsystems against the test matrix below.

### Stage 6: AviumUI Feature Validation
* [ ] Validate AviumUI Monet theme engine and real-time GPU background blur on SDM845 Adreno 630.
* [ ] Verify AviumUI Lockscreen architecture, dynamic clock customization, and widgets.
* [ ] Test lightweight floating / freeform multi-window functionality.
* [ ] Verify AviumUI smart sidebar and quick access drawers.
* [ ] Test Avium Launcher desktop features, gesture navigation, and task switcher fluidity.

### Stage 7: Daily-Driver Polish
* [ ] Optimize battery drain during deep sleep (suspend / wakeup alarms / PMIC).
* [ ] Tune thermal management (`thermal-engine` / cpu frequency governor profiles).
* [ ] Enforce full SELinux policy (`enforcing` mode validation without policy denials).
* [ ] Clean up redundant debug flags and finalize release packaging.

---

## 🧪 Comprehensive Hardware & Subsystem Test Matrix

| Category | Component / Feature | Test Description | Target Status |
| :--- | :--- | :--- | :---: |
| **Core System** | **Boot & Recovery** | Cold boot, reboot, recovery boot, fastbootd | ⏳ Pending |
| **Core System** | **ADB & Fastboot** | USB debugging, root shell, file push/pull | ⏳ Pending |
| **Core System** | **Storage & Encryption** | FBE (File-Based Encryption) v2, userdata mount | ⏳ Pending |
| **Core System** | **SELinux** | Permissive boot -> clean Enforcing without denials | ⏳ Pending |
| **Core System** | **Suspend & Power** | Deep sleep, idle battery drain (<1%/h), charging | ⏳ Pending |
| **Display & Input** | **Display** | Refresh rate, brightness slider, night light | ⏳ Pending |
| **Display & Input** | **Touchscreen** | Multi-touch, edge gestures, tap-to-wake (DT2W) | ⏳ Pending |
| **Connectivity** | **Wi-Fi** | 2.4 GHz & 5 GHz bands, WPA3, hotspot tethering | ⏳ Pending |
| **Connectivity** | **Bluetooth** | A2DP audio streaming, BLE peripherals, pairing | ⏳ Pending |
| **Connectivity** | **NFC** | Card emulation, tag reading, contact sharing | ⏳ Pending |
| **Connectivity** | **GPS / Location** | GNSS fix (GPS, GLONASS, Galileo, BeiDou) | ⏳ Pending |
| **Telephony** | **RIL / Mobile Data** | SIM card detection, 4G LTE data throughput | ⏳ Pending |
| **Telephony** | **Calls & SMS** | CS/PS voice calls, SMS sending & reception | ⏳ Pending |
| **Telephony** | **IMS / VoLTE** | HD voice over LTE, VoWiFi registration | ⏳ Pending |
| **Audio** | **Audio Subsystem** | Speaker, earpiece, 3.5mm jack, dual mic routing | ⏳ Pending |
| **Media & Imaging** | **Camera** | Front & rear photo capture, 4K video, flashlight | ⏳ Pending |
| **Biometrics** | **Fingerprint** | Sensor enrollment, lockscreen match, sleep wake | ⏳ Pending |
| **Sensors** | **Sensor Array** | Accelerometer, Gyroscope, Proximity, Ambient Light, Compass, Hall sensor | ⏳ Pending |
| **AviumUI UI/UX** | **AviumUI Blur** | GPU blur rendering performance & stability | ⏳ Pending |
| **AviumUI UI/UX** | **Lockscreen** | Custom clock fonts, lockscreen widgets | ⏳ Pending |
| **AviumUI UI/UX** | **Lightweight Windows** | Freeform window resizing, drag & drop, PiP | ⏳ Pending |
| **AviumUI UI/UX** | **Sidebar** | Quick tool drawer activation, app shortcuts | ⏳ Pending |
| **AviumUI UI/UX** | **Launcher** | Gesture responsiveness, app search, app drawer | ⏳ Pending |

---

## 📊 Status Legend
* ⏳ **Pending**: Planned, awaiting build / device testing.
* 🟡 **In Progress**: Under active investigation or debugging.
* 🟢 **Verified**: Tested and functional without regressions.
* 🔴 **Blocked**: Known regression or upstream limitation identified.
