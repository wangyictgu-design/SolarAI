import Foundation

/// GET /devStatus.do 的回应
struct DeviceStatusResponse: Codable {
    let status: Int
    let pv1Volt: Int             // ÷10 → 太阳能电压 (V)
    let pv1ChargerCur: Int       // ÷10 → 太阳能充电电流 (A)
    let pv1ChargerPwr: Int       // 太阳能充电功率 (W)
    let battVolt: Int            // ÷10 → 电池电压 (V)
    let gridVolt: Int            // ÷10 → 电网电压 (V)
    let gridCur: Int             // ÷10 → 电网电流 (A)
    let sload: Int               // 视在负载 (VA)
    let pgrid: Int               // 电网功率 (W) — 若 > 0 需 SINT 转换
    let pload: Int               // 负载功率 (W)
    let inverterVolt: Int        // ÷10 → 逆变器电压 (V)
    let inverterCur: Int         // ÷10 → 逆变器电流 (A)
    let bmsSocVal: Int           // 电池 SOC (%)
    let battType: Int            // 2 = 锂电池（显示 SOC），否则隐藏
    let pwrTotalHLoad: Int       // 总 kWh 高位元组
    let pwrTotalLLoad: Int       // 总 kWh 低位元组

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
    var ploadDisplay: String { DataFormatter.formatPower(pload) }
    var inverterVoltDisplay: String { DataFormatter.formatVoltage(inverterVolt) }
    var inverterCurDisplay: String { DataFormatter.formatCurrent(inverterCur) }
    var bmsSocDisplay: String { DataFormatter.formatSOC(bmsSocVal) }
    var totalKwhDisplay: String { DataFormatter.formatTotalKwh(high: pwrTotalHLoad, low: pwrTotalLLoad) }
    var shouldShowBattSOC: Bool { battType == 2 }
}
