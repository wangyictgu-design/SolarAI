import Foundation

/// GET /devStatus.do 的响应模型
///
/// 所有字段为接口返回的原始整数值，格式化显示通过 computed properties 实现（调用 DataFormatter）。
/// 需要注意的特殊处理：
/// - 电压/电流字段需 ÷ 10.0
/// - pgrid、pload 均需按 SINT16（二补数）解析后显示
/// - total = pwr_total_h_load * 1000 + pwr_total_l_load * 0.1
/// - batt_type == 2 时才显示 bms_soc_val
struct DeviceStatusResponse: Codable {
    let status: Int
    let pv1Volt: Int             // 原始值，显示时 ÷10 → PV Volt (V)
    let pv1ChargerCur: Int       // 原始值，显示时 ÷10 → PV Charger Cur (A)
    let pv1ChargerPwr: Int       // 直接显示 → PV Charger P (W)
    let battVolt: Int            // 原始值，显示时 ÷10 → Batt Volt (V)
    let gridVolt: Int            // 原始值，显示时 ÷10 → Grid Volt (V)
    let gridCur: Int             // 原始值，显示时 ÷10 → Grid Cur (A)
    let sload: Int               // 直接显示 → SLoad (VA)
    let pgrid: Int               // SINT16 解析 → Grid P (W)
    let pload: Int               // SINT16 解析 → PLoad (W)
    let inverterVolt: Int        // 原始值，显示时 ÷10 → Invert Volt (V)
    let inverterCur: Int         // 原始值，显示时 ÷10 → Invert Cur (A)
    let bmsSocVal: Int           // 锂电池电量百分比，仅 battType==2 时显示
    let battType: Int            // 电池类型：2=锂电池（显示SOC + BMS图标高亮）
    let pwrTotalHLoad: Int       // Total kWh 高位：× 1000
    let pwrTotalLLoad: Int       // Total kWh 低位：× 0.1

    enum CodingKeys: String, CodingKey {
        case status
        case pv1Volt = "pv1_volt"
        case pv1ChargerCur = "pv1_charger_cur"
        case pv1ChargerPwr = "pv1_charger_pwr"
        case battVolt = "batt_volt"
        case gridVolt = "grid_volt"
        case gridCur = "grid_cur"
        case sload
        case pgrid
        case pload = "pload"
        case inverterVolt = "inverter_volt"
        case inverterCur = "inverter_cur"
        case bmsSocVal = "bms_soc_val"
        case battType = "batt_type"
        case pwrTotalHLoad = "pwr_total_h_load"
        case pwrTotalLLoad = "pwr_total_l_load"
    }

    // MARK: - 格式化显示值

    var pvVoltDisplay: String { DataFormatter.formatVoltage(pv1Volt) }
    var pvChargerCurDisplay: String { DataFormatter.formatCurrent(pv1ChargerCur) }
    var pvChargerPwrDisplay: String { DataFormatter.formatPower(pv1ChargerPwr) }
    var battVoltDisplay: String { DataFormatter.formatVoltage(battVolt) }
    var gridVoltDisplay: String { DataFormatter.formatVoltage(gridVolt) }
    var gridCurDisplay: String { DataFormatter.formatCurrent(gridCur) }
    var sloadDisplay: String { DataFormatter.formatVA(sload) }
    var pgridDisplay: String { DataFormatter.formatGridPower(pgrid) }
    var ploadDisplay: String { DataFormatter.formatPloadPower(pload) }
    var inverterVoltDisplay: String { DataFormatter.formatVoltage(inverterVolt) }
    var inverterCurDisplay: String { DataFormatter.formatCurrent(inverterCur) }
    var bmsSocDisplay: String { DataFormatter.formatSOC(bmsSocVal) }
    var totalKwhDisplay: String { DataFormatter.formatTotalKwh(high: pwrTotalHLoad, low: pwrTotalLLoad) }
    var shouldShowBattSOC: Bool { battType == 2 }
}
