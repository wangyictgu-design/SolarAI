import Foundation

/// dev_version 字段可能是 Int 或 String，用枚举兼容两种类型
enum FlexibleValue: Codable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let strVal = try? container.decode(String.self) {
            self = .string(strVal)
        } else {
            self = .int(0)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let val): try container.encode(val)
        case .string(let val): try container.encode(val)
        }
    }
}

/// GET /general.do 的响应
struct GeneralResponse: Codable {
    let status: Int
    let arrowFlag: Int
    let devVersion: FlexibleValue

    enum CodingKeys: String, CodingKey {
        case status
        case arrowFlag = "arrow_flag"
        case devVersion = "dev_version"
    }
}
