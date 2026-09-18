# LoMo HiLight Architecture & Engineering Design

> **Target Device**: OnePlus 6 (`enchilada` / Snapdragon 845)  
> **Feature Name**: `LoMo HiLight`  
> **Inspiration**: Pixel Gemini HiLight  
> **Hardware Interface**: OnePlus 6 Front-Facing RGB Notification LED (`android.hardware.light-service.lineage`)  
> **System Server Backend**: `com.android.server.statusbar.StatusBarManagerService` + `com.android.server.lights.LightsManager.LIGHT_ID_NOTIFICATIONS`  
> **SystemUI Controller**: `org.avium.systemui.hilight.LoMoHiLightController`  
> **Settings Hub**: `packages/apps/LoMoLab` (`org.lomolab.settings.GeminiHiLightFragment`)

---

## 1. Hardware Abstraction & Real Light Backend

The OnePlus 6 hardware incorporates a front-facing multi-color RGB LED indicator driven by Qualcomm SoC PWM / PMIC channels. In Android 16 QPR2 / LineageOS 23.2, this is abstracted via `android.hardware.light-service.lineage` implementing the AIDL `android.hardware.light.ILights` HAL.

### The System Light Reservation in Android
In Android framework (`core/java/android/hardware/lights/` and `services/core/java/com/android/server/lights/`):
- Light types `0` through `7` are strictly reserved for system server use:
  - `LIGHT_ID_BACKLIGHT = 0`
  - `LIGHT_ID_KEYBOARD = 1`
  - `LIGHT_ID_BUTTONS = 2`
  - `LIGHT_ID_BATTERY = 3`
  - `LIGHT_ID_NOTIFICATIONS = 4` (Physical RGB Notification LED on OnePlus 6)
  - `LIGHT_ID_ATTENTION = 5`
  - `LIGHT_ID_BLUETOOTH = 6`
  - `LIGHT_ID_WIFI = 7`
- Android's public `android.hardware.lights.LightsManager.getLights()` and `setLightStates()` explicitly filter out system lights (`isSystemLight()` where `0 <= type < 8`). Attempting to access or control system lights from application space throws `IllegalStateException` or fails `checkRequestIsValid`.
- Therefore, the notification LED is exclusively owned in `system_server` via `com.android.server.lights.LightsManager.getLight(LightsManager.LIGHT_ID_NOTIFICATIONS)`.

---

## 2. Decoupled Multi-Layer Architecture

To maintain strict security boundaries and follow AOSP conventions, LoMo HiLight is decoupled across three layers:

```text
+-------------------------------------------------------------------+
|                        LoMoLab (Settings UI)                      |
|  - Packages: apps/LoMoLab                                         |
|  - Pure settings UI; writes to Settings.System lomolab_hilight_* |
|  - Zero hardware light access, zero background services           |
+---------------------------------+---------------------------------+
                                  | ContentObserver
                                  v
+-------------------------------------------------------------------+
|                   SystemUI (LoMoHiLightController)                |
|  - Packages: SystemUI/src/org/avium/systemui/hilight/             |
|  - Event-driven AudioRecordingCallback & AudioPlaybackCallback    |
|  - Dynamic RoleManager.ROLE_ASSISTANT detection                   |
|  - State machine: IDLE -> LISTENING -> THINKING -> RESPONDING     |
+---------------------------------+---------------------------------+
                                  | IStatusBarService.setHiLightState()
                                  | (Protected by STATUS_BAR_SERVICE)
                                  v
+-------------------------------------------------------------------+
|               system_server (StatusBarManagerService)             |
|  - LocalServices.getService(LightsManager.class)                 |
|  - LogicalLight: lm.getLight(LIGHT_ID_NOTIFICATIONS)              |
|  - Drives hardware RGB LED: setColor() / setFlashing() / turnOff()|
+---------------------------------+---------------------------------+
                                  | AIDL
                                  v
+-------------------------------------------------------------------+
|          android.hardware.light-service.lineage (HAL)            |
|  - /sys/class/leds/red, green, blue                               |
+-------------------------------------------------------------------+
```

### 2.1 LoMoLab (Application Layer)
- **Role**: Solely responsible for presentation, user preference management, and color selection.
- **Persistence**: Writes configuration to `Settings.System`:
  - `lomolab_hilight_enabled` (0/1)
  - `lomolab_hilight_listening_enabled` (0/1)
  - `lomolab_hilight_thinking_enabled` (0/1)
  - `lomolab_hilight_responding_enabled` (0/1)
  - `lomolab_hilight_screen_off_only` (0/1)
  - `lomolab_hilight_disable_charging` (0/1)
  - `lomolab_hilight_test_trigger` (timestamp)
  - `lomolab_hilight_test_color` (hex RGB int)
- **Zero Privileged Light Ownership**: Contains no light services, no `android.permission.CONTROL_DEVICE_LIGHTS`, and no direct HAL interaction.

### 2.2 Framework IPC Bridge (`IStatusBarService`)
- Added to `com.android.internal.statusbar.IStatusBarService.aidl`:
  ```aidl
  /** Controls hardware notification LED state for LoMo HiLight assistant interactions */
  void setHiLightState(int color, int mode, int onMs, int offMs);
  ```
- Implemented in `com.android.server.statusbar.StatusBarManagerService.java`:
  ```java
  @Override
  public void setHiLightState(int color, int mode, int onMs, int offMs) {
      enforceStatusBar();
      com.android.server.lights.LightsManager lm =
              com.android.server.LocalServices.getService(com.android.server.lights.LightsManager.class);
      if (lm != null) {
          com.android.server.lights.LogicalLight light =
                  lm.getLight(com.android.server.lights.LightsManager.LIGHT_ID_NOTIFICATIONS);
          if (light != null) {
              if (color == 0) {
                  light.turnOff();
              } else if (mode == 0) {
                  light.setColor(color);
              } else {
                  light.setFlashing(color, mode, onMs, offMs);
              }
          }
      }
  }
  ```
- **Security Guarantee**: Guarded by `enforceStatusBar()`. Standard user applications cannot call this method; only system components holding `android.permission.STATUS_BAR` (SystemUI) can invoke it.

### 2.3 SystemUI Controller (`LoMoHiLightController`)
- Located in `packages/SystemUI/src/org/avium/systemui/hilight/LoMoHiLightController.kt`.
- Initialized on SystemUI boot during `IslandController.start()`.
- Uses `IStatusBarService.Stub.asInterface(ServiceManager.getService(Context.STATUS_BAR_SERVICE))` to drive the hardware LED.

---

## 3. Dynamic Assistant Detection

LoMo HiLight does NOT hardcode any specific package name. Instead, it dynamically discovers the active assistant via Android's `RoleManager`:
```kotlin
val roleManager = context.getSystemService(RoleManager::class.java)
val holders = roleManager?.getRoleHolders(RoleManager.ROLE_ASSISTANT)
val assistantPackage = holders?.firstOrNull()
val assistantUid = context.packageManager.getPackageUid(assistantPackage, 0)
```
This guarantees seamless out-of-the-box compatibility with Google Gemini, Google Assistant, or any custom voice assistant installed by the user.

---

## 4. State Machine & Event Handling

```
             +-----------------------+
             |         IDLE          |
             |       (LED Off)       |
             +-----------+-----------+
                         | Assistant Audio Recording Started
                         v
             +-----------------------+
             |       LISTENING       | <---+
             |    (Cyan #00FFFF)     |     |
             +-----------+-----------+     |
                         | Assistant Audio Recording Stopped
                         v                 |
             +-----------------------+     |
             |       THINKING        |     | Recording Resumed
             |    (Purple #9C27B0)   | ----+
             +-----------+-----------+
                         | Audio Playback Started
                         v
             +-----------------------+
             |      RESPONDING       |
             |    (Blue #2979FF)     |
             +-----------+-----------+
                         | Audio Playback Stopped
                         v
             +-----------------------+
             |         IDLE          |
             |       (LED Off)       |
             +-----------------------+
```

1. **IDLE**: `setHiLightState(0, 0, 0, 0)`. The hardware LED is turned off and ownership is yielded back to system notification/battery indicators.
2. **LISTENING**: Triggered by `AudioManager.AudioRecordingCallback`. When the Assistant's UID begins microphone recording, the LED pulses in **Cyan** (`#00FFFF`).
3. **THINKING**: When microphone recording finishes but playback has not begun, the LED pulses in **Purple** (`#9C27B0`).
4. **RESPONDING**: Triggered by `AudioManager.AudioPlaybackCallback`. When the Assistant's UID begins audio playback, the LED illuminates steady in **Blue** (`#2979FF`).
5. Upon playback completion, transitions cleanly to **IDLE**, invoking `light.turnOff()`.

---

## 5. Power & Thermal Compliance

- **Zero While-Loops & Zero Polling**: All updates are triggered strictly by framework callbacks (`AudioRecordingCallback`, `AudioPlaybackCallback`, `ContentObserver`, `BroadcastReceiver`).
- **Zero Permanent Wakelocks**: No background wakelocks are held. The device remains fully eligible for Linux kernel deep suspend (suspend-to-RAM).
- **Screen-Off Gating (`lomolab_hilight_screen_off_only`)**: When enabled, checks `PowerManager.isInteractive()`. If the screen is on, LED illumination is suppressed.
- **Charging Priority (`lomolab_hilight_disable_charging`)**: When enabled and `BatteryManager.BATTERY_STATUS_CHARGING` is active, HiLight yields priority to hardware charging indicators.

---

## 6. Diagnostic Self-Test

In LoMoLab -> **Gemini & HiLight**, users can test the physical LED across 6 distinct spectra.
When selected:
1. LoMoLab writes `lomolab_hilight_test_color` and `lomolab_hilight_test_trigger = System.currentTimeMillis()` to `Settings.System`.
2. SystemUI's `ContentObserver` receives the update, sets the LED flashing with the chosen color for exactly 2500ms, and then automatically returns to `IDLE` (`light.turnOff()`).
