import UIKit
import SnapKit

/// 單一硬體模組圖示的 Collection View Cell（灰/橙狀態）
final class HardwareStatusCell: UICollectionViewCell {

    static let reuseIdentifier = "HardwareStatusCell"

    /// 圖示圖片視圖（置中，36x36）
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// 標題文字（圖示下方，置中，字體 11，最多 2 行）
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)

        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 36, height: 36))
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    /// 設定圖示與啟用狀態
    /// - Parameters:
    ///   - icon: 硬體圖示（含 grayImageName、orangeImageName、title）
    ///   - isActive: 是否啟用
    func configure(icon: HardwareIcon, isActive: Bool) {
        let imageName = isActive ? icon.orangeImageName : icon.grayImageName
        iconImageView.image = UIImage(named: imageName)
        titleLabel.text = icon.title
        titleLabel.textColor = isActive ? AppColors.accent : AppColors.textSecondary
    }
}
