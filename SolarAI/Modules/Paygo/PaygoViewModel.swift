import Foundation

protocol PaygoViewModelDelegate: AnyObject {
    func paygoViewModelDidSubmitSuccess(_ viewModel: PaygoViewModel)
    func paygoViewModel(_ viewModel: PaygoViewModel, didSubmitFailure message: String)
    func paygoViewModel(_ viewModel: PaygoViewModel, didUpdateInfo info: String)
    func paygoViewModel(_ viewModel: PaygoViewModel, didGetBlocked remainingSeconds: Int)
}

/// PAYGO 分页的 ViewModel — 处理代码提交与设备状态信息
final class PaygoViewModel {

    weak var delegate: PaygoViewModelDelegate?

    private(set) var currentCode: String = ""
    private(set) var useCompatibility: Bool = false
    private(set) var deviceInfo: String = "Input code"

    private var infoTimer: Timer?

    // MARK: - 代码输入

    func appendDigit(_ digit: Int) {
        guard currentCode.count < 20 else { return }
        currentCode.append("\(digit)")
    }

    func deleteLastDigit() {
        guard !currentCode.isEmpty else { return }
        currentCode.removeLast()
    }

    func clearCode() {
        currentCode = ""
    }

    func setCompatibility(_ enabled: Bool) {
        useCompatibility = enabled
    }

    // MARK: - 提交

    func submitCode() {
        guard !currentCode.isEmpty else {
            delegate?.paygoViewModel(self, didSubmitFailure: "Input error")
            return
        }

        NetworkService.shared.submitPaygoPassword(
            code: currentCode,
            useCompatibility: useCompatibility
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                switch response.resultType {
                case .success:
                    self.delegate?.paygoViewModelDidSubmitSuccess(self)
                case .wrongCode:
                    self.delegate?.paygoViewModel(self, didSubmitFailure: "Wrong code")
                case .blocked(let seconds):
                    self.delegate?.paygoViewModel(self, didGetBlocked: seconds)
                }
            case .failure(let error):
                self.delegate?.paygoViewModel(self, didSubmitFailure: error.localizedDescription)
            }
        }
    }

    // MARK: - 信息轮询

    func startInfoPolling() {
        fetchInfo()
        infoTimer?.invalidate()
        infoTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.dataRefreshInterval, repeats: true) { [weak self] _ in
            self?.fetchInfo()
        }
    }

    func stopInfoPolling() {
        infoTimer?.invalidate()
        infoTimer = nil
    }

    func refreshInfo() {
        fetchInfo()
    }

    private func fetchInfo() {
        NetworkService.shared.fetchPaygoInfo { [weak self] result in
            guard let self = self else { return }
            if case .success(let response) = result {
                self.deviceInfo = response.info
                self.delegate?.paygoViewModel(self, didUpdateInfo: response.info)
            }
        }
    }
}
