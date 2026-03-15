import Foundation

/// GET /devStatus.do 的回應
struct DeviceStatusResponse: Codable {
    let status: Int
    let pv1Volt: Int             // ÷10 → 太陽能電壓 (V)
    let pv1ChargerCur: Int       // ÷10 → 太陽能充電電流 (A)
    let pv1ChargerPwr: Int       // 太陽能充電功率 (W)
    let battVolt: Int            // ÷10 → 電池電壓 (V)
    let gridVolt: Int            // ÷10 → 電網電壓 (V)
    let gridCur: Int             // ÷10 → 電網電流 (A)
    let sload: Int               // 視在負載 (VA)
    let pgrid: Int               // 電網功率 (W) — 若 > 0 需 SINT 轉換
    let pload: Int               // 負載功率 (W)
    let inverterVolt: Int        // ÷10 → 逆變器電壓 (V)
    let inverterCur: Int         // ÷10 → 逆變器電流 (A)
    let bmsSocVal: Int           // 電池 SOC (%)
    let battType: Int            // 2 = 鋰電池（顯示 SOC），否則隱藏
    let pwrTotalHLoad: Int       // 總 kWh 高位元組
    let pwrTotalLLoad: Int       // 總 kWh 低位元組

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
        case pload = "Pload"
        case inverterVolt = "inverter_volt"
        case inverterCur = "inverter_cur"
        case bmsSocVal = "bms_soc_val"
        case battType = "batt_type"
        case pwrTotalHLoad = "pwr_total_h_load"
        case pwrTotalLLoad = "pwr_total_l_load"
    }

    // MARK: - 格式化顯示值

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
