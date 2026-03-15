import UIKit
import SnapKit

/// 顯示動態能源流向圖（等角房屋示意圖）
/// 根據當前流向類型循環播放動畫幀
final class EnergyFlowView: UIView {

    /// 圖片視圖，填滿整個視圖，scaleAspectFit
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private var currentFlowType: EnergyFlowType = .noConnect

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        showNoConnect()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        showNoConnect()
    }

    private func setupUI() {
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - 公開方法

    /// 更新能源流向類型
    /// - Parameter type: 能源流向類型（含 frameCount、frameImageName(at:)）
    func updateFlowType(_ type: EnergyFlowType) {
        guard type != currentFlowType else { return }
        currentFlowType = type

        if type == .noConnect {
            // 無連線：顯示靜態圖片
            showNoConnect()
        } else {
            // 其他類型：建立 6 幀動畫，總時長 = 每幀時長 × 幀數
            startAnimation(for: type)
        }
    }

    // MARK: - 動畫

    /// 顯示無連線靜態圖
    private func showNoConnect() {
        imageView.image = UIImage(named: "no_connect")
    }

    /// 啟動動畫
    private func startAnimation(for type: EnergyFlowType) {
        var frames: [UIImage] = []
        for i in 0..<type.frameCount {
            let name = type.frameImageName(at: i)
            if let image = UIImage(named: name) {
                frames.append(image)
            }
        }

        guard !frames.isEmpty else {
            showNoConnect()
            return
        }

        // 使用 UIImage.animatedImage，總時長 = AnimationConfig.flowFrameDuration × 幀數
        let duration = AnimationConfig.flowFrameDuration * Double(type.frameCount)
        imageView.image = UIImage.animatedImage(with: frames, duration: duration)
    }
}
