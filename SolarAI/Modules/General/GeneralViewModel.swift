import Foundation

protocol GeneralViewModelDelegate: AnyObject {
    func generalViewModelDidUpdateData(_ viewModel: GeneralViewModel)
    func generalViewModel(_ viewModel: GeneralViewModel, didFailWithError error: String)
}

/// 總覽分頁的 ViewModel — 取得連線狀態、硬體狀態、基本資訊
final class GeneralViewModel {

    weak var delegate: GeneralViewModelDelegate?

    private(set) var generalResponse: GeneralResponse?
    private(set) var activeHardwareModules: Set<Int> = []
    private(set) var deviceVersion: String = "--"
    private(set) var isHeartbeatActive: Bool = false

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
        NetworkService.shared.fetchGeneral { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.generalResponse = response
                self.isHeartbeatActive = (response.status == 0)
                self.activeHardwareModules = BitParser.parseHardwareStatus(response.arrowFlag)

                let version = response.devVersion
                if version > 0 {
                    let major = (version >> 16) & 0xFF
                    let minor = (version >> 8) & 0xFF
                    let patch = version & 0xFF
                    self.deviceVersion = "SSE_INT_FW_V\(major).\(String(format: "%02d", minor)).\(String(format: "%02d", patch))"
                } else {
                    self.deviceVersion = "SSE_INT_FW_V1.00.00"
                }

                self.delegate?.generalViewModelDidUpdateData(self)

            case .failure(let error):
                self.delegate?.generalViewModel(self, didFailWithError: error.localizedDescription)
            }
        }
    }
}
