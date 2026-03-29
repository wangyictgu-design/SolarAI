import Foundation

protocol GeneralViewModelDelegate: AnyObject {
    func generalViewModelDidUpdateData(_ viewModel: GeneralViewModel)
    func generalViewModel(_ viewModel: GeneralViewModel, didFailWithError error: String)
}

/// General 标签页的 ViewModel
///
/// 职责：
/// 1. 定时轮询 /general.do + /devStatus.do（并发请求）
/// 2. 解析 arrow_flag bits 0-3 判断 PV/Load/Battery/Grid 是否存在
/// 3. 解析 devStatus.batt_type 判断 BMS 是否活跃
/// 4. 汇总所有数据源，输出 activeHardwareModules 集合供 UI 判断图标高亮
/// 5. /general.do 成功 → Bluetooth 高亮；失败 → 清空 activeHardwareModules 并刷新 UI
/// 6. 解析 dev_version 构建设备版本号字符串
final class GeneralViewModel {

    weak var delegate: GeneralViewModelDelegate?

    /// 存储活跃的硬件模块 rawValue 集合，用于 UI 判断图标高亮
    private(set) var activeHardwareModules: Set<Int> = []
    private(set) var deviceVersion: String = "--"
    private(set) var isHeartbeatActive: Bool = false

    private var refreshTimer: Timer?

    // MARK: - 公开方法

    func startPolling() {
        fetchData()
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.dataRefreshInterval, repeats: true) { [weak self] _ in
            self?.fetchData()
        }
    }

    func stopPolling() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - 私有方法

    private func fetchData() {
        let group = DispatchGroup()

        var generalResp: GeneralResponse?
        var devStatusResp: DeviceStatusResponse?

        // 请求 /general.do
        group.enter()
        NetworkService.shared.fetchGeneral { result in
            if case .success(let resp) = result {
                generalResp = resp
            }
            group.leave()
        }

        // 请求 /devStatus.do（用于 BMS 状态判断）
        group.enter()
        NetworkService.shared.fetchDeviceStatus { result in
            if case .success(let resp) = result {
                devStatusResp = resp
            }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            guard let general = generalResp else {
                self.activeHardwareModules = []
                self.isHeartbeatActive = false
                self.deviceVersion = "--"
                self.delegate?.generalViewModelDidUpdateData(self)
                self.delegate?.generalViewModel(self, didFailWithError: "获取设备数据失败")
                return
            }

            self.buildHardwareStatus(general: general, devStatus: devStatusResp)
            self.buildDeviceVersion(general: general)

            self.delegate?.generalViewModelDidUpdateData(self)
        }
    }

    // MARK: - 硬件图标状态

    /// 根据多个数据源组合判断哪些硬件模块处于活跃状态
    ///
    /// 数据来源：
    /// - arrow_flag bits 0-3: PV / Load / Battery / Grid 存在标志
    /// - general.status: Heartbeat 状态（0 = 活跃）
    /// - devStatus.batt_type: BMS 状态（== 2 表示锂电池 BMS 活跃）
    /// - Bluetooth: /general.do 成功即高亮（本方法仅在成功解析后调用）
    private func buildHardwareStatus(general: GeneralResponse, devStatus: DeviceStatusResponse?) {
        var modules = Set<Int>()

        // Heartbeat: status == 0 表示心跳正常
        self.isHeartbeatActive = (general.status == 0)
        if general.status == 0 {
            modules.insert(HardwareIcon.heartbeat.rawValue)
        }

        // Bluetooth: /general.do 成功 ↔ 与设备 HTTP 通讯正常
        modules.insert(HardwareIcon.bluetooth.rawValue)

        // arrow_flag bits 0-3: 硬件存在标志
        let hw = BitParser.parseHardwareExistence(general.arrowFlag)
        if hw.pvExists   { modules.insert(HardwareIcon.pvInput.rawValue) }
        if hw.loadExists  { modules.insert(HardwareIcon.load.rawValue) }
        if hw.battExists  { modules.insert(HardwareIcon.battery.rawValue) }
        if hw.gridExists  { modules.insert(HardwareIcon.grid.rawValue) }

        // BMS: batt_type == 2 表示锂电池 BMS 存在
        if let ds = devStatus, ds.battType == 2 {
            modules.insert(HardwareIcon.bms.rawValue)
        }

        print("🔧 arrow_flag=\(general.arrowFlag), 二进制=\(String(general.arrowFlag, radix: 2)), 活跃模块=\(modules.sorted())")

        self.activeHardwareModules = modules
    }

    // MARK: - 版本号解析

    private func buildDeviceVersion(general: GeneralResponse) {
        switch general.devVersion {
        case .string(let str):
            self.deviceVersion = str

        case .int(let version):
            if version > 0 {
                let major = (version >> 16) & 0xFF
                let minor = (version >> 8) & 0xFF
                let patch = version & 0xFF
                self.deviceVersion = "SSE_INT_FW_v\(major).\(String(format: "%02d", minor)).\(String(format: "%02d", patch))"
            } else {
                self.deviceVersion = "SSE_INT_FW_v1.00.00"
            }
        }
    }
}
