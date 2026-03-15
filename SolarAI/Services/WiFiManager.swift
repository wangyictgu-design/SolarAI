import Foundation
import UIKit
import SystemConfiguration
import Alamofire

/// 網路變化通知（WiFi 切換等）
extension Notification.Name {
    static let networkDidChange = Notification.Name("SolarAI.networkDidChange")
    static let deviceReachabilityResult = Notification.Name("SolarAI.deviceReachabilityResult")
}

/// WiFi 連接管理器
/// iOS 無法掃描 WiFi 列表，因此本類的職責是：
/// 1. 打開系統 WiFi 設定讓用戶手動連接
/// 2. 透過 SCNetworkReachability 監聽網路變化
/// 3. 透過 Ping 設備 API 驗證是否連接到正確的 WiFi
final class WiFiManager {

    static let shared = WiFiManager()

    private var reachability: SCNetworkReachability?
    private var isMonitoring = false

    private init() {}

    // MARK: - 打開系統 WiFi 設定

    func openWiFiSettings() {
        if let url = URL(string: "App-Prefs:root=WIFI"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - 網路變化監聽

    func startMonitoringNetworkChanges() {
        guard !isMonitoring else { return }

        let host = "192.168.4.1"
        reachability = SCNetworkReachabilityCreateWithName(nil, host)

        var context = SCNetworkReachabilityContext(
            version: 0, info: nil, retain: nil, release: nil, copyDescription: nil
        )

        if let reachability = reachability {
            SCNetworkReachabilitySetCallback(reachability, { (_, _, _) in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .networkDidChange, object: nil)
                }
            }, &context)

            SCNetworkReachabilityScheduleWithRunLoop(
                reachability, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue
            )
        }

        // Darwin 系統級網路變化通知（與 c019-app 相同做法）
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { (_, _, _, _, _) in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .networkDidChange, object: nil)
                }
            },
            "com.apple.system.config.network_change" as CFString,
            nil,
            .deliverImmediately
        )

        isMonitoring = true
    }

    func stopMonitoringNetworkChanges() {
        if let reachability = reachability {
            SCNetworkReachabilityUnscheduleFromRunLoop(
                reachability, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue
            )
        }
        reachability = nil
        isMonitoring = false
    }

    // MARK: - 判斷是否在 WiFi 網路

    var isOnWiFi: Bool {
        let manager = NetworkReachabilityManager()
        return manager?.isReachableOnEthernetOrWiFi ?? false
    }

    // MARK: - Ping 設備驗證連接

    /// 向逆變器 API 發送請求，驗證是否連到正確的 WiFi
    func pingDevice(completion: ((Bool) -> Void)? = nil) {
        let url = "\(AppConfig.baseURL)\(APIEndpoint.general)"

        AF.request(url, method: .get, requestModifier: { $0.timeoutInterval = 4 })
            .validate(statusCode: 200..<300)
            .responseData { response in
                let success = response.data != nil && response.error == nil
                NotificationCenter.default.post(
                    name: .deviceReachabilityResult,
                    object: nil,
                    userInfo: ["reachable": success]
                )
                completion?(success)
            }
    }
}

// MARK: - WiFi 錯誤類型

enum WiFiError: Error, LocalizedError {
    case notOnWiFi
    case deviceUnreachable
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notOnWiFi:
            return "請先連接到 WiFi 網路"
        case .deviceUnreachable:
            return "無法連接到逆變器，請確認已連接到 SSE WiFi"
        case .cancelled:
            return "連接已取消"
        }
    }
}
