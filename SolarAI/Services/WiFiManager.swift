import Foundation
import UIKit
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork
import NetworkExtension
import Alamofire

/// 网络变化通知（WiFi 切换等）
extension Notification.Name {
    static let networkDidChange = Notification.Name("SolarAI.networkDidChange")
    static let deviceReachabilityResult = Notification.Name("SolarAI.deviceReachabilityResult")
}

/// WiFi 连接管理器（单例）
///
/// iOS 系统限制：App 无法扫描附近 WiFi 列表，也无法程序化连接指定 WiFi（需付费账号 + NEHotspotConfiguration）。
///
/// 因此采用以下替代方案：
/// 1. openWiFiSettings() — 跳转 iOS 系统 WiFi 设置，由用户手动连接 SSE 热点
/// 2. startMonitoringNetworkChanges() — 通过 SCNetworkReachability + Darwin 通知监听网络变化
/// 3. pingDevice() — 向 /general.do 发请求验证是否连到了逆变器热点
///
/// 流程：用户连接 WiFi → 返回 App → 网络变化通知触发 → Ping 成功 → 自动跳转主页
final class WiFiManager {

    static let shared = WiFiManager()

    private var reachability: SCNetworkReachability?
    private var isMonitoring = false

    private init() {}

    // MARK: - 打开系统 WiFi 设置

    func openWiFiSettings() {
        if let url = URL(string: "App-Prefs:root=WIFI"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - 网络变化监听

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

        // Darwin 系统级网络变化通知（与 c019-app 相同做法）
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

    // MARK: - 判断是否在 WiFi 网络

    var isOnWiFi: Bool {
        let manager = NetworkReachabilityManager()
        return manager?.isReachableOnEthernetOrWiFi ?? false
    }

    // MARK: - 当前 WiFi 名称 (SSID)

    /// 当前已连接 WiFi 的 SSID。
    /// - **必须**：(1) Apple Developer → Identifiers → 本 App ID 勾选 **Access WiFi Information**；(2) `SolarAI.entitlements` 含 `com.apple.developer.networking.wifi-info`；(3) Target Build Settings 中 **CODE_SIGN_ENTITLEMENTS** 指向该文件（勿留空）；(4) 重新生成并选用含该能力的 **Provisioning Profile**。缺任一项则 `CNCopyCurrentNetworkInfo` 在真机上多为 `nil`。
    /// - 首次若仍读不到，系统可能弹出**定位权限**（已配置 `NSLocationWhenInUseUsageDescription`），请允许后再试。
    /// - **模拟器**几乎无法拿到 SSID；请用**真机**且手机已连接该 Wi-Fi。
    func currentWiFiSSID() -> String? {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }
        for interface in interfaces {
            guard let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] else { continue }
            if let ssid = info[kCNNetworkInfoKeySSID as String] as? String, !ssid.isEmpty {
                return ssid
            }
        }
        return nil
    }

    /// 异步读取当前 SSID（优先 `NEHotspotNetwork`，再回退 `CNCopyCurrentNetworkInfo`）。回调可能在后台线程。
    func fetchCurrentWiFiSSID(completion: @escaping (String?) -> Void) {
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { [weak self] network in
                if let ssid = network?.ssid, !ssid.isEmpty {
                    completion(ssid)
                    return
                }
                completion(self?.currentWiFiSSID())
            }
        } else {
            completion(currentWiFiSSID())
        }
    }

    // MARK: - Ping 设备验证连接

    /// 向逆变器 API 发送请求，验证是否连到正确的 WiFi
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

// MARK: - WiFi 错误类型

enum WiFiError: Error, LocalizedError {
    case notOnWiFi
    case deviceUnreachable
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notOnWiFi:
            return "Please connect to a WiFi network first"
        case .deviceUnreachable:
            return "Unable to connect to inverter, please confirm you are connected to SSE WiFi"
        case .cancelled:
            return "Connection cancelled"
        }
    }
}
