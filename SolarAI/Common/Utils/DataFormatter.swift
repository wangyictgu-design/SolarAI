import Foundation

/// 將原始裝置資料值格式化為可顯示的字串
enum DataFormatter {

    /// 除以 10.0 並格式化為電壓
    static func formatVoltage(_ rawValue: Int) -> String {
        let value = Double(rawValue) / 10.0
        return String(format: "%.1f V", value)
    }

    /// 除以 10.0 並格式化為電流
    static func formatCurrent(_ rawValue: Int) -> String {
        let value = Double(rawValue) / 10.0
        return String(format: "%.1f A", value)
    }

    /// 以瓦特格式化功率
    static func formatPower(_ rawValue: Int) -> String {
        return "\(rawValue) W"
    }

    /// 以 VA 格式化視在功率
    static func formatVA(_ rawValue: Int) -> String {
        return "\(rawValue) VA"
    }

    /// 從高位元組與低位元組值計算總 kWh
    /// 公式：high * 1000 + low * 0.1
    static func formatTotalKwh(high: Int, low: Int) -> String {
        let total = Double(high) * 1000.0 + Double(low) * 0.1
        return String(format: "%.1f kwh", total)
    }

    /// 解析電網功率 (pgrid)，正值時考慮 SINT 轉換
    static func formatGridPower(_ rawValue: Int) -> String {
        let displayValue: Int
        if rawValue <= 0 {
            displayValue = rawValue
        } else {
            displayValue = BitParser.toSigned16(rawValue)
        }
        return "\(displayValue) W"
    }

    /// 格式化電池 SOC 百分比
    static func formatSOC(_ rawValue: Int) -> String {
        return "\(rawValue) %"
    }
}
