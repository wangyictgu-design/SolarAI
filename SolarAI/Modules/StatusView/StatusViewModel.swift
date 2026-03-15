import Foundation

protocol StatusViewModelDelegate: AnyObject {
    func statusViewModelDidUpdateStatus(_ viewModel: StatusViewModel)
    func statusViewModelDidUpdateFlow(_ viewModel: StatusViewModel, flowType: EnergyFlowType)
    func statusViewModel(_ viewModel: StatusViewModel, didFailWithError error: String)
}

/// 狀態檢視分頁的 ViewModel — 輪詢裝置狀態與 general 端點
final class StatusViewModel {

    weak var delegate: StatusViewModelDelegate?

    private(set) var deviceStatus: DeviceStatusResponse?
    private(set) var currentFlowType: EnergyFlowType = .noConnect

    private var refreshTimer: Timer?

    // MARK: - 公開方法

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

        // 取得 arrow_flag 以顯示流向動畫
        group.enter()
        NetworkService.shared.fetchGeneral { [weak self] result in
            if case .success(let response) = result {
                let flowType = BitParser.parseArrowFlag(response.arrowFlag)
                if self?.currentFlowType != flowType {
                    self?.currentFlowType = flowType
                    DispatchQueue.main.async {
                        self?.delegate?.statusViewModelDidUpdateFlow(self!, flowType: flowType)
                    }
                }
            }
            group.leave()
        }

        // 取得裝置狀態以顯示資料標籤
        group.enter()
        NetworkService.shared.fetchDeviceStatus { [weak self] result in
            switch result {
            case .success(let response):
                self?.deviceStatus = response
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.delegate?.statusViewModel(self!, didFailWithError: error.localizedDescription)
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

// MARK: - EnergyFlowType 的 Equatable 實作

extension EnergyFlowType: Equatable {}
