#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

TARGET_MD="$OUT_DIR/RUNTIME-POWER-TEST.md"

cat << 'EOF' > "$TARGET_MD"
# AviumUI 16.2.1 三阶段真机功耗专项测试方案

本文档为 OnePlus 6 (enchilada) 在 AviumUI 16.2.1 上的三阶段功耗诊断执行规程。
通过隔离变量，分别测试：**纯深休眠底噪**、**纯屏幕渲染底噪**、**导航多射频高负载场景**。

---

## 准备工作
1. 确保电脑已连接手机并授权 ADB。
2. 赋予脚本执行权限：
   ```bash
   chmod +x ./avium-runtime-power-capture.sh
   chmod +x ./avium-charge-test.sh
   ```

---

## 测试 A：纯熄屏待机（Deep Sleep 基线）
- **测试目的**：排除是否存在后台持续唤醒、无法进入 Suspend-to-RAM 的常驻唤醒锁。
- **持续时间**：30 分钟。
- **环境要求**：
  1. 充至 100% 电量后拔掉 USB 数据线。
  2. 关闭所有后台第三方应用，关闭 GPS 开关，Wi-Fi 保持连接。
  3. 执行基线重置：
     ```bash
     adb shell dumpsys batterystats --reset
     ```
  4. 按电源键熄屏，手机静置在桌面上 30 分钟，期间严禁点亮屏幕。
- **采集数据**：
  30 分钟结束后，插上 USB 数据线立即执行：
  ```bash
  ./avium-runtime-power-capture.sh idle
  ```
- **预期结果**：30 分钟掉电 ≤ 1%，Deep Sleep 时间占比 ≥ 90%。

---

## 测试 B：纯亮屏静止（Display & GPU 基线）
- **测试目的**：测量 AMOLED 屏幕与 Launcher 基础渲染的纯静态功耗，排除是否有隐形持续重绘。
- **持续时间**：30 分钟。
- **环境要求**：
  1. 拔掉 USB 数据线。
  2. 屏幕亮度固定在 35% ~ 50%（关闭自动亮度）。
  3. 停留在系统默认桌面，不滑动、不点击。
  4. 执行基线重置：
     ```bash
     adb shell dumpsys batterystats --reset
     ```
  5. 保持屏幕常亮（可在开发者选项中勾选“充电时不锁定屏幕”，或在显示设置中设为最长超时）。
- **采集数据**：
  30 分钟结束后立即执行：
  ```bash
  ./avium-runtime-power-capture.sh screen-on
  ```
- **预期结果**：30 分钟掉电约 3% ~ 5%（整机功率约 1.2W ~ 1.5W）。

---

## 测试 C：导航 + 音乐（复合高负载复现）
- **测试目的**：复现用户真实掉电场景（85% -> 36% / 40分钟），精确定位耗电大户。
- **持续时间**：40 分钟。
- **环境要求**：
  1. 拔掉数据线，电量在 80% 以上。
  2. 开启高德地图 / 百度地图实际导航（或模拟导航路线）。
  3. 开启音乐播放并通过蓝牙耳机或蓝牙音箱收听。
  4. 开启 4G 移动数据（关闭 Wi-Fi 以模拟真实出行场景）。
  5. 执行基线重置：
     ```bash
     adb shell dumpsys batterystats --reset
     ```
  6. 持续导航 + 听歌 40 分钟。
- **采集数据**：
  40 分钟结束后立即连上电脑执行：
  ```bash
  ./avium-runtime-power-capture.sh navigation-music
  ```

---

## 数据分析指南
执行完毕后，分析三组目录：
- `power_dumps/idle/dumpsys_batterystats.txt` -> 检查 `Total run time` vs `Screen off time` vs `Wake lock time`。
- `power_dumps/navigation-music/dumpsys_batterystats.txt` -> 检查：
  - `Cellular radio active time`
  - `GPS active time`
  - `Uid u0a...: (top consumers)`
  - `Screen on time & discharge rate`
EOF

echo "Generated $TARGET_MD successfully."
