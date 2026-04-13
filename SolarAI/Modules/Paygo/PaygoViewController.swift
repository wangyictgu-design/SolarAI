import UIKit
import SnapKit

/// PAYGO 标签页 — 数字键盘输入解锁码，带品牌展示和兼容性开关
final class PaygoViewController: UIViewController {

    // MARK: - 属性

    private let viewModel = PaygoViewModel()

    // MARK: - UI 组件

    /// 背景图片
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "input_code_bg")
        // 让图片内容直接按视图尺寸拉伸，始终与当前 view 同大小
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.alpha = 0.45
        return iv
    }()

    /// 数字键盘容器
    private let keypadContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#4A5B6B").withAlphaComponent(0.95)
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.3
        v.layer.shadowRadius = 8
        return v
    }()

    /// 代码显示区（同时用于显示用户输入和设备 info 文本）
    private let displayLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(hex: "#6B7B8B").withAlphaComponent(0.5)
        label.textColor = AppColors.textPrimary
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.text = "Input code"
        return label
    }()

    /// 缓存最新的设备 info 文本
    private var latestDeviceInfo: String = "Input code"

    /// 结果提示（成功/失败）：贴 safeArea 右侧，纵向与输入条 `displayLabel` 对齐（键盘仍单独居中）
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.isHidden = true
        return label
    }()

    /// 包住 `resultLabel`；靠屏幕右侧独立布局，`isHidden` 时不占位交互
    private let resultSideContainer: UIView = {
        let v = UIView()
        v.isHidden = true
        v.backgroundColor = .clear
        return v
    }()

    /// 兼容性开关区域
    private let compatibilityStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        return sv
    }()

    /// 兼容性勾选框
    private let compatibilityCheckbox: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "square"), for: .normal)
        btn.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        btn.tintColor = AppColors.accent
        return btn
    }()

    private let compatibilityLabel: UILabel = {
        let label = UILabel()
        label.text = "Compatibility"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = AppColors.textPrimary
        return label
    }()

    /// 底部品牌标题
    private let paygoTitleLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = AppColors.accent
        label.textAlignment = .center
        return label
    }()

    private var keypadButtons: [UIButton] = []
    /// 仅包住数字键区域，锁定态只在此区域降透明度/禁触控，不含上方显示条
    private let keypadGridStack = UIStackView()
    private var isInputLocked: Bool = false
    /// 提交 password.do 后暂隐显示条，直到下一次 showInfo.do 结果写回（避免旧 Reset 等与密码之间的闪烁）
    private var isPaygoDisplaySuppressedUntilNextInfo = false

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupUI()
        setupKeypad()
        viewModel.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.startInfoPolling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopInfoPolling()
        isPaygoDisplaySuppressedUntilNextInfo = false
        displayLabel.alpha = 1
    }

    // MARK: - UI 布局

    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(paygoTitleLabel)
        view.addSubview(keypadContainer)
        view.addSubview(resultSideContainer)
        view.addSubview(compatibilityStack)
        keypadContainer.addSubview(displayLabel)
        resultSideContainer.addSubview(resultLabel)

        compatibilityStack.addArrangedSubview(compatibilityCheckbox)
        compatibilityStack.addArrangedSubview(compatibilityLabel)

        // 背景图
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 兼容性开关 — 右上角
        compatibilityStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }

        keypadContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
            make.width.equalTo(260)
        }

        displayLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(40)
        }

        resultLabel.preferredMaxLayoutWidth = 280
        resultLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.width.lessThanOrEqualTo(280)
        }
        // 键盘卡片单独水平居中；提示锚在 safeArea 右侧偏内，避开最边缘
        resultSideContainer.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-32)
            make.centerY.equalTo(displayLabel.snp.centerY)
            make.width.lessThanOrEqualTo(280)
            make.leading.greaterThanOrEqualTo(keypadContainer.snp.trailing).offset(12).priority(750)
        }

        // PAYGO 标题 — 底部
        paygoTitleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.centerX.equalToSuperview()
        }

        compatibilityCheckbox.addTarget(self, action: #selector(toggleCompatibility), for: .touchUpInside)
    }

    /// 创建数字键盘（4 行 × 3 列）
    private func setupKeypad() {
        let keys: [[String]] = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["✕", "0", "✓"]
        ]

        keypadGridStack.axis = .vertical
        keypadGridStack.spacing = 6
        keypadGridStack.distribution = .fillEqually

        for row in keys {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 6
            rowStack.distribution = .fillEqually

            for key in row {
                let button = createKeyButton(title: key)
                rowStack.addArrangedSubview(button)
                keypadButtons.append(button)
            }
            keypadGridStack.addArrangedSubview(rowStack)
        }

        keypadContainer.addSubview(keypadGridStack)
        keypadGridStack.snp.makeConstraints { make in
            make.top.equalTo(displayLabel.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }

    /// 创建单个键盘按钮
    private func createKeyButton(title: String) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        btn.backgroundColor = UIColor(white: 0.88, alpha: 1.0)
        btn.setTitleColor(UIColor(hex: "#4A5B6B"), for: .normal)
        btn.layer.cornerRadius = 8
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.15
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 2

        if title == "x" || title == "✓" {
            btn.backgroundColor = UIColor(white: 0.82, alpha: 1.0)
        }

        if title == "✕" {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(deleteKeyLongPressed(_:)))
            longPress.minimumPressDuration = 0.45
            btn.addGestureRecognizer(longPress)
        }

        btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        return btn
    }

    // MARK: - 事件处理

    @objc private func keyTapped(_ sender: UIButton) {
        guard !isInputLocked else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }
        guard let title = sender.titleLabel?.text else { return }
        hideResult()

        var skipDisplayUpdate = false
        switch title {
        case "✕": viewModel.deleteLastDigit()
        case "✓":
            if !viewModel.currentCode.isEmpty {
                isPaygoDisplaySuppressedUntilNextInfo = true
                displayLabel.alpha = 0
                skipDisplayUpdate = true
            }
            viewModel.submitCode()
        default:
            if let digit = Int(title) {
                switch viewModel.appendDigit(digit) {
                case .appended, .maxLengthReached:
                    break
                case .forbiddenDigit:
                    showResult(text: "Digits 7, 8, 9, and 0 are not allowed.", color: AppColors.error)
                }
            }
        }
        if !skipDisplayUpdate {
            updateDisplay()
        }
    }

    @objc private func deleteKeyLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard !isInputLocked else { return }
        guard gesture.state == .began else { return }
        hideResult()
        viewModel.clearCode()
        updateDisplay()
    }

    private func applyInputLockIfNeeded(with info: String) {
        let normalized = info.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let shouldLock = (normalized == "demo test" || normalized == "block 30mins")

        guard shouldLock != isInputLocked else { return }
        isInputLocked = shouldLock

        if shouldLock {
            viewModel.clearCode()
            hideResult()
        }

        keypadButtons.forEach { $0.isEnabled = !shouldLock }
        keypadGridStack.isUserInteractionEnabled = !shouldLock
        keypadGridStack.alpha = shouldLock ? 0.55 : 1.0
        keypadContainer.alpha = 1.0
        updateDisplay()
    }

    private func updateDisplay() {
        guard !isPaygoDisplaySuppressedUntilNextInfo else { return }
        if viewModel.currentCode.isEmpty {
            displayLabel.text = latestDeviceInfo
            displayLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            displayLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        } else {
            displayLabel.text = viewModel.currentCode
            displayLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium)
            displayLabel.textColor = AppColors.textPrimary
        }
    }

    @objc private func toggleCompatibility() {
        compatibilityCheckbox.isSelected.toggle()
        viewModel.setCompatibility(compatibilityCheckbox.isSelected)
    }

    // MARK: - 结果显示

    private func showResult(text: String, color: UIColor) {
        resultLabel.text = text
        resultLabel.textColor = color
        resultLabel.isHidden = false
        resultSideContainer.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.hideResult()
        }
    }

    private func hideResult() {
        resultLabel.isHidden = true
        resultSideContainer.isHidden = true
    }
}

// MARK: - PaygoViewModelDelegate

extension PaygoViewController: PaygoViewModelDelegate {

    func paygoViewModelDidSubmitSuccess(_ viewModel: PaygoViewModel) {
        viewModel.clearCode()
        updateDisplay()
        showResult(text: "Code accepted!", color: AppColors.textPrimary)
        viewModel.refreshInfoWithQuickFollowUps()
    }

    func paygoViewModel(_ viewModel: PaygoViewModel, didSubmitFailure message: String) {
        showResult(text: message, color: AppColors.error)
        viewModel.clearCode()
        updateDisplay()
        viewModel.refreshInfoWithQuickFollowUps()
    }

    func paygoViewModel(_ viewModel: PaygoViewModel, didUpdateInfo info: String) {
        latestDeviceInfo = info
        let wasSuppressed = isPaygoDisplaySuppressedUntilNextInfo
        applyInputLockIfNeeded(with: info)
        if wasSuppressed {
            isPaygoDisplaySuppressedUntilNextInfo = false
            displayLabel.alpha = 1
        }
        if viewModel.currentCode.isEmpty {
            updateDisplay()
        }
    }

    func paygoViewModel(_ viewModel: PaygoViewModel, didGetBlocked remainingSeconds: Int) {
        showResult(text: "Blocked. Wait \(remainingSeconds)s", color: AppColors.error)
        viewModel.clearCode()
        updateDisplay()
        viewModel.refreshInfoWithQuickFollowUps()
    }
}
