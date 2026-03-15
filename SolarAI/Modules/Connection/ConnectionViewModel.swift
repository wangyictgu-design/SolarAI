import Foundation
import UIKit

protocol ConnectionViewModelDelegate: AnyObject {
    func didStartPinging()
    func didConnectSuccessfully()
    func didFailToConnect(error: String)
    func didUpdateStatus(_ message: String)
}

/// 登入頁 ViewModel
///
/// 流程（參考 c019-app 模式）：
/// 1. 用戶點「Refresh」→ 打開 iOS WiFi 設定
/// 2. 用戶在設定中手動連接 SSE WiFi
/// 3. 返回 App → 偵測到網路變化 → 自動 Ping 設備
/// 4. Ping 成功 → 跳轉主頁
/// 5. Ping 失敗 → 顯示錯誤提示
final class ConnectionViewModel {

    weak var delegate: ConnectionViewModelDelegate?

    private let wifiManager = WiFiManager.shared
    private var isPinging = false
    /// 防止重複跳轉的標記
    private(set) var hasNavigated = false

    /// 防抖計時器，避免網路變化時連續多次 Ping
    private var pingDebounceTimer: Timer?

    // MARK: - 生命週期

    func startObserving() {
        wifiManager.startMonitoringNetworkChanges()
        NotificationCenter.default.addObserver(
            self, selector: #selector(onNetworkChanged),
            name: .networkDidChange, object: nil
        )
    }

    func stopObserving() {
        wifiManager.stopMonitoringNetworkChanges()
        NotificationCenter.default.removeObserver(self)
        pingDebounceTimer?.invalidate()
    }

    /// 重置狀態（從主頁返回時調用）
    func resetState() {
        hasNavigated = false
        isPinging = false
    }

    deinit {
        stopObserving()
    }

    // MARK: - 操作

    /// 打開系統 WiFi 設定
    func openWiFiSettings() {
        wifiManager.openWiFiSettings()
    }

    /// 手動觸發連接（用戶點擊「Click to connect」）
    func connectManually() {
        guard !hasNavigated else { return }
        guard wifiManager.isOnWiFi else {
            delegate?.didFailToConnect(error: WiFiError.notOnWiFi.localizedDescription)
            return
        }
        pingDevice()
    }

    /// App 從背景回到前景時調用
    func appDidBecomeActive() {
        guard !hasNavigated else { return }
        schedulePing()
    }

    // MARK: - 內部方法

    @objc private func onNetworkChanged() {
        guard !hasNavigated else { return }
        schedulePing()
    }

    /// 防抖 Ping，避免短時間內多次觸發
    private func schedulePing() {
        pingDebounceTimer?.invalidate()
        pingDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
            self?.pingDevice()
        }
    }

    private func pingDevice() {
        guard !isPinging, !hasNavigated else { return }
        guard wifiManager.isOnWiFi else { return }

        isPinging = true
        delegate?.didStartPinging()
        delegate?.didUpdateStatus("Wifi connecting")

        wifiManager.pingDevice { [weak self] reachable in
            guard let self = self else { return }
            self.isPinging = false

            if reachable && !self.hasNavigated {
                self.hasNavigated = true
                self.delegate?.didUpdateStatus("Device connecting")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.delegate?.didConnectSuccessfully()
                }
            } else if !reachable {
                self.delegate?.didFailToConnect(
                    error: WiFiError.deviceUnreachable.localizedDescription
                )
            }
        }
    }
}
