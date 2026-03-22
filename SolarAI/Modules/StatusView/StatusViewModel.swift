import Foundation

protocol StatusViewModelDelegate: AnyObject {
    func statusViewModelDidUpdateStatus(_ viewModel: StatusViewModel)
    func statusViewModelDidUpdateFlow(_ viewModel: StatusViewModel, flowType: EnergyFlowType)
    func statusViewModel(_ viewModel: StatusViewModel, didFailWithError error: String)
}

/// 状态检视分页的 ViewModel — 轮询设备状态与 general 端点
final class StatusViewModel {

    weak var delegate: StatusViewModelDelegate?

    private(set) var deviceStatus: DeviceStatusResponse?
    private(set) var currentFlowType: EnergyFlowType = .noConnect

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

        // 获取 arrow_flag 以显示流向动画
        group.enter()
        NetworkService.shared.fetchGeneral { [weak self] result in
            guard let self = self else { group.leave(); return }
            if case .success(let response) = result {
                let flowType = BitParser.parseArrowFlag(response.arrowFlag)
                if self.currentFlowType != flowType {
                    self.currentFlowType = flowType
                    DispatchQueue.main.async {
                        self.delegate?.statusViewModelDidUpdateFlow(self, flowType: flowType)
                    }
                }
            }
            group.leave()
        }

        // 获取设备状态以显示资料标签
        group.enter()
        NetworkService.shared.fetchDeviceStatus { [weak self] result in
            guard let self = self else { group.leave(); return }
            switch result {
            case .success(let response):
                self.deviceStatus = response
            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.statusViewModel(self, didFailWithError: error.localizedDescription)
                }
            }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.delegate?.statusViewModelDidUpdateStatus(self)
        }
    }
}

// MARK: - EnergyFlowType 的 Equatable 实作

extension EnergyFlowType: Equatable {}
