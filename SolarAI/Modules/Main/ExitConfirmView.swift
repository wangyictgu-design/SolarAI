import UIKit
import SnapKit

/// 退出確認對話框委託協定
protocol ExitConfirmViewDelegate: AnyObject {
    /// 使用者點擊取消
    func didCancel(_ view: ExitConfirmView)
    /// 使用者點擊確認
    func didConfirm(_ view: ExitConfirmView)
}

/// 模態對話框，詢問「是否退出當前設備」
final class ExitConfirmView: UIView {

    weak var delegate: ExitConfirmViewDelegate?

    // MARK: - 子視圖

    /// 中央白色圓角容器
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.cardBackground
        v.layer.cornerRadius = 12
        return v
    }()

    /// 標題文字：「是否退出當前設備」
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Whether to exit the current device"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    /// 水平分隔線
    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.separator
        return v
    }()

    /// 垂直分隔線（按鈕之間）
    private let verticalSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.separator
        return v
    }()

    /// 取消按鈕
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Cancel", for: .normal)
        btn.setTitleColor(AppColors.textPrimary, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return btn
    }()

    /// 確認按鈕（橘色／強調色）
    private let confirmButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Confirm", for: .normal)
        btn.setTitleColor(AppColors.accent, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return btn
    }()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupActions()
    }

    // MARK: - 佈局

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)

        addSubview(containerView)
        [messageLabel, separatorLine, cancelButton, confirmButton, verticalSeparator].forEach {
            containerView.addSubview($0)
        }

        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(300)
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        separatorLine.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(separatorLine.snp.bottom)
            make.leading.equalToSuperview()
            make.trailing.equalTo(containerView.snp.centerX)
            make.height.equalTo(48)
            make.bottom.equalToSuperview()
        }

        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(separatorLine.snp.bottom)
            make.leading.equalTo(containerView.snp.centerX)
            make.trailing.equalToSuperview()
            make.height.equalTo(48)
        }

        verticalSeparator.snp.makeConstraints { make in
            make.top.equalTo(separatorLine.snp.bottom)
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(0.5)
        }
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
    }

    // MARK: - 按鈕事件

    @objc private func cancelTapped() {
        delegate?.didCancel(self)
    }

    @objc private func confirmTapped() {
        delegate?.didConfirm(self)
    }

    // MARK: - 公開方法

    /// 在指定父視圖中顯示
    func show(in parentView: UIView) {
        parentView.addSubview(self)
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        alpha = 0
        UIView.animate(withDuration: 0.25) { self.alpha = 1 }
    }

    /// 關閉並移除
    func dismiss() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
