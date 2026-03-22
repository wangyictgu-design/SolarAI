import UIKit

// MARK: - 应用程式设定

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
    static let tabSelected = UIColor(hex: "#C56A02")
    static let tabNormal = UIColor(hex: "#2A3D4E")
    static let inputBackground = UIColor(hex: "#253545")
}

// MARK: - 硬件图示名称

/// 硬件图标枚举 — 声明顺序决定 UI 显示顺序（与安卓端一致）
/// rawValue 仅用于 activeHardwareModules 集合的标识，不再直接对应图片文件名
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

/// 将 arrow_flag 位元模式对应至动画图片集名称
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
