import UIKit
import SnapKit

/// Faulty Alert 標籤頁 — 顯示解析後的錯誤代碼、事件和解決方案
final class FaultyAlertViewController: UIViewController {

    // MARK: - 屬性

    private let viewModel = FaultyAlertViewModel()

    // MARK: - UI 元件

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    /// 無告警時的提示文字
    private let noAlertLabel: UILabel = {
        let label = UILabel()
        label.text = "No active faults or warnings"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        return label
    }()

    // MARK: - 生命週期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupUI()
        viewModel.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.startPolling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopPolling()
    }

    // MARK: - UI 佈局

    private func setupUI() {
        scrollView.showsVerticalScrollIndicator = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-16)
            make.width.equalTo(scrollView).offset(-40)
        }

        view.addSubview(noAlertLabel)
        noAlertLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    /// 更新故障列表顯示
    private func updateFaultDisplay() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let items = viewModel.faultItems
        noAlertLabel.isHidden = !items.isEmpty
        scrollView.isHidden = items.isEmpty

        for item in items {
            let faultView = FaultItemView(item: item)
            contentStack.addArrangedSubview(faultView)

            let separator = UIView()
            separator.backgroundColor = AppColors.separator
            separator.snp.makeConstraints { make in
                make.height.equalTo(0.5)
            }
            contentStack.addArrangedSubview(separator)
        }
    }
}

// MARK: - FaultyAlertViewModelDelegate

extension FaultyAlertViewController: FaultyAlertViewModelDelegate {

    func faultyAlertViewModelDidUpdate(_ viewModel: FaultyAlertViewModel) {
        updateFaultDisplay()
    }

    func faultyAlertViewModel(_ viewModel: FaultyAlertViewModel, didFailWithError error: String) {
        // 靜默處理，下次輪詢時重試
    }
}

// MARK: - 故障項目視圖

/// 單條故障記錄行，顯示代碼、事件和解決方案
private final class FaultItemView: UIView {

    init(item: FaultItem) {
        super.init(frame: .zero)
        setupUI(with: item)
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    private func setupUI(with item: FaultItem) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill

        stack.addArrangedSubview(createRow(label: "Faulty code:", value: item.code, valueColor: AppColors.error))
        stack.addArrangedSubview(createRow(label: "Faulty Event:", value: item.event, valueColor: AppColors.error))
        stack.addArrangedSubview(createRow(label: "Faulty solution:", value: item.solution, valueColor: AppColors.error))

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    private func createRow(label: String, value: String, valueColor: UIColor) -> UIView {
        let container = UIView()

        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        labelView.textColor = AppColors.textPrimary
        labelView.setContentHuggingPriority(.required, for: .horizontal)

        let valueView = UILabel()
        valueView.text = value
        valueView.font = UIFont.systemFont(ofSize: 14)
        valueView.textColor = valueColor
        valueView.numberOfLines = 0

        container.addSubview(labelView)
        container.addSubview(valueView)

        labelView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        valueView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(labelView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview()
        }

        return container
    }
}
