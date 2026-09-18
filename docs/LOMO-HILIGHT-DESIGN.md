# LoMo HiLight Architecture & Engineering Design

> **Target Device**: OnePlus 6 (`enchilada` / Snapdragon 845)  
> **Feature Name**: `LoMo HiLight`  
> **Inspiration**: Pixel Gemini HiLight  
> **Hardware Interface**: OnePlus 6 Front-Facing RGB Notification LED (`android.hardware.light-service.lineage`)  
> **System Service**: `org.lomolab.settings.hilight.HiLightService`

---

## 1. Hardware Abstraction & LED Architecture

The OnePlus 6 hardware incorporates a multi-color RGB LED indicator mapped via `android.hardware.light-service.lineage` (AIDL `android.hardware.lights`).
- **Zero Raw Sysfs Guessing**: Direct access to `/sys/class/leds` is bypassed in favor of Android's official `android.hardware.lights.LightsManager` API (API level 31+).
- **Session Arbitration via `LightsSession`**:
  ```kotlin
  val lightsManager = context.getSystemService(LightsManager::class.java)
  val session = lightsManager.openSession()
  val request = LightsRequest.Builder()
      .addLight(targetLight, LightState.Builder().setColor(color).build())
      .build()
  session.requestLights(request)
  ```
- **State Restoration Guarantee**:
  Closing the `LightsSession` (`session.close()`) automatically instructs `LightsService` in Android framework to release hardware arbitration and seamlessly restore prior system light states (battery charging, low-battery alerts, unread system notifications).

---

## 2. Dynamic Assistant Detection (No Hardcoding)

LoMo HiLight does NOT hardcode any specific Assistant package name (such as `com.google.android.apps.googleassistant` or `com.google.android.googlequicksearchbox`).
Instead, it dynamically discovers the active assistant via Android's `RoleManager`:
```kotlin
val roleManager = context.getSystemService(RoleManager::class.java)
val holders = roleManager?.getRoleHolders(RoleManager.ROLE_ASSISTANT)
val assistantPackage = holders?.firstOrNull()
val assistantUid = context.packageManager.getPackageUid(assistantPackage, 0)
```
Fallback is handled via `Settings.Secure.ASSISTANT`. This ensures complete compatibility with Google Gemini, Google Assistant, or any user-selected assistant application.

---

## 3. Four-State Reactive Lifecycle

```
             +-----------------------+
             |         IDLE          |
             |  (LED System Restored)|
             +-----------+-----------+
                         | Assistant Recording Started
                         v
             +-----------------------+
             |       LISTENING       | <---+
             |    (Cyan #00FFFF)     |     |
             +-----------+-----------+     |
                         | Assistant Recording Stopped
                         v                 |
             +-----------------------+     |
             |       THINKING        |     | Assistant Recording Resumed
             |    (Purple #9C27B0)   | ----+
             +-----------+-----------+
                         |
       +-----------------+-----------------+
       | Playback Started                  | 10s Timeout Expired
       v                                   v
+-----------------------+        +-----------------------+
|      RESPONDING       |        |         IDLE          |
|    (Blue #2979FF)     |        |  (LED System Restored)|
+-----------+-----------+        +-----------------------+
            | Playback Stopped
            v
+-----------------------+
|         IDLE          |
|  (LED System Restored)|
+-----------------------+
```

1. **IDLE**:
   Lights session is closed (`session?.close()`). System maintains native notification/charging ownership.
2. **LISTENING**:
   Detected via `AudioManager.AudioRecordingCallback`. When the Assistant's UID is actively recording audio through the microphone, the LED is illuminated in **Cyan** (`0xFF00FFFF`).
3. **THINKING**:
   When recording stops while the query is being processed, a finite 10-second timeout timer is started. The LED pulses in **Purple** (`0xFF9C27B0`).
4. **RESPONDING**:
   Detected via `AudioManager.AudioPlaybackCallback`. When the Assistant's UID begins audio playback (voice response), the thinking timeout is cancelled and the LED illuminates in **Blue** (`0xFF2979FF`).
   Upon playback completion, the state transitions back to **IDLE**, closing the lights session and restoring default system light behavior.

---

## 4. Power & Thermal Constraints Compliance

- **Zero While-Loops / Zero Polling**: No `while(true)`, no periodic polling Handler tasks. Callbacks are invoked purely on framework audio hardware events (`onRecordingConfigChanged`, `onPlaybackConfigChanged`).
- **Zero Persistent Wakelocks**: Neither `WAKE_LOCK` nor `PARTIAL_WAKE_LOCK` is held during operation. The system remains fully eligible for Linux kernel deep suspend (suspend-to-RAM).
- **Screen-Off Optimization (`lomolab_hilight_screen_off_only`)**:
  When enabled, queries `PowerManager.isInteractive()`. If the screen is active, LED indication is suppressed to conserve energy.
- **Charging Protection (`lomolab_hilight_disable_charging`)**:
  Monitors `ACTION_BATTERY_CHANGED`. When charging or fully charged, HiLight yields priority to hardware charging indicators.

---

## 5. Hardware Diagnostic Self-Test

In LoMoLab -> **Gemini & HiLight**, users can test the physical LED across 6 distinct spectra:
- Red (`0xFFFF0000`)
- Green (`0xFF00FF00`)
- Blue (`0xFF0000FF`)
- Cyan (`0xFF00FFFF`)
- Purple (`0xFF9C27B0`)
- White (`0xFFFFFFFF`)

Upon selection, the test lights the LED for exactly 2500ms, then immediately calls `clearLed()`, ensuring the test leaves zero dangling states or residual session locks.
