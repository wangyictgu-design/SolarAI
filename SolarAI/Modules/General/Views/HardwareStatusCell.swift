import UIKit
import SnapKit

/// 单一硬件模组图示的 Collection View Cell（灰/橙状态）
final class HardwareStatusCell: UICollectionViewCell {

    static let reuseIdentifier = "HardwareStatusCell"

    /// 图示图片视图（置中，36x36）
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// 标题文字（图示下方，置中，字体 11，最多 2 行）
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

    func configure(icon: HardwareIcon, isActive: Bool) {
        if isActive {
            iconImageView.image = UIImage(named: icon.orangeImageName)
            iconImageView.tintColor = nil
        } else {
            iconImageView.image = UIImage(named: icon.orangeImageName)?
                .withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = UIColor(white: 0.55, alpha: 1.0)
        }
        titleLabel.text = icon.title
        titleLabel.textColor = isActive ? AppColors.accent : AppColors.textSecondary
    }
}
