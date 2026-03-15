import Foundation

/// GET /general.do 的回應
struct GeneralResponse: Codable {
    let status: Int
    let arrowFlag: Int
    let devVersion: Int

    enum CodingKeys: String, CodingKey {
        case status
        case arrowFlag = "arrow_flag"
        case devVersion = "dev_version"
    }
}
