import UIKit
import SnapKit

/// PAYGO 標籤頁 — 數字鍵盤輸入解鎖碼，帶品牌展示和相容性開關
final class PaygoViewController: UIViewController {

    // MARK: - 屬性

    private let viewModel = PaygoViewModel()

    // MARK: - UI 元件

    /// 背景圖片
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "input_code_bg")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.alpha = 0.3
        return iv
    }()

    /// 數字鍵盤容器
    private let keypadContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#4A5B6B").withAlphaComponent(0.95)
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.3
        v.layer.shadowRadius = 8
        return v
    }()

    /// 代碼顯示區
    private let displayLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(hex: "#6B7B8B").withAlphaComponent(0.5)
        label.textColor = AppColors.textPrimary
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.text = ""
        return label
    }()

    /// 結果提示標籤（成功/失敗）
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    /// 輸入提示
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "Input code"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        return label
    }()

    /// 相容性開關區域
    private let compatibilityStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        return sv
    }()

    /// 相容性勾選框
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

    /// 底部品牌標題
    private let paygoTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "PAYGO ENERGY"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = AppColors.accent
        label.textAlignment = .center
        return label
    }()

    private var keypadButtons: [UIButton] = []

    // MARK: - 生命週期

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
    }

    // MARK: - UI 佈局

    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(paygoTitleLabel)
        view.addSubview(keypadContainer)
        view.addSubview(infoLabel)
        view.addSubview(resultLabel)
        view.addSubview(compatibilityStack)
        keypadContainer.addSubview(displayLabel)

        compatibilityStack.addArrangedSubview(compatibilityCheckbox)
        compatibilityStack.addArrangedSubview(compatibilityLabel)

        // 背景圖
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 相容性開關 — 右上角
        compatibilityStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }

        // 數字鍵盤 — 垂直居中
        keypadContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
            make.width.equalTo(260)
            make.height.equalTo(300)
        }

        // 代碼顯示區
        displayLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(40)
        }

        // 結果標籤
        resultLabel.snp.makeConstraints { make in
            make.top.equalTo(keypadContainer.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }

        // 輸入提示
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(resultLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }

        // PAYGO 標題 — 底部
        paygoTitleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.centerX.equalToSuperview()
        }

        compatibilityCheckbox.addTarget(self, action: #selector(toggleCompatibility), for: .touchUpInside)
    }

    /// 建立數字鍵盤（4 行 × 3 列）
    private func setupKeypad() {
        let keys: [[String]] = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["✕", "0", "✓"]
        ]

        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 6
        gridStack.distribution = .fillEqually

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
            gridStack.addArrangedSubview(rowStack)
        }

        keypadContainer.addSubview(gridStack)
        gridStack.snp.makeConstraints { make in
            make.top.equalTo(displayLabel.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }

    /// 建立單個鍵盤按鈕
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

        if title == "✕" || title == "✓" {
            btn.backgroundColor = UIColor(white: 0.82, alpha: 1.0)
        }

        btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        return btn
    }

    // MARK: - 事件處理

    @objc private func keyTapped(_ sender: UIButton) {
        guard let title = sender.titleLabel?.text else { return }
        hideResult()

        switch title {
        case "✕": viewModel.clearCode()
        case "✓": viewModel.submitCode()
        default:
            if let digit = Int(title) {
                viewModel.appendDigit(digit)
            }
        }
        displayLabel.text = viewModel.currentCode
    }

    @objc private func toggleCompatibility() {
        compatibilityCheckbox.isSelected.toggle()
        viewModel.setCompatibility(compatibilityCheckbox.isSelected)
    }

    // MARK: - 結果顯示

    private func showResult(text: String, color: UIColor) {
        resultLabel.text = text
        resultLabel.textColor = color
        resultLabel.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.hideResult()
        }
    }

    private func hideResult() {
        resultLabel.isHidden = true
    }
}

// MARK: - PaygoViewModelDelegate

extension PaygoViewController: PaygoViewModelDelegate {

    func paygoViewModelDidSubmitSuccess(_ viewModel: PaygoViewModel) {
        showResult(text: "Code accepted!", color: AppColors.confirm)
        viewModel.clearCode()
        displayLabel.text = ""
    }

    func paygoViewModel(_ viewModel: PaygoViewModel, didSubmitFailure message: String) {
        showResult(text: message, color: AppColors.error)
    }

    func paygoViewModel(_ viewModel: PaygoViewModel, didUpdateInfo info: String) {
        infoLabel.text = info
    }

    func paygoViewModel(_ viewModel: PaygoViewModel, didGetBlocked remainingSeconds: Int) {
        showResult(text: "Blocked. Wait \(remainingSeconds)s", color: AppColors.error)
    }
}
