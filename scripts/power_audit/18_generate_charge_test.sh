#!/bin/bash
set -euo pipefail

SOURCE_ROOT="${1:-/home/runner/android/avium}"
CONTROL_DIR="${2:-$(pwd)}"
OUT_DIR="${3:-/home/runner/android/audit_output}"
mkdir -p "$OUT_DIR"

SCRIPT="$OUT_DIR/avium-charge-test.sh"
GUIDE="$OUT_DIR/CHARGING-TEST.md"

cat << 'EOF' > "$SCRIPT"
#!/bin/bash
# ==============================================================================
# AviumUI 16.2.1 充电采样专用诊断工具 (Strictly Read-Only)
# 采样电池电流、电压、温度、SoC以及USB输入状态
# ==============================================================================

set -u

LABEL="${1:-charge_sample}"
DURATION_SECS="${2:-600}" # 默认采样 10 分钟 (600秒)
INTERVAL_SECS="${3:-5}"   # 默认 5 秒采样一次

OUT_FILE="./power_dumps/${LABEL}_charging_log.csv"
mkdir -p "./power_dumps"

echo "timestamp,soc,current_now_mA,voltage_now_mV,temp_dC,status,charge_counter,usb_type,usb_online" > "$OUT_FILE"

echo "=================================================="
echo "AviumUI 充电采样开始: 标签=$LABEL, 持续=${DURATION_SECS}秒, 间隔=${INTERVAL_SECS}秒"
echo "数据将实时记录至: $OUT_FILE"
echo "=================================================="

START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION_SECS))

while [ $(date +%s) -lt $END_TIME ]; do
    NOW=$(date +%s)
    
    # 采集 battery 节点
    SAMPLE=$(adb shell '
        SOC=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo -1)
        CUR=$(cat /sys/class/power_supply/battery/current_now 2>/dev/null || echo 0)
        VOL=$(cat /sys/class/power_supply/battery/voltage_now 2>/dev/null || echo 0)
        TMP=$(cat /sys/class/power_supply/battery/temp 2>/dev/null || echo 0)
        STA=$(cat /sys/class/power_supply/battery/status 2>/dev/null || echo "Unknown")
        CNT=$(cat /sys/class/power_supply/battery/charge_counter 2>/dev/null || echo 0)
        UTYP=$(cat /sys/class/power_supply/usb/type 2>/dev/null || echo "Unknown")
        UON=$(cat /sys/class/power_supply/usb/online 2>/dev/null || echo 0)
        echo "$SOC,$CUR,$VOL,$TMP,$STA,$CNT,$UTYP,$UON"
    ')

    # 处理单位: current_now 通常是 uA, voltage_now 通常是 uV, temp 通常是 0.1°C
    SOC=$(echo "$SAMPLE" | cut -d',' -f1)
    CUR_RAW=$(echo "$SAMPLE" | cut -d',' -f2)
    VOL_RAW=$(echo "$SAMPLE" | cut -d',' -f3)
    TMP_RAW=$(echo "$SAMPLE" | cut -d',' -f4)
    STA=$(echo "$SAMPLE" | cut -d',' -f5)
    CNT=$(echo "$SAMPLE" | cut -d',' -f6)
    UTYP=$(echo "$SAMPLE" | cut -d',' -f7)
    UON=$(echo "$SAMPLE" | cut -d',' -f8)

    # 换算为 mA 和 mV
    CUR_MA=$((CUR_RAW / 1000))
    VOL_MV=$((VOL_RAW / 1000))

    echo "$NOW,$SOC,$CUR_MA,$VOL_MV,$TMP_RAW,$STA,$CNT,$UTYP,$UON" >> "$OUT_FILE"
    echo "[$LABEL] 电量: ${SOC}%, 电流: ${CUR_MA} mA, 电压: ${VOL_MV} mV, 温度: $((TMP_RAW / 10))°C, 状态: $STA"

    sleep "$INTERVAL_SECS"
done

echo "=================================================="
echo "采样完成！报告文件: $OUT_FILE"
echo "=================================================="
EOF
chmod +x "$SCRIPT"

cat << 'EOF' > "$GUIDE"
# 亮屏与熄屏充电对比诊断指南

本测试用于验证 OnePlus 6 在 AviumUI 16.2.1 下是否存在“亮屏充电极慢，熄屏明显加快”的硬件级 / 策略级约束。

---

## 测试流程

### 第一轮：熄屏充电测试（10 分钟）
1. 将手机电量消耗至约 40% ~ 60%。
2. 插上原装 Dash 充电器或标准快充充电头。
3. 启动采样脚本（后台执行）：
   ```bash
   ./avium-charge-test.sh screen_off 600 5
   ```
4. 立即按电源键关闭屏幕，保持熄屏 10 分钟。
5. 记录这 10 分钟的：
   - 起始与结束电量差（SoC 增长 %）
   - 平均充电电流（mA）

---

### 第二轮：亮屏静止充电测试（10 分钟）
1. 保持充电线连接，点亮屏幕。
2. 屏幕亮度调整为 50%，停留在桌面静止。
3. 启动采样脚本：
   ```bash
   ./avium-charge-test.sh screen_on 600 5
   ```
4. 保持屏幕常亮 10 分钟（不要息屏，不要操作手机）。
5. 记录这 10 分钟的：
   - 起始与结束电量差（SoC 增长 %）
   - 平均充电电流（mA）

---

## 结论判断矩阵

| 指标 | 熄屏充电预期 | 亮屏充电预期 (正常硬件温控) | 异常现象 (强限制) |
| :--- | :--- | :--- | :--- |
| **平均电流** | 1800 ~ 3000 mA | 1000 ~ 1500 mA | ≤ 300 mA 或负电流 |
| **SoC 增长/10min** | +8% ~ +15% | +4% ~ +8% | 0% ~ +1% |
| **电池温度** | 35°C ~ 41°C | 36°C ~ 42°C | 45°C+ (过热保护) |

### 机制分析：
- **如果亮屏电流在 1000~1500mA，但电量几乎不涨**：
  说明系统正在被高功耗进程（如后台 GMS 同步、地图定位或全亮屏）吞噬了输入的 1.5A 电流（输入电流 ≈ 消耗电流，净电流接近 0）。
- **如果亮屏瞬间电流直接被硬件限制在 200~400mA**：
  说明 OnePlus 6 PMIC 固件开启了严苛的 Display-On Input Current Limiting（防烧屏与发热限制）。
EOF

echo "Generated $SCRIPT and $GUIDE successfully."
