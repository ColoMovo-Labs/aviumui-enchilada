# AviumUI 16.2.1 for OnePlus 6

[English](README.md) | [简体中文](README.zh-CN.md)

> 为仍然强大的硬件，提供一个继续向前的 Android 体验。  
> 熟悉，而又不同。

[![Status: Experimental](https://img.shields.io/badge/Status-Experimental%20%2F%20Unofficial-orange.svg)](#免责声明)
[![Android Version](https://img.shields.io/badge/Android-16%20QPR2-blue.svg)](#当前平台基础)
[![Target Device](https://img.shields.io/badge/Device-OnePlus%206%20(enchilada)-red.svg)](#概述)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

---

## 概述

此项目提供了一个针对 **OnePlus 6**（代号 `enchilada`）智能手机的 **AviumUI 16.2.1** 非官方系统实现。此构建基于 **Android 16 QPR2**（API 级别 36，构建 ID：`BP4A.251205.006`），并专门针对 Qualcomm Snapdragon 845 (SDM845) 移动平台进行了适配与优化。

此构建被设计用于在 OnePlus 6 上提供一个现代 Android 体验，使您能够在经典设备上体验到更新的交互界面与系统功能。

* **目标设备**：OnePlus 6 (`enchilada`)
* **移动平台**：Qualcomm Snapdragon 845 (SDM845)
* **操作系统版本**：AviumUI 16.2.1
* **底层 Android 版本**：Android 16 QPR2
* **构建类型**：非官方构建 (Unofficial Feature Build)
* **Maintainer**：LoMo 洛陌

需要注意的是，此构建不是官方发布的固件，不保证适用于所有使用场景。

---

## 为什么这个项目存在

OnePlus 6 仍然具有能够处理现代 Android 工作负载的硬件。高通骁龙 845 移动平台搭配 6GB/8GB 运行内存，依然具备充足的计算潜力与日常响应能力。

让熟悉的设备，以一种新的方式继续使用。

每一次滑动，都经过重新考虑。此项目尝试让这台设备继续获得新的系统体验。通过使用现代化的 Android 16 QPR2 核心代码库与深度定制的 AviumUI 系统组件，我们旨在为 OnePlus 6 带来一个更加现代的系统体验。这允许设备在超出官方支持生命周期后，依然能够探索最新的操作系统功能与视觉语言。

---

## 当前平台基础

此项目建立在经过严格验证的底层基础设施之上，旨在提供最大的系统稳定性与硬件兼容性：

* **Linux 4.19 Golden Baseline**：采用经过完整验证的 Linux 4.19.325 LTS 长期支持内核分支，保留纯净的上游调度与电源架构，未集成侵入式内核修改。
* **Physical / Legacy A/B 分区架构**：原生保留 OnePlus 6 原始的物理双分区布局（`/system_a`、`/system_b`、`/vendor_a`、`/vendor_b`）。
* **No Super / No Retrofit Dynamic Partitions**：未引入动态分区重构或 super 容器方案，完全避免了因分区映射开销而导致的性能损耗或恢复模式异常。
* **EROFS 文件系统**：系统镜像生成采用 EROFS (Enhanced Read-Only File System) 并启用 `lz4hc,9` 高比率压缩，在有限的物理存储空间中提供了优异的读取吞吐量与空间节约。
* **SELinux Enforcing**：系统全程在 SELinux 强制模式 (Enforcing) 下运行，严格约束各守护进程与 HAL 域的安全策略。
* **Android Verified Boot (AVB)**：集成了完整的 AVB 签名与元数据校验逻辑，确保各镜像链条的完整性。
* **Android 16 QPR2**：对齐最新的 Google Android 平台功能集与安全补丁基线。

---

## 当前已验证功能

在经过真实设备测试的环境中，以下功能已被确认为按预期工作：

* **系统启动与核心引导 (Boot & Init)**：冷启动、温重启以及关机充电流程均稳定通过。
* **无线局域网 (Wi-Fi)**：支持 2.4GHz 与 5GHz 双频段连接，网络切换与热点分享工作正常。
* **蓝牙通信 (Bluetooth)**：支持外设连接、低功耗蓝牙 (BLE) 以及 Bluetooth A2DP 高清音频传输。
* **近场通信 (NFC)**：支持卡片模拟、交通卡读取与数据交换。
* **移动网络与高清语音 (Cellular & VoLTE)**：移动数据通信稳定，支持运营商 IMS 注册与 VoLTE 高清通话。
* **相机子系统 (Camera)**：Qualcomm 硬件抽象层工作正常，支持照片拍摄与视频录制。
* **音频架构 (Audio & Sound)**：集成 Qualcomm / OnePlus Audio HAL，支持立体声外放、扬声器通话与 Dirac GEF 音效。
* **耳机接口 (Headphones)**：3.5mm 实体耳机插孔支持插入检测与线控指令。
* **指纹识别 (Fingerprint)**：后置电容式指纹传感器认证可靠，唤醒响应迅速。
* **三段式开关 (Alert Slider)**：物理三段式滑块支持静音、振动与响铃模式切换。
* **自动亮度 (Auto Brightness)**：环境光传感器与平滑调节算法协同正常。
* **息屏显示 (AOD / Ambient Display)**：低功耗息屏显示与轻触唤醒功能可用。
* **统一锁屏时钟 (Universal Lockscreen Clock)**：Material Expressive 锁屏时钟样式渲染完整。

---

## Feature Build

此构建为包含完整功能的 **Feature Build**，在纯净基准之上集成了多项专属体验增强：

* **Google Mobile Services (GMS)**：深度集成官方 GMS 运行环境，支持账户同步与基础服务。
* **11 种精心挑选的中文字体 (11 Chinese Fonts)**：集成包括得意黑、霞鹜文楷、霞鹜新晰黑、小赖圆体、思源宋体等在内的 11 种开源授权字体，可通过“壁纸与样式”设置直接应用。
* **27 张精选原生高分辨率壁纸 (27 Curated Wallpapers)**：内置专为 19:9 AMOLED 屏幕调校的高清壁纸集，涵盖兽系原创、二次元场景与深空摄影。
* **Avium / Elixir Control Center**：全新设计的控制中心快捷磁贴与状态面板，提供流畅的下滑手势与交互控制。
* **Status Bar Capsule (状态栏胶囊)**：在状态栏轻量化呈现当前正在进行的系统事件。
* **Super Island (超级岛)**：居中适配 OnePlus 6 顶部凹槽（Notch）的实时活动交互岛，无缝包覆刘海物理区域。
* **Back-to-Home 动画改进**：针对 Quickstep 与 Launcher3 之间的过渡管线进行了优化，使返回桌面的手势退出动画更加连贯。

---

## Super Island

Super Island 是直接在 `SystemUI` 进程内部实现的高级实时活动系统（Ongoing Activity），专为 OnePlus 6 的物理凹槽屏幕进行硬件几何适配。

### 支持的实时事件类型

* **媒体播放 (Media Playback)**：展示音轨标题、艺术家、专辑封面图、3 柱动态均衡器动画以及上一首/暂停/下一首快捷控制。
* **充电指示 (Charging)**：实时电池百分比显示，以及 OnePlus Dash Charge 快速充电连接瞬态弹窗。
* **音频设备连接 (Headset)**：3.5mm 有线耳机与蓝牙音频设备接入通知横幅。
* **进行中的通话 (Phone Calls)**：实时计时器药丸以及一键挂断操作。
* **屏幕录制 (Screen Recording)**：实时录屏计时状态与快速停止控制。
* **手电筒 (Flashlight)**：手电筒开启状态指示与快捷关闭。

### 视觉模糊与已知行为说明

Super Island 支持通过 SurfaceFlinger 渲染背景模糊（Background Blur）。需要注意的是：

> [!WARNING]
> **关于 Background Blur 的使用建议**：  
> 在先前的实现中，`View.setRenderEffect` 曾导致卡片内部内容连带模糊的问题。当前的背景模糊实现仍处于一个需要进一步改进的状态。在某些配置中，启用 Blur 可能导致卡片内容的可读性降低，或在特定图层叠加时产生半透明矩形伪影。**建议当前保持该选项关闭**，系统将自动回退至清晰纯净的半透明深色 OLED 渲染路径。

您可以在 `设置 -> 状态栏 -> 胶囊与超级岛`（或 `Avium Settings -> Status Bar -> Capsule & Super Island`）中按需调整此行为。

---

## GMS

此构建通过启用 `WITH_GMS=true` 构建标志，内置了核心 Google Mobile Services 服务包。

* **核心组件预装**：Google Play Services、Google Play Store、Google Services Framework 等核心基础设施已内置并在系统分区中完成配置。
* **独立应用策略**：为了满足物理 system 分区的容量要求，部分可从 Google Play 获取的独立应用（例如 Google App / Velvet、Google Maps、YouTube 等）**不会被预安装**。
* **获取方式**：用户在完成初始设置后，可以通过 Google Play Store 根据个人需要下载安装这些应用。
* **关于第三方 GApps 的重要提示**：Google Mobile Services 已包含在此构建中。安装额外的 GApps 软件包可能导致重复组件、权限冲突或不可预测的行为，因此**强烈不建议**执行此操作。

---

## 电源与续航

当前此系统正处于 **Runtime Power Validation**（真机运行时代谢验证）阶段。

需要明确说明的是，我们不对设备的电池续航时间做出任何定性保证。电池表现可能受到电池健康度、移动网络信号质量、GNSS 卫星追踪、GMS 后台同步以及具体使用场景的显著影响。

* **高复合负载场景**：当设备处于连续高负载工作时（例如同时开启 GNSS 卫星导航、移动蜂窝数据连接、蓝牙 A2DP 音频传输以及中高屏幕亮度），整机瞬时功耗处于相对较高水平。
* **硬件老化因素**：OnePlus 6 作为发布于 2018 年的设备，原始电池（额定容量 3300mAh）可能已存在不同程度的化学老化与内阻升高，这可能会加剧在高负载下的电量下降速度。
* **充电行为说明**：OnePlus 6 的硬件电源管理芯片（PMIC）在屏幕点亮状态下会实施严格的输入电流限制以控制发热，因此在屏幕开启时充电速度会明显慢于熄屏状态。

有关电源表现的详细测量与日志抓取，请参阅随附的真机测试指引文档。

---

## 已知问题

在决定使用此构建之前，请查看以下已知问题列表。您可能会注意到某些行为与以前的系统版本不同：

1. **Super Island 背景模糊视觉伪影**：在部分界面下开启 Background Blur 选项可能导致文字渲染模糊或在卡片周围出现黑色半透明矩形。推荐将该功能开关保持在关闭状态。
2. **指纹录入数量限制**：当前系统最多只能录入 2 个指纹。已录入指纹的识别、解锁与认证功能工作正常且稳定。
3. **高负载功耗表现**：在重度导航与多媒体协同工作场景下，电池消耗速度可能较快，当前正在通过专用诊断工具收集真实设备运行数据。
4. **返回桌面手势动画**：Back-to-Home 退出动画在部分复杂第三方应用程序上的连贯性仍在持续验证与优化中。

---

## 安装

在继续之前，请确保您已仔细阅读并理解以下安装指引。如果您使用的是不同的 recovery，步骤可能会有所不同。

### 前提条件

* OnePlus 6 设备已处于可用的解锁 bootloader 状态。
* 设备已安装兼容的 Custom Recovery（推荐基于 Android 16 / LineageOS 23 的 Recovery 环境）。
* 计算机已正确配置 `adb` 命令行工具及相关 USB 驱动程序。
* **强烈建议**在继续操作前将所有个人重要数据备份至外部存储设备，并在 Recovery 中执行恢复出厂设置（Factory Reset / Format Data）。

### 安装步骤

1. 将设备引导进入 Recovery 模式。
2. 在 Recovery 菜单中选择 `Apply update` -> `Apply from ADB`。
3. 将设备通过 USB 数据线连接至计算机，并执行以下命令进行刷写：
   ```bash
   adb sideload AviumUI-16.2.1-enchilada-20260912-Unofficial-GMS.zip
   ```
4. 等待 sideload 传输与分区写入完成。
5. **请勿刷入额外的 GApps 压缩包**，GMS 运行环境已完整集成在此构建中。
6. 选择 `Reboot system now` 重启设备。首次启动过程可能需要数分钟时间，请耐心等待。

> [!CAUTION]
> **绝对禁止的操作**：  
> 请勿尝试使用任何第三方脚本对 OnePlus 6 实施 dynamic partitions (动态分区) 改造，亦不要尝试刷入任何针对 `super` 分区的转换包。此构建完全且严格依赖设备原生的 Physical Legacy A/B 分区表。尝试修改底层物理分区结构可能会导致严重的分区损坏或设备无法启动。

---

## 下载与校验

此构建的验证归档信息如下所示：

* **文件名**：`AviumUI-16.2.1-enchilada-20260912-Unofficial-GMS.zip`
* **Final Feature Commit**：`c4e5e6483876353efe760ed90cb8853d20ae9ce8`
* **Final Bacon CI Run**：`34705478697`
* **SHA256 校验码**：
  ```text
  92236f72c5eb19f50a5ea18bae6a88a6588da34c7c93afdbea677d938544024f
  ```

在将固件传输至设备之前，建议校验文件的 SHA256 哈希值，以确保下载过程未发生文件损坏。

---

## 开发说明

* **底层基线**：此构建的底层 Linux 4.19 内核、硬件抽象层 (HAL) 与硬件编解码组件已在真实设备上完成严谨的启动与功能验证。
* **功能模块**：系统定制层与 Feature 部分目前仍处于持续演进与测试阶段。
* **维护范围**：此项目系社区独立开发者个人维护的业余技术探索成果。维护者不承诺提供定期的 OTA 系统升级，亦不保证长期维护周期的持续性。有关更多信息或参与代码审查，请关注相关代码仓库。

---

## 致谢

感谢以下开源项目、组织与开发者为本项目的实现提供的坚实基础与灵感：

* [LineageOS](https://lineageos.org/) 项目团队：提供了卓越且长期受维护的 Android 设备基准树与硬件抽象支持。
* [AviumUI](https://github.com/AviumUI) 核心开发团队：提供了极富表现力的现代系统设计与界面框架。
* [Android 开源项目 (AOSP)](https://source.android.com/)：提供了开放的操作系统基础。
* OnePlus 与 Qualcomm 开源协作生态：提供了必要的设备内核与驱动程序源代码。
* **EdwinMoq** 与 **uwugl**：为 SDM845 平台的现代 Android 适配提供了宝贵的社区参考与技术探索。
* **Namespace**：特别感谢 [Namespace](https://namespace.so) 为本项目提供的强大云原生计算资源与 GitHub Actions 高性能运行程序。通过使用 Namespace 32 vCPU EPYC 算力支持，使得大型 Android 操作系统构建、全量缓存优化与深度静态审计能够在极短的时间内可靠完成。

---

## 免责声明

此软件按“原样”提供，不附带任何形式的明示或暗示保证。在法律允许的最大范围内，作者和贡献者明确拒绝承担所有明示、默示或法定的陈述与保证，包括但不限于对适销性、特定用途适用性以及不侵权的默示保证。

刷写自定义系统可能导致数据丢失、设备无法启动或某些硬件功能无法按预期工作。在生产环境中部署前，请验证您的配置。在继续操作之前，您应当知悉并自行承担因使用本软件可能带来的全部风险。对于因使用或无法使用本软件而导致的任何直接、间接、偶然或继发性损害，维护者概不承担责任。
