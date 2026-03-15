import Foundation

/// POST /password.do 的請求主體
struct PaygoPasswordRequest: Codable {
    let pwd: String?
    let code: String?

    init(value: String, useCompatibility: Bool) {
        if useCompatibility {
            self.pwd = nil
            self.code = value
        } else {
            self.pwd = value
            self.code = nil
        }
    }
}

/// POST /password.do 的回應
struct PaygoPasswordResponse: Codable {
    let status: Int
    let remainLockTime: Int

    enum CodingKeys: String, CodingKey {
        case status
        case remainLockTime = "remain_lock_time"
    }

    /// 0 = 成功, 1 = 失敗, 2 = 鎖定中
    var resultType: PaygoResult {
        switch status {
        case 0: return .success
        case 1: return .wrongCode
        case 2: return .blocked(remainingSeconds: remainLockTime)
        default: return .wrongCode
        }
    }
}

enum PaygoResult {
    case success
    case wrongCode
    case blocked(remainingSeconds: Int)
}

/// GET /showInfo.do 的回應
struct PaygoInfoResponse: Codable {
    let status: Int
    let info: String
}
