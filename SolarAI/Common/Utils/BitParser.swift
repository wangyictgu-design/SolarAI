import Foundation

/// 用於將 16 位元旗標值解析為個別位元狀態的工具
enum BitParser {

    /// 檢查 16 位元值中特定位元是否被設定（位元 0 = 最右側）
    static func isBitSet(_ value: Int, bit: Int) -> Bool {
        guard bit >= 0 && bit < 16 else { return false }
        return (value >> bit) & 1 == 1
    }

    /// 從 16 位元值取得所有已設定位元的位置
    static func getSetBits(_ value: Int) -> [Int] {
        var result: [Int] = []
        for bit in 0..<16 {
            if isBitSet(value, bit: bit) {
                result.append(bit)
            }
        }
        return result
    }

    // MARK: - 箭頭旗標 → 能量流向類型

    /// 箭頭旗標位元定義：
    ///   bit 1: 太陽能輸入啟用
    ///   bit 2: 電網/交流輸入啟用
    ///   bit 3: 電池放電中
    ///   bit 5: 電池充電中
    ///   bit 7: 負載輸出啟用
    static func parseArrowFlag(_ flag: Int) -> EnergyFlowType {
        let pvActive   = isBitSet(flag, bit: 1)
        let gridActive = isBitSet(flag, bit: 2)
        let battDischarging = isBitSet(flag, bit: 3)
        let battCharging    = isBitSet(flag, bit: 5)
        let loadActive      = isBitSet(flag, bit: 7)

        if pvActive && gridActive && loadActive && battCharging {
            return .pvGridToLoadBatt
        }
        if pvActive && battDischarging && loadActive {
            return .pvBattToLoad
        }
        if pvActive && loadActive && battCharging {
            return .pvToLoadBatt
        }
        if pvActive && loadActive {
            return .pvToLoad
        }
        if pvActive && battCharging {
            return .pvToBatt
        }
        if gridActive && loadActive && battCharging {
            return .gridToLoadBatt
        }
        if gridActive && loadActive {
            return .gridToLoad
        }
        if gridActive && battCharging {
            return .gridToBatt
        }
        if battDischarging && loadActive {
            return .battToLoad
        }

        return .noConnect
    }

    // MARK: - 硬體狀態旗標

    /// 解析狀態值以判斷哪些硬體模組為啟用狀態
    static func parseHardwareStatus(_ value: Int) -> Set<Int> {
        var activeModules = Set<Int>()
        for bit in 0..<16 {
            if isBitSet(value, bit: bit) {
                activeModules.insert(bit)
            }
        }
        return activeModules
    }

    // MARK: - SINT 轉換（用於 pgrid）

    /// 使用二補數將無符號 16 位元值轉換為有符號
    static func toSigned16(_ value: Int) -> Int {
        if value <= 0 {
            return value
        }
        let inverted = (~value) & 0xFFFF
        return -(inverted + 1)
    }
}
