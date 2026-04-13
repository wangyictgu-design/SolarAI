import Foundation

protocol PaygoViewModelDelegate: AnyObject {
    func paygoViewModelDidSubmitSuccess(_ viewModel: PaygoViewModel)
    func paygoViewModel(_ viewModel: PaygoViewModel, didSubmitFailure message: String)
    func paygoViewModel(_ viewModel: PaygoViewModel, didUpdateInfo info: String)
    func paygoViewModel(_ viewModel: PaygoViewModel, didGetBlocked remainingSeconds: Int)
}

/// PAYGO 标签页的 ViewModel
///
/// 职责：
/// 1. 管理用户输入的解锁码（appendDigit / deleteLastDigit / clearCode）
/// 2. 提交解锁码到 /password.do，处理三种响应状态（成功/失败/锁定）
/// 3. 定时轮询 /showInfo.do 获取设备实时状态文本
/// 4. 提交完成后立即刷新 info，并在一小段时间内短间隔补拉（设备端 info 可能略晚于 password 响应才更新）
/// 5. 提交 /password.do 未返回前，不发起 /showInfo.do（避免轮询抢先返回旧 info 盖住新状态）
/// 6. Compatibility：未勾选默认 `code`，勾选后 `pwd`
final class PaygoViewModel {

    weak var delegate: PaygoViewModelDelegate?

    private(set) var currentCode: String = ""
    private(set) var useCompatibility: Bool = false
    private(set) var deviceInfo: String = "Input code"

    private var infoTimer: Timer?
    /// `true` 时表示正在等待 `password.do` 响应，此时跳过仅由轮询触发的 `showInfo.do`
    private var isPaygoPasswordRequestInFlight = false
    /// 用于取消过期的「密码提交后补拉 showInfo」延时任务
    private var quickInfoRefreshGeneration: UInt = 0

    /// 数字键盘追加结果（禁用 7、8、9、0）
    enum AppendDigitResult {
        case appended
        case maxLengthReached
        case forbiddenDigit
    }

    // MARK: - 代码输入

    func appendDigit(_ digit: Int) -> AppendDigitResult {
        if digit == 0 || (7...9).contains(digit) {
            return .forbiddenDigit
        }
        guard currentCode.count < 12 else { return .maxLengthReached }
        currentCode.append("\(digit)")
        return .appended
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

        isPaygoPasswordRequestInFlight = true

        NetworkService.shared.submitPaygoPassword(
            code: currentCode,
            useCompatibility: useCompatibility
        ) { [weak self] result in
            guard let self = self else { return }
            self.isPaygoPasswordRequestInFlight = false
            switch result {
            case .success(let response):
                switch response.resultType {
                case .success:
                    // status == 0：立即清空输入，避免 UI 仍短暂显示已提交密码
                    self.clearCode()
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
        quickInfoRefreshGeneration += 1
    }

    func refreshInfo() {
        fetchInfo()
    }

    /// 提交 password 后使用：立刻请求一次 showInfo，并在短时间内再补拉数次，缩短 info 晚更新的等待（局域网仍可能有包乱序，概率低）。
    func refreshInfoWithQuickFollowUps() {
        quickInfoRefreshGeneration += 1
        let generation = quickInfoRefreshGeneration
        fetchInfo()
        let extraCount = 4
        let step: TimeInterval = 0.2
        for i in 1...extraCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + step * Double(i)) { [weak self] in
                guard let self, generation == self.quickInfoRefreshGeneration else { return }
                self.fetchInfo()
            }
        }
    }

    private func fetchInfo() {
        if isPaygoPasswordRequestInFlight {
            return
        }
        NetworkService.shared.fetchPaygoInfo { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.deviceInfo = response.info
                self.delegate?.paygoViewModel(self, didUpdateInfo: response.info)
            case .failure:
                // 请求失败仍回调一次，便于界面在「仅等 showInfo」时解除占位/隐藏态
                self.delegate?.paygoViewModel(self, didUpdateInfo: self.deviceInfo)
            }
        }
    }
}
