import Foundation

/// 用于将 16 位旗标值解析为个别位状态的工具
enum BitParser {

    /// 检查 16 位值中特定位是否被设定（bit 0 = 最右侧）
    static func isBitSet(_ value: Int, bit: Int) -> Bool {
        guard bit >= 0 && bit < 16 else { return false }
        return (value >> bit) & 1 == 1
    }

    /// 提取 2-bit 字段值（用于 Machine-Batt-Arrow 和 Machine-Grid-Arrow）
    static func extract2Bits(_ value: Int, lowBit: Int) -> Int {
        return (value >> lowBit) & 0x03
    }

    // MARK: - arrow_flag → 硬件存在标志（bits 0-3）

    /// 从 arrow_flag 提取硬件存在标志
    /// - bit 0: PVFlag（太阳能板是否存在）
    /// - bit 1: LoadFlag（负载是否存在）
    /// - bit 2: BattFlag（电池是否存在）
    /// - bit 3: GridFlag（电网是否存在）
    struct HardwareExistence {
        let pvExists: Bool
        let loadExists: Bool
        let battExists: Bool
        let gridExists: Bool
    }

    static func parseHardwareExistence(_ arrowFlag: Int) -> HardwareExistence {
        return HardwareExistence(
            pvExists: isBitSet(arrowFlag, bit: 0),
            loadExists: isBitSet(arrowFlag, bit: 1),
            battExists: isBitSet(arrowFlag, bit: 2),
            gridExists: isBitSet(arrowFlag, bit: 3)
        )
    }

    // MARK: - arrow_flag → 能量流向类型（bits 4-9）

    /// 文档定义（image_4.png）：
    ///   bit 4: PV-to-Machine-Arrow（0:断开 1:PV→逆变器）
    ///   bit 5: Machine-to-Load-Arrow（0:断开 1:逆变器→负载）
    ///   bits 6-7: Machine-Batt-Arrow（00:断开 01:逆变器→电池 10:电池→逆变器 11:连接）
    ///   bits 8-9: Machine-Grid-Arrow（00:断开 01:逆变器→电网 10:电网→逆变器 11:连接）
    ///   流动图解析只需要用 4, 5, 6, 7, 8, 9 即可
    static func parseArrowFlag(_ flag: Int) -> EnergyFlowType {
        let pvToMachine    = isBitSet(flag, bit: 4)
        let machineToLoad  = isBitSet(flag, bit: 5)
        let machineBatt    = extract2Bits(flag, lowBit: 6)
        let machineGrid    = extract2Bits(flag, lowBit: 8)

        let battCharging    = (machineBatt == 0b01)  // 逆变器 → 电池
        let battDischarging = (machineBatt == 0b10)  // 电池 → 逆变器
        let gridToMachine   = (machineGrid == 0b10)  // 电网 → 逆变器
        let gridConnected   = (machineGrid != 0b00)  // 电网有连接

        // 按优先级匹配流向组合
        if pvToMachine && gridConnected && machineToLoad && battCharging {
            return .pvGridToLoadBatt   // PV+电网 → 逆变器 → 负载+电池
        }
        if pvToMachine && battDischarging && machineToLoad {
            return .pvBattToLoad       // PV+电池 → 逆变器 → 负载
        }
        if pvToMachine && machineToLoad && battCharging {
            return .pvToLoadBatt       // PV → 逆变器 → 负载+电池
        }
        if pvToMachine && machineToLoad {
            return .pvToLoad           // PV → 逆变器 → 负载
        }
        if pvToMachine && battCharging {
            return .pvToBatt           // PV → 逆变器 → 电池
        }
        if gridToMachine && machineToLoad && battCharging {
            return .gridToLoadBatt     // 电网 → 逆变器 → 负载+电池
        }
        if gridToMachine && machineToLoad {
            return .gridToLoad         // 电网 → 逆变器 → 负载
        }
        if gridToMachine && battCharging {
            return .gridToBatt         // 电网 → 逆变器 → 电池
        }
        if battDischarging && machineToLoad {
            return .battToLoad         // 电池 → 逆变器 → 负载
        }

        return .noConnect
    }

    // MARK: - SINT 转换（用于 pgrid）

    /// 使用二补数将无符号 16 位值转换为有符号
    static func toSigned16(_ value: Int) -> Int {
        if value <= 0 {
            return value
        }
        let inverted = (~value) & 0xFFFF
        return -(inverted + 1)
    }
}
