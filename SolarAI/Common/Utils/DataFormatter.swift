import Foundation

/// 将 /devStatus.do 返回的原始整数值格式化为 UI 显示字符串
///
/// 协议要求：
/// - 电压/电流类字段（pv1_volt, grid_volt, batt_volt, grid_cur, inverter_volt, inverter_cur）需 ÷ 10.0
/// - 功率类字段 pv1_charger_pwr 直接显示
/// - pgrid、pload：均按 SINT16（16 位二补数）解析后显示（协议 20260112）
/// - Total kWh = pwr_total_h_load * 1000 + pwr_total_l_load * 0.1
enum DataFormatter {

    /// 电压字段：原始值 ÷ 10.0，保留一位小数，单位 V
    static func formatVoltage(_ rawValue: Int) -> String {
        let value = Double(rawValue) / 10.0
        return String(format: "%.1f V", value)
    }

    /// 电流字段：原始值 ÷ 10.0，保留一位小数，单位 A
    static func formatCurrent(_ rawValue: Int) -> String {
        let value = Double(rawValue) / 10.0
        return String(format: "%.1f A", value)
    }

    /// 以瓦特格式化功率
    static func formatPower(_ rawValue: Int) -> String {
        return "\(rawValue) W"
    }

    /// 以 VA 格式化视在功率
    static func formatVA(_ rawValue: Int) -> String {
        return "\(rawValue) VA"
    }

    /// 总用电量 kWh：由高低两个字段组合计算
    /// 公式：pwr_total_h_load * 1000 + pwr_total_l_load * 0.1
    static func formatTotalKwh(high: Int, low: Int) -> String {
        let total = Double(high) * 1000.0 + Double(low) * 0.1
        return String(format: "%.1f kwh", total)
    }

    /// pgrid、pload：协议要求接到上传数据后按 SINT（16 位二补数）解析再显示。
    /// 设备若已用 JSON 负数表示，则不再重复套用 16 位解释。
    static func formatSint16PowerW(_ rawValue: Int) -> String {
        let displayValue = rawValue < 0 ? rawValue : BitParser.toSigned16(rawValue)
        return "\(displayValue) W"
    }

    /// 电网功率 Grid P（pgrid）
    static func formatGridPower(_ rawValue: Int) -> String {
        return formatSint16PowerW(rawValue)
    }

    /// 负载有功功率 PLoad（pload）
    static func formatPloadPower(_ rawValue: Int) -> String {
        return formatSint16PowerW(rawValue)
    }

    /// 格式化电池 SOC 百分比
    static func formatSOC(_ rawValue: Int) -> String {
        return "\(rawValue) %"
    }
}
