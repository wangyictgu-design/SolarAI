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
        case .invalidURL: return "无效的 URL"
        case .requestFailed(let msg): return "请求失败: \(msg)"
        case .decodingFailed: return "资料解析失败"
        case .noData: return "无回应资料"
        }
    }
}

/// 网络服务单例，负责与逆变器 HTTP API 通讯
/// 基础地址：http://192.168.4.1:8080
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
                if let data = response.data, let raw = String(data: data, encoding: .utf8) {
                    print("📡 [\(endpoint)] Raw JSON: \(raw)")
                }

                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    print("❌ [\(endpoint)] Decode error: \(error)")
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
        let parameters: [String: Any] = {
            if useCompatibility {
                return ["code": code]
            } else {
                return ["pwd": code]
            }
        }()

        session.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default)
            .validate(statusCode: 200..<300)
            .responseData { response in
                if let data = response.data, let raw = String(data: data, encoding: .utf8) {
                    print("📡 [POST \(APIEndpoint.password)] Raw JSON: \(raw)")
                }

                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(PaygoPasswordResponse.self, from: data)
                    completion(.success(decoded))
                } catch {
                    print("❌ [POST \(APIEndpoint.password)] Decode error: \(error)")
                    completion(.failure(.decodingFailed))
                }
            }
    }

    /// 获取设备信息（PAYGO 页面用）
    func fetchPaygoInfo(completion: @escaping (Result<PaygoInfoResponse, NetworkError>) -> Void) {
        request(endpoint: APIEndpoint.showInfo, completion: completion)
    }
}
