import Foundation
import Alamofire

/// 网络请求错误类型
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(String)
    case decodingFailed
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .requestFailed(let msg): return "Request failed: \(msg)"
        case .decodingFailed: return "Data parsing failed"
        case .noData: return "No response data"
        }
    }
}

/// 网络服务单例，封装所有与逆变器 HTTP API 的通信
///
/// 基础地址：http://192.168.4.1:8080（设备 WiFi 热点内网地址）
/// 请求超时：8 秒（单次请求）/ 15 秒（资源）
///
/// 提供 5 个接口方法：
/// - fetchGeneral()        → GET  /general.do
/// - fetchDeviceStatus()   → GET  /devStatus.do
/// - fetchFaultyAlert()    → GET  /faultyAlert.do
/// - submitPaygoPassword() → POST /password.do
/// - fetchPaygoInfo()      → GET  /showInfo.do
final class NetworkService {

    static let shared = NetworkService()

    private let session: Session

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 15
        session = Session(configuration: config)
    }

    // MARK: - 通用请求方法

    private func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        let url = "\(AppConfig.baseURL)\(endpoint)"

        session.request(url, method: method)
            .validate(statusCode: 200..<300)
            .responseData { response in
                #if DEBUG
                if let data = response.data, let raw = String(data: data, encoding: .utf8) {
                    print("📡 [\(endpoint)] Raw JSON: \(raw)")
                }
                #endif

                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    #if DEBUG
                    print("❌ [\(endpoint)] Decode error: \(error)")
                    #endif
                    completion(.failure(.decodingFailed))
                }
            }
    }

    // MARK: - 具体 API 请求

    /// 获取通用信息（General 页面用）
    func fetchGeneral(completion: @escaping (Result<GeneralResponse, NetworkError>) -> Void) {
        request(endpoint: APIEndpoint.general, completion: completion)
    }

    /// 获取设备状态（Status View 页面用）
    func fetchDeviceStatus(completion: @escaping (Result<DeviceStatusResponse, NetworkError>) -> Void) {
        request(endpoint: APIEndpoint.deviceStatus, completion: completion)
    }

    /// 获取故障告警（Faulty Alert 页面用）
    func fetchFaultyAlert(completion: @escaping (Result<FaultyAlertResponse, NetworkError>) -> Void) {
        request(endpoint: APIEndpoint.faultyAlert, completion: completion)
    }

    /// 发送 PAYGO 密码
    func submitPaygoPassword(
        code: String,
        useCompatibility: Bool,
        completion: @escaping (Result<PaygoPasswordResponse, NetworkError>) -> Void
    ) {
        let url = "\(AppConfig.baseURL)\(APIEndpoint.password)"
        // 与协议一致：默认未勾选 → code；勾选 Compatibility → pwd
        let parameters: [String: String] = {
            if useCompatibility {
                return ["pwd": code]
            } else {
                return ["code": code]
            }
        }()

        #if DEBUG
        print("📡 [POST \(APIEndpoint.password)] request url=\(url), useCompatibility=\(useCompatibility), parameters=\(parameters)")
        #endif

        session.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
            .validate(statusCode: 200..<300)
            .responseData { response in
                #if DEBUG
                if let data = response.data, let raw = String(data: data, encoding: .utf8) {
                    print("📡 [POST \(APIEndpoint.password)] response Raw JSON: \(raw)")
                }
                #endif

                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(PaygoPasswordResponse.self, from: data)
                    completion(.success(decoded))
                } catch {
                    #if DEBUG
                    print("❌ [POST \(APIEndpoint.password)] Decode error: \(error)")
                    #endif
                    completion(.failure(.decodingFailed))
                }
            }
    }

    /// 获取设备信息（PAYGO 页面用）
    func fetchPaygoInfo(completion: @escaping (Result<PaygoInfoResponse, NetworkError>) -> Void) {
        request(endpoint: APIEndpoint.showInfo, completion: completion)
    }
}
