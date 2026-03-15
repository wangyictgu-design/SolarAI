import Foundation
import Alamofire

/// 網路請求錯誤類型
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(String)
    case decodingFailed
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無效的 URL"
        case .requestFailed(let msg): return "請求失敗: \(msg)"
        case .decodingFailed: return "資料解析失敗"
        case .noData: return "無回應資料"
        }
    }
}

/// 網路服務單例，負責與逆變器 HTTP API 通訊
/// 基礎地址：http://192.168.4.1:8080
final class NetworkService {

    static let shared = NetworkService()

    private let session: Session

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 15
        session = Session(configuration: config)
    }

    // MARK: - 通用請求方法

    private func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        let url = "\(AppConfig.baseURL)\(endpoint)"

        session.request(url, method: method)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    if let data = response.data,
                       let decoded = try? JSONDecoder().decode(T.self, from: data) {
                        completion(.success(decoded))
                    } else {
                        completion(.failure(.requestFailed(error.localizedDescription)))
                    }
                }
            }
    }

    // MARK: - 具體 API 請求

    /// 獲取通用資訊（General 頁面用）
    func fetchGeneral(completion: @escaping (Result<GeneralResponse, NetworkError>) -> Void) {
        request(endpoint: APIEndpoint.general, completion: completion)
    }

    /// 獲取設備狀態（Status View 頁面用）
    func fetchDeviceStatus(completion: @escaping (Result<DeviceStatusResponse, NetworkError>) -> Void) {
        request(endpoint: APIEndpoint.deviceStatus, completion: completion)
    }

    /// 獲取故障告警（Faulty Alert 頁面用）
    func fetchFaultyAlert(completion: @escaping (Result<FaultyAlertResponse, NetworkError>) -> Void) {
        request(endpoint: APIEndpoint.faultyAlert, completion: completion)
    }

    /// 發送 PAYGO 密碼
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
            .responseDecodable(of: PaygoPasswordResponse.self) { response in
                switch response.result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    if let data = response.data,
                       let decoded = try? JSONDecoder().decode(PaygoPasswordResponse.self, from: data) {
                        completion(.success(decoded))
                    } else {
                        completion(.failure(.requestFailed(error.localizedDescription)))
                    }
                }
            }
    }

    /// 獲取設備資訊（PAYGO 頁面用）
    func fetchPaygoInfo(completion: @escaping (Result<PaygoInfoResponse, NetworkError>) -> Void) {
        request(endpoint: APIEndpoint.showInfo, completion: completion)
    }
}
