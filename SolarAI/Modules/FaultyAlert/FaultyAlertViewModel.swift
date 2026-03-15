import Foundation

protocol FaultyAlertViewModelDelegate: AnyObject {
    func faultyAlertViewModelDidUpdate(_ viewModel: FaultyAlertViewModel)
    func faultyAlertViewModel(_ viewModel: FaultyAlertViewModel, didFailWithError error: String)
}

/// 故障警報分頁的 ViewModel — 取得並解析錯誤/警告位元欄位
final class FaultyAlertViewModel {

    weak var delegate: FaultyAlertViewModelDelegate?

    private(set) var faultItems: [FaultItem] = []
    private(set) var isLoading = false

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
        isLoading = true
        NetworkService.shared.fetchFaultyAlert { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false

            switch result {
            case .success(let response):
                self.faultItems = response.parseAllAlerts()
                self.delegate?.faultyAlertViewModelDidUpdate(self)
            case .failure(let error):
                self.delegate?.faultyAlertViewModel(self, didFailWithError: error.localizedDescription)
            }
        }
    }
}
