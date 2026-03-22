import UIKit
import SnapKit

/// Faulty Alert 标签页 — 以表格形式显示故障代码、事件和解决方案
final class FaultyAlertViewController: UIViewController {

    // MARK: - 属性

    private let viewModel = FaultyAlertViewModel()

    // MARK: - UI 元件

    private let scrollView = UIScrollView()

    /// 表格容器（包含表头 + 数据行）
    private let tableStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        sv.alignment = .fill
        return sv
    }()

    /// 无告警时的提示文字
    private let noAlertLabel: UILabel = {
        let label = UILabel()
        label.text = "No active faults or warnings"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        return label
    }()

    // MARK: - 常量

    private let borderColor = UIColor(white: 0.35, alpha: 1.0).cgColor
    private let headerBgColor = UIColor(red: 0.15, green: 0.25, blue: 0.30, alpha: 1.0)
    private let rowBgColor = UIColor(red: 0.12, green: 0.22, blue: 0.27, alpha: 1.0)

    // MARK: - 生命周期

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

    // MARK: - UI 布局

    private func setupUI() {
        scrollView.showsVerticalScrollIndicator = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(tableStack)
        tableStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
            make.width.equalTo(scrollView).offset(-32)
        }

        view.addSubview(noAlertLabel)
        noAlertLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    /// 更新故障列表
    private func updateFaultDisplay() {
        tableStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let items = viewModel.faultItems
        noAlertLabel.isHidden = !items.isEmpty
        scrollView.isHidden = items.isEmpty

        guard !items.isEmpty else { return }

        // 表头行
        let header = makeRow(
            col1: "Faulty code:",
            col2: "Faulty Event:",
            col3: "Faulty solution:",
            textColor: AppColors.textPrimary,
            bgColor: headerBgColor,
            font: .systemFont(ofSize: 13, weight: .semibold)
        )
        tableStack.addArrangedSubview(header)

        // 数据行
        for item in items {
            let row = makeRow(
                col1: item.code,
                col2: item.event,
                col3: item.solution,
                textColor: AppColors.error,
                bgColor: rowBgColor,
                font: .systemFont(ofSize: 13)
            )
            tableStack.addArrangedSubview(row)
        }

        // 外边框
        tableStack.layoutIfNeeded()
        addTableBorder()
    }

    // MARK: - 表格行构建

    /// 创建一个三列的行
    private func makeRow(
        col1: String,
        col2: String,
        col3: String,
        textColor: UIColor,
        bgColor: UIColor,
        font: UIFont
    ) -> UIView {
        let row = UIView()
        row.backgroundColor = bgColor

        let label1 = makeLabel(text: col1, color: textColor, font: font)
        let label2 = makeLabel(text: col2, color: textColor, font: font)
        let label3 = makeLabel(text: col3, color: textColor, font: font)

        let divider1 = makeVerticalDivider()
        let divider2 = makeVerticalDivider()

        row.addSubview(label1)
        row.addSubview(divider1)
        row.addSubview(label2)
        row.addSubview(divider2)
        row.addSubview(label3)

        // 三列比例: Faulty code (~22%), Faulty Event (~38%), Faulty solution (~40%)
        label1.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.width.equalToSuperview().multipliedBy(0.20)
        }

        divider1.snp.makeConstraints { make in
            make.leading.equalTo(label1.snp.trailing).offset(10)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(0.5)
        }

        label2.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalTo(divider1.snp.trailing).offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.width.equalToSuperview().multipliedBy(0.33)
        }

        divider2.snp.makeConstraints { make in
            make.leading.equalTo(label2.snp.trailing).offset(10)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(0.5)
        }

        label3.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalTo(divider2.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-10)
        }

        // 行底部分隔线
        let bottomLine = UIView()
        bottomLine.backgroundColor = UIColor(white: 0.35, alpha: 1.0)
        row.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        return row
    }

    private func makeLabel(text: String, color: UIColor, font: UIFont) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = color
        label.font = font
        label.numberOfLines = 0
        return label
    }

    private func makeVerticalDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.35, alpha: 1.0)
        return v
    }

    // MARK: - 外边框

    private var tableBorderLayer: CAShapeLayer?

    private func addTableBorder() {
        tableBorderLayer?.removeFromSuperlayer()

        let border = CAShapeLayer()
        border.strokeColor = borderColor
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 0.5
        border.frame = tableStack.bounds
        border.path = UIBezierPath(rect: tableStack.bounds).cgPath
        tableStack.layer.addSublayer(border)
        tableBorderLayer = border
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !viewModel.faultItems.isEmpty {
            addTableBorder()
        }
    }
}

// MARK: - FaultyAlertViewModelDelegate

extension FaultyAlertViewController: FaultyAlertViewModelDelegate {

    func faultyAlertViewModelDidUpdate(_ viewModel: FaultyAlertViewModel) {
        updateFaultDisplay()
    }

    func faultyAlertViewModel(_ viewModel: FaultyAlertViewModel, didFailWithError error: String) {
        // 静默处理，下次轮询时重试
    }
}
