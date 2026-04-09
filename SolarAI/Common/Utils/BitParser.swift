import Foundation

/// 位运算工具类
///
/// 主要用途：
/// 1. 解析 /general.do 返回的 arrow_flag 字段（16位）
///    - bits 0-3: 硬件存在标志（PV/Load/Battery/Grid）→ General 页图标高亮
///    - bits 4-9: 能量流向状态 → Status View 页动画选择
/// 2. pgrid、pload 字段的 SINT16（有符号 16 位整数）转换（协议 20260112 / devStatus.do）
enum BitParser {

    /// 检查 16 位值中指定位是否为 1（bit 0 = 最低位，从右往左数）
    static func isBitSet(_ value: Int, bit: Int) -> Bool {
        guard bit >= 0 && bit < 16 else { return false }
        return (value >> bit) & 1 == 1
    }

    /// 提取连续 2 位的值（用于 bits 6-7 和 bits 8-9 的双位字段）
    /// 返回 0~3，分别对应：00=断开 01=正向 10=反向 11=连接
    static func extract2Bits(_ value: Int, lowBit: Int) -> Int {
        return (value >> lowBit) & 0x03
    }

    // MARK: - arrow_flag → 硬件存在标志（bits 0-3）

    /// 从 arrow_flag 低 4 位提取硬件存在标志，用于 General 页图标高亮判断
    /// - bit 0: PV（太阳能板）
    /// - bit 1: Load（负载）
    /// - bit 2: Battery（电池）
    /// - bit 3: Grid（电网）
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

    /// 从 arrow_flag 的 bits 4-9 解析出当前能量流向，用于 Status View 页的动画选择
    ///
    /// 位定义：
    /// - bit 4:    PV → 逆变器（0:断开 1:连接）
    /// - bit 5:    逆变器 → 负载（0:断开 1:连接）
    /// - bits 6-7: 逆变器 ↔ 电池（00:断开 01:逆变器→电池充电 10:电池→逆变器放电 11:连接）
    /// - bits 8-9: 逆变器 ↔ 电网（00:断开 01:逆变器→电网馈电 10:电网→逆变器供电 11:连接）
    ///
    /// 按优先级匹配流向组合，返回对应的 EnergyFlowType 动画类型
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

    // MARK: - SINT 转换（用于 pgrid、pload）

    /// 将设备上报的 16 位原始值按二补数解释为有符号整数（符号位 0 为正，1 为负）
    ///
    /// 用途：`devStatus.do` 的 pgrid、pload 显示前均做此解析。
    /// 例：60000 → -5536；34 → 34
    static func toSigned16(_ value: Int) -> Int {
        let uint16 = UInt16(clamping: value)
        return Int(Int16(bitPattern: uint16))
    }
}
