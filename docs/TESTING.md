# Real-Device Hardware & Feature Verification Matrix

This document defines the strict, sequential test protocol to be executed on the physical **OnePlus 6 (`enchilada`)** test device following successful compilation and packaging of Build #1.

---

## 📋 Sequential Test Execution Order

Tests must strictly proceed from early bootloader/kernel validation up through userspace and AviumUI-specific features:

```text
1. Boot/Recovery  ->  2. ADB  ->  3. Display/Touch  ->  4. Encryption  ->  5. Wi-Fi  ->  6. Bluetooth
      ↓
7. SIM/RIL  ->  8. Mobile Data  ->  9. Calls/SMS  ->  10. IMS/VoLTE  ->  11. Audio  ->  12. Camera
      ↓
13. Fingerprint  ->  14. NFC  ->  15. GPS  ->  16. Sensors  ->  17. Suspend  ->  18. Battery Drain
      ↓
19. SELinux  ->  20. AviumUI Blur  ->  21. Lockscreen  ->  22. Lightweight Windows  ->  23. Sidebar  ->  24. Launcher
```

---

## 🧪 Verification Matrix

| # | Test Item | Verification Criteria | Status (`PASS` / `FAIL` / `NOT TESTED`) | Observation & Debug Notes |
| :-: | :--- | :--- | :---: | :--- |
| **01** | **Boot / Recovery** | Device boots kernel, mounts EROFS partitions, boots into recovery (`lineage_recovery`) and System. | `NOT TESTED` | |
| **02** | **ADB** | USB debugging functional via `adb devices`, root shell access via `adb root`. | `NOT TESTED` | |
| **03** | **Display / Touch** | Native 1080x2280 panel refresh, backlight slider, touchscreen multi-touch, DT2W (Double Tap to Wake). | `NOT TESTED` | |
| **04** | **Encryption** | File-Based Encryption (FBE v2) initializes userdata partition cleanly without bootloops. | `NOT TESTED` | |
| **05** | **Wi-Fi** | Connects to 2.4 GHz & 5 GHz IEEE 802.11ac networks, DHCP negotiation, hotspot tethering. | `NOT TESTED` | |
| **06** | **Bluetooth** | Discovers BLE devices, pairs with Bluetooth accessories, A2DP audio streaming functional. | `NOT TESTED` | |
| **07** | **SIM / RIL** | Dual nano-SIM card detection, IMEI recognition, baseband radio communication. | `NOT TESTED` | |
| **08** | **Mobile Data** | 4G LTE data connection establishes, APN auto-configuration, upstream/downstream throughput. | `NOT TESTED` | |
| **09** | **Calls / SMS** | Circuit-Switched (CS) voice calls, SMS dispatch and receipt. | `NOT TESTED` | |
| **10** | **IMS / VoLTE** | IMS registration status `Registered`, HD Voice call established over LTE, VoWiFi handover. | `NOT TESTED` | |
| **11** | **Audio** | Bottom speaker output, earpiece receiver, 3.5mm headphone jack routing, dual microphones. | `NOT TESTED` | |
| **12** | **Camera** | Main 16MP + 20MP rear cameras capture stills and 4K video; 16MP front camera functional. | `NOT TESTED` | |
| **13** | **Fingerprint** | Rear Goodix/FPC capacitive fingerprint enrollment, screen-off unlock authentication. | `NOT TESTED` | |
| **14** | **NFC** | NXP PN553 NFC controller initialization, contactless tag read/write, HCE card emulation. | `NOT TESTED` | |
| **15** | **GPS / Location** | Qualcomm GNSS fix (GPS, GLONASS, Galileo, BeiDou), accurate coordinate lock. | `NOT TESTED` | |
| **16** | **Sensors** | Accelerometer, Gyroscope, Proximity, Light sensor, Compass, Tri-State physical alert slider. | `NOT TESTED` | |
| **17** | **Suspend (Deep Sleep)** | Device enters SoC deep sleep (`lpm_levels`), power collapse verified via `dmesg` / `sysfs`. | `NOT TESTED` | |
| **18** | **Battery Drain** | Standby discharge rate measured over 8 hours (target: `< 1.2% / hour` with Wi-Fi connected). | `NOT TESTED` | |
| **19** | **SELinux** | Transitions from `permissive` to `enforcing` without critical `avc: denied` policy blocks. | `NOT TESTED` | |
| **20** | **AviumUI Blur** | Real-time Adreno 630 GPU background blur rendering in notification shade and volume panel. | `NOT TESTED` | |
| **21** | **Lockscreen** | AviumUI dynamic lockscreen clock typography, shortcuts, and widget rendering. | `NOT TESTED` | |
| **22** | **Lightweight Windows**| Freeform multi-window mode, window drag & resize, Picture-in-Picture (PiP). | `NOT TESTED` | |
| **23** | **Sidebar** | Edge-triggered Avium smart sidebar drawer, app quick shortcuts invocation. | `NOT TESTED` | |
| **24** | **Launcher** | Avium Launcher gesture navigation, app search, fluid task switcher animations. | `NOT TESTED` | |

---

## 📊 Summary Scorecard

* **Total Test Cases**: 24
* **Passed**: 0
* **Failed**: 0
* **Not Tested**: 24
