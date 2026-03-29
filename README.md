# Solar AI Inverter Setup APP (iOS)

## 一、项目概述

本项目是 **Solar AI 逆变器** 配套的 iOS 端控制/监测 App，功能对标已上线的 Android 版本。  
App 通过 WiFi 连接逆变器设备的热点（SSID 以 `SSE` 开头，默认密码 `SSE123456`），与设备内置的 HTTP 服务通信，实时展示设备状态、能量流向、故障告警和 PAYGO 解锁功能。

- **开发语言**：Swift 5
- **UI 框架**：UIKit（纯代码布局，不使用 SwiftUI / Storyboard）
- **架构模式**：MVVM
- **最低系统版本**：iOS 15.0
- **屏幕方向**：仅横屏（Landscape）
- **依赖管理**：CocoaPods
  - `SnapKit`：自动布局约束
  - `Alamofire`：HTTP 网络请求

---

## 二、核心交互流程

```
┌─────────────┐    手动连WiFi     ┌──────────────┐    Ping成功     ┌──────────────────┐
│  登录页       │ ──────────────→ │ iOS WiFi 设置  │ ──────────────→ │  主页（4个Tab）    │
│  Connection  │  Refresh按钮     └──────────────┘   自动跳转       │  General          │
│  ViewController│                                                  │  Status View      │
│              │  Click to connect → 主动Ping设备                   │  Faulty Alert     │
│              │  Test Entry(DEBUG) → 跳过验证直接进入               │  PAYGO            │
└─────────────┘                                                    └──────────────────┘
       ↑                                                                   │
       └───────────── 点击 Connected 区域 → 退出弹窗 → Confirm ────────────┘
```

**WiFi 连接说明**：iOS 系统不允许 App 扫描/程序化连接 WiFi，因此采用以下方案：
1. 点击 "Refresh the BT List" → 跳转系统 WiFi 设置
2. 用户手动连接 SSE 开头的热点 → 返回 App
3. App 通过 `SCNetworkReachability` 监听网络变化 → 自动 Ping 设备 → 成功则跳转主页

---

## 三、项目目录结构

```
SolarAI/
├── Application/                    # App 生命周期
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Common/                         # 公共模块
│   ├── Constants.swift             # 全局常量（颜色、API端点、硬件图标枚举、动画类型）
│   ├── Extensions/
│   │   ├── UIColor+Hex.swift       # 十六进制颜色扩展
│   │   └── UIView+Layout.swift     # 布局辅助扩展
│   └── Utils/
│       ├── BitParser.swift         # 位运算工具（arrow_flag解析、SINT16转换）
│       └── DataFormatter.swift     # 数据格式化（电压÷10、功率、kWh计算等）
├── Models/                         # 数据模型（Codable）
│   ├── GeneralResponse.swift       # /general.do 响应
│   ├── DeviceStatusResponse.swift  # /devStatus.do 响应 + 格式化显示属性
│   ├── FaultyAlertResponse.swift   # /faultyAlert.do 响应 + 位解析
│   ├── PaygoResponse.swift         # /password.do 和 /showInfo.do 响应
│   └── ErrorDefinitions.swift      # 故障/警告码定义（SE001~SE051, SW001~SW012）
├── Services/                       # 服务层
│   ├── NetworkService.swift        # HTTP 请求单例（Alamofire）
│   └── WiFiManager.swift           # WiFi 状态监听 + Ping 验证
├── Modules/                        # 业务模块（按页面划分）
│   ├── Connection/                 # 登录/连接页
│   │   ├── ConnectionViewController.swift
│   │   └── ConnectionViewModel.swift
│   ├── Main/                       # 主容器
│   │   ├── MainContainerViewController.swift  # 顶部Tab栏 + 子VC容器
│   │   ├── SideTabBarView.swift               # 顶部Tab栏视图(TopTabBarView)
│   │   ├── ExitConfirmView.swift              # 退出确认弹窗
│   │   └── LoadingView.swift                  # 全屏加载遮罩
│   ├── General/                    # General 标签页
│   │   ├── GeneralViewController.swift
│   │   ├── GeneralViewModel.swift
│   │   └── Views/HardwareStatusCell.swift     # 硬件图标Cell
│   ├── StatusView/                 # Status View 标签页
│   │   ├── StatusViewController.swift
│   │   ├── StatusViewModel.swift
│   │   └── Views/EnergyFlowView.swift         # 能量流向动画视图
│   ├── FaultyAlert/                # Faulty Alert 标签页
│   │   ├── FaultyAlertViewController.swift
│   │   └── FaultyAlertViewModel.swift
│   └── Paygo/                      # PAYGO 标签页
│       ├── PaygoViewController.swift
│       └── PaygoViewModel.swift
└── Resources/
    └── Assets.xcassets             # 图片资源（硬件图标、动画帧、背景图等）
```

---

## 四、API 接口详解

设备基础地址：`http://192.168.4.1:8080`

### 4.1 GET /general.do — 通用信息

**用途**：General 页获取硬件状态 + Status View 页获取能量流向

```json
{
  "status": 0,
  "arrow_flag": 166,
  "dev_version": 0
}
```

| 字段 | 说明 |
|------|------|
| `status` | 心跳状态，0 = 正常 |
| `arrow_flag` | 16位标志位，bits 0-3 为硬件存在标志，bits 4-9 为能量流向 |
| `dev_version` | 设备固件版本，可能为 Int 或 String |

**arrow_flag 位解析**（从右往左数）：

```
Bits 0-3：硬件存在标志
  bit 0: PV（太阳能板）
  bit 1: Load（负载）
  bit 2: Battery（电池）
  bit 3: Grid（电网）

Bits 4-9：能量流向
  bit 4:   PV → 逆变器（0:断开 1:连接）
  bit 5:   逆变器 → 负载（0:断开 1:连接）
  bits 6-7: 逆变器 ↔ 电池（00:断开 01:逆变器→电池 10:电池→逆变器 11:连接）
  bits 8-9: 逆变器 ↔ 电网（00:断开 01:逆变器→电网 10:电网→逆变器 11:连接）
```

**dev_version 解析**：
- 若为 String：直接显示
- 若为 Int 且 > 0：`major = (value >> 16) & 0xFF`, `minor = (value >> 8) & 0xFF`, `patch = value & 0xFF` → 拼接为 `SSE_INT_FW_vX.XX.XX`
- 若为 0：默认显示 `SSE_INT_FW_v1.00.00`

---

### 4.2 GET /devStatus.do — 设备实时数据

**用途**：Status View 页的数据标签 + General 页的 BMS 状态判断

```json
{
  "status": 0,
  "pv1_volt": 0,
  "pv1_charger_cur": 0,
  "pv1_charger_pwr": 0,
  "batt_volt": 0,
  "grid_volt": 0,
  "grid_cur": 0,
  "sload": 0,
  "pgrid": 0,
  "pload": 0,
  "inverter_volt": 0,
  "inverter_cur": 0,
  "bms_soc_val": 0,
  "batt_type": 0,
  "pwr_total_h_load": 0,
  "pwr_total_l_load": 0
}
```

| 字段 | 显示名 | 处理方式 |
|------|--------|---------|
| `pv1_volt` | PV Volt | ÷ 10.0，显示 V |
| `pv1_charger_cur` | PV Charger Cur | ÷ 10.0，显示 A |
| `pv1_charger_pwr` | PV Charger P | 直接显示 W |
| `batt_volt` | Batt Volt | ÷ 10.0，显示 V |
| `grid_volt` | Grid Volt | ÷ 10.0，显示 V |
| `grid_cur` | Grid Cur | ÷ 10.0，显示 A |
| `sload` | SLoad | 直接显示 VA |
| `pgrid` | Grid P | ≤0 直接显示；>0 做 SINT16 转换后显示 W |
| `pload` | PLoad | 直接显示 W |
| `inverter_volt` | Invert Volt | ÷ 10.0，显示 V |
| `inverter_cur` | Invert Cur | ÷ 10.0，显示 A |
| `bms_soc_val` | Batt SOC | 仅 batt_type=2 时显示，单位 % |
| `batt_type` | — | =2 表示锂电池，BMS 图标高亮 |
| `pwr_total_h_load` + `pwr_total_l_load` | Total | 计算公式：`high * 1000 + low * 0.1`，单位 kwh |

**pgrid SINT16 转换说明**：  
pgrid > 0 时，将其作为无符号 16 位整数解释为有符号 16 位整数（二补数）。使用 `Int16(bitPattern: UInt16(value))` 实现。

---

### 4.3 GET /faultyAlert.do — 故障告警

**用途**：Faulty Alert 页的三列表格展示

```json
{
  "status": 0,
  "error1": 0, "error2": 0, "error3": 0,
  "warn1": 0, "warn2": 0,
  "pv1_charger_error": 0,
  "pv1_charger_warn": 0
}
```

每个字段为 16 位标志位，每 bit 对应一个故障/警告码。解析方式：遍历 bit 0~15，若该位为 1，则从 `ErrorDefinitions` 中查找对应的故障码、事件描述和解决方案。

完整故障码定义见 `Models/ErrorDefinitions.swift`（SE001~SE051 为错误，SW001~SW012 为警告）。

---

### 4.4 POST /password.do — PAYGO 解锁

**用途**：提交 PAYGO 解锁码

请求体（根据 Compatibility 开关选择字段名）：
- Compatibility 关闭（默认）：`{"pwd": "151125"}`
- Compatibility 开启：`{"code": "151125"}`

```json
// 响应
{
  "status": 0,
  "remain_lock time": 0
}
```

| status | 含义 | UI 处理 |
|--------|------|--------|
| 0 | 成功 | 显示 "Code accepted!"（绿色） |
| 1 | 失败 | 显示 "Wrong code"（红色） |
| 2 | 锁定中 | 显示 "Blocked. Wait Xs"（红色），X = remain_lock_time |

提交后无论结果如何，都会清空输入并立即调用 `/showInfo.do` 刷新显示。

---

### 4.5 GET /showInfo.do — PAYGO 设备状态

**用途**：获取 PAYGO 页输入框内的提示文本

```json
{
  "status": 0,
  "info": "Input code"
}
```

`info` 字段文本在用户未输入时显示在输入框内；用户输入时被数字覆盖；提交后恢复显示。  
通过定时轮询（每 3 秒）保持最新状态。

---

## 五、数据轮询机制

所有页面在 `viewWillAppear` 时启动轮询，`viewWillDisappear` 时停止，轮询间隔为 **3 秒**（`AppConfig.dataRefreshInterval`）：

| 页面 | 轮询接口 |
|------|---------|
| General | `/general.do` + `/devStatus.do`（并发） |
| Status View | `/general.do`（流向动画） + `/devStatus.do`（数据标签），并发 |
| Faulty Alert | `/faultyAlert.do` |
| PAYGO | `/showInfo.do` |

---

## 六、General 页硬件图标高亮逻辑

硬件图标分为两组：**Connect state**（5 个）和 **Hardware state**（11 个）。

图标高亮数据来源：

| 图标 | 高亮条件 | 数据来源 |
|------|---------|---------|
| Heartbeat | `general.status == 0` | `/general.do` |
| Bluetooth | `/general.do` 请求成功（能解析到 General 响应） | 通讯成功即高亮；失败则清空模块集合并置灰 |
| WiFi / 4G / GPS | 暂无对应接口字段 | 保持置灰 |
| PV Input | `arrow_flag` bit 0 == 1 | `/general.do` |
| Load | `arrow_flag` bit 1 == 1 | `/general.do` |
| Battery | `arrow_flag` bit 2 == 1 | `/general.do` |
| Grid | `arrow_flag` bit 3 == 1 | `/general.do` |
| BMS | `batt_type == 2` | `/devStatus.do` |
| 其余（Generator, CT, RS485, USB, BTS, CAN） | 暂无对应接口字段 | 保持置灰 |

---

## 七、Status View 能量流向动画

根据 `arrow_flag` bits 4-9 的组合，映射到不同的动画类型：

| 类型 | 资源前缀 | 含义 |
|------|---------|------|
| `noConnect` | `no_connect` | 无连接（静态图） |
| `pvToLoad` | `pv_inver_l` | PV → 逆变器 → 负载 |
| `pvToBatt` | `pv_inver_b` | PV → 逆变器 → 电池 |
| `pvToLoadBatt` | `pv_inver_l_b` | PV → 逆变器 → 负载+电池 |
| `pvBattToLoad` | `pvb_inver_l` | PV+电池 → 逆变器 → 负载 |
| `gridToLoad` | `gr_inver_l` | 电网 → 逆变器 → 负载 |
| `gridToBatt` | `gr_inver_b` | 电网 → 逆变器 → 电池 |
| `gridToLoadBatt` | `gr_inver_l_b` | 电网 → 逆变器 → 负载+电池 |
| `battToLoad` | `b_inver_l` | 电池 → 逆变器 → 负载 |
| `pvGridToLoadBatt` | `pvgrid_inver_l_b` | PV+电网 → 逆变器 → 负载+电池 |

每种动画 6 帧，帧文件命名为 `{前缀}1` ~ `{前缀}6`，每帧 0.5 秒，无限循环。

---

## 八、构建与运行

```bash
# 1. 安装依赖
cd SolarAiInverter
pod install

# 2. 打开工作空间（注意是 .xcworkspace，不是 .xcodeproj）
open SolarAI.xcworkspace

# 3. 选择真机目标（需连接逆变器热点才能获取数据）
#    DEBUG 模式下登录页有 "Test Entry" 按钮可跳过连接直接进入主页
```

---

## 九、待确认/注意事项

1. **`remain_lock time` 字段**：协议文档中 key 为 `"remain_lock time"`（含空格），代码中暂用 `"remain_lock_time"`（下划线），需连接真机时实际验证 API 返回的字段名。
2. **Bluetooth / 4G / GPS 图标**：目前无对应接口字段，始终置灰。如后续固件增加相关字段，需要更新 `GeneralViewModel.buildHardwareStatus()` 方法。
3. **warn2**：协议文档中预留了 warn2 字段但无定义，`ErrorDefinitions.warn2` 为空字典。
