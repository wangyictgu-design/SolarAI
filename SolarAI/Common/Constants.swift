import UIKit

// MARK: - 应用设置

enum AppConfig {
    static let appName = "Solar AI Inverter Setup APP"
    static let appVersion = "V01R001B001"
    static let defaultPassword = "SSE123456"
    static let baseURL = "http://192.168.4.1:8080"
    static let dataRefreshInterval: TimeInterval = 3.0
}

// MARK: - API 端点

enum APIEndpoint {
    static let general = "/general.do"
    static let deviceStatus = "/devStatus.do"
    static let faultyAlert = "/faultyAlert.do"
    static let password = "/password.do"
    static let showInfo = "/showInfo.do"
}

// MARK: - 颜色

enum AppColors {
    static let background = UIColor(hex: "#1a343d")
    static let accent = UIColor(hex: "#C56A02")
    static let accentGradientStart = UIColor(hex: "#FF8C00")
    static let accentGradientEnd = UIColor(hex: "#FFA500")
    static let error = UIColor(hex: "#FF4444")
    static let confirm = UIColor(hex: "#00BFA5")
    static let textPrimary = UIColor.white
    static let textSecondary = UIColor(white: 0.65, alpha: 1.0)
    static let separator = UIColor(white: 0.3, alpha: 1.0)
    static let cardBackground = UIColor(hex: "#1C2B3A")
    /// 顶部 Tab 选中项背景（仅此区域用该色，未选中与页面底色一致）
    static let tabSelected = UIColor(hex: "#C56A02")
    /// 顶部 Tab 未选中：与 `background` 相同，保证整页底色统一为 #1a343d
    static let tabNormal = background
    static let inputBackground = UIColor(hex: "#253545")
    /// Tab 之间竖向虚线、底部分割线
    static let tabBarDivider = UIColor(white: 1, alpha: 0.32)
}

// MARK: - 硬件图标名称

/// 硬件图标枚举
///
/// 设计说明：
/// - 枚举声明顺序 = UI 显示顺序（与安卓端保持一致）
/// - rawValue (0~15) 仅用于 activeHardwareModules 集合中的唯一标识
/// - 图片文件通过 resourceIndex 属性映射到 Assets 中的 hw_orange_{rawValue} / hw_gray_{rawValue}
/// - 前 5 个为 Connect state（第一行），后 11 个为 Hardware state（第二三行）
enum HardwareIcon: Int, CaseIterable {
    // Connect state（第一行 5 个）
    case heartbeat = 0
    case bluetooth = 1
    case wifi = 2
    case fourG = 3
    case gps = 4
    // Hardware state（第二、三行 11 个）— 顺序与安卓一致
    case pvInput = 5
    case load = 6
    case battery = 7
    case grid = 8
    case generator = 9
    case ct = 10
    case rs485 = 11
    case usb = 12
    case bts = 13
    case can = 14
    case bms = 15

    var title: String {
        switch self {
        case .heartbeat:  return "Heartbeat"
        case .bluetooth:  return "Bluetooth"
        case .wifi:       return "WiFi"
        case .fourG:      return "4G"
        case .gps:        return "GPS"
        case .pvInput:    return "PV Input"
        case .load:       return "Load"
        case .battery:    return "Battery"
        case .grid:       return "Grid"
        case .generator:  return "Generator"
        case .ct:         return "CT"
        case .rs485:      return "RS485"
        case .usb:        return "USB"
        case .bts:        return "BTS"
        case .can:        return "CAN"
        case .bms:        return "BMS"
        }
    }

    /// 对应 Solar资料/图标橙色/ 中的资源文件编号（1-16）
    var resourceIndex: Int {
        switch self {
        case .heartbeat:  return 1
        case .bluetooth:  return 2
        case .wifi:       return 3
        case .fourG:      return 4
        case .gps:        return 5
        case .pvInput:    return 6
        case .load:       return 9
        case .battery:    return 7
        case .grid:       return 8
        case .generator:  return 10
        case .ct:         return 11
        case .rs485:      return 12
        case .usb:        return 13
        case .bts:        return 16
        case .can:        return 15
        case .bms:        return 14
        }
    }

    var grayImageName: String {
        return "hw_gray_\(rawValue)"
    }

    var orangeImageName: String {
        return "hw_orange_\(rawValue)"
    }
}

// MARK: - 能量流向动画

/// 能量流向动画类型
///
/// rawValue 对应 Assets 中的图片资源前缀名。除 noConnect 为静态图（1帧）外，
/// 其余每种类型有 6 帧动画（{rawValue}1 ~ {rawValue}6），每帧 0.5 秒循环播放。
/// 由 BitParser.parseArrowFlag() 根据 arrow_flag bits 4-9 解析得出。
enum EnergyFlowType: String {
    case noConnect       = "no_connect"
    case battToLoad      = "b_inver_l"
    case gridToBatt      = "gr_inver_b"
    case gridToLoad      = "gr_inver_l"
    case gridToLoadBatt  = "gr_inver_l_b"
    case pvToBatt        = "pv_inver_b"
    case pvToLoad        = "pv_inver_l"
    case pvToLoadBatt    = "pv_inver_l_b"
    case pvBattToLoad    = "pvb_inver_l"
    case pvGridToLoadBatt = "pvgrid_inver_l_b"

    var frameCount: Int {
        return self == .noConnect ? 1 : 6
    }

    func frameImageName(at index: Int) -> String {
        if self == .noConnect {
            return rawValue
        }
        return "\(rawValue)\(index + 1)"
    }
}

// MARK: - 动画时长

enum AnimationConfig {
    static let flowFrameDuration: TimeInterval = 0.5
    static let flowAnimationRepeat: Int = 0  // 0 = 无限循环
}
