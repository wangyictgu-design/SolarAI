import UIKit
import SnapKit

/// Status View 标签页 — 显示能源流向图及即时数据标签
///
/// 标签位置对照设计稿（image4.png）：
/// - PV 数据：右上方（太阳能板区域上方）
/// - Grid 数据：右侧中间（电网塔旁边）
/// - Invert 数据：中间偏右（逆变器设备旁）
/// - Load 数据：底部中间偏左（房子下方）
/// - Batt 数据：底部右侧（电池旁边）
final class StatusViewController: UIViewController {

    // MARK: - 属性

    private let viewModel = StatusViewModel()

    // MARK: - UI 元件

    /// 能源流向动画图
    private let energyFlowView = EnergyFlowView()

    // PV 数据标签（太阳能板）
    private let pvChargerPLabel = DataLabel(prefix: "PV Charger P:")
    private let pvVoltLabel = DataLabel(prefix: "PV Volt:")
    private let pvChargerCurLabel = DataLabel(prefix: "PV Charger Cur:")

    // 逆变器数据标签
    private let invertVoltLabel = DataLabel(prefix: "Invert Volt:")
    private let invertCurLabel = DataLabel(prefix: "Invert Cur:")

    // 电网数据标签
    private let gridPLabel = DataLabel(prefix: "Grid P:")
    private let gridCurLabel = DataLabel(prefix: "Grid Cur:")
    private let gridVoltLabel = DataLabel(prefix: "Grid Volt:")

    // 负载数据标签
    private let sloadLabel = DataLabel(prefix: "SLoad:")
    private let ploadLabel = DataLabel(prefix: "PLoad:")
    private let totalLabel = DataLabel(prefix: "Total:")

    // 电池数据标签
    private let battVoltLabel = DataLabel(prefix: "Batt Volt:")
    private let battSOCLabel = DataLabel(prefix: "Batt SOC:")

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
        view.addSubview(energyFlowView)

        // 能源流向图：偏左居中显示
        energyFlowView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
        }

        // PV 数据 — 太阳上方，使用百分比定位适配不同机型
        let pvStack = makeStack([pvChargerPLabel, pvVoltLabel, pvChargerCurLabel], alignment: .trailing)
        view.addSubview(pvStack)
        pvStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.trailing.equalTo(view.snp.trailing).multipliedBy(0.66)
        }

        // Grid 数据 — 电网塔旁边，PV 下方，使用百分比靠近图标
        let gridStack = makeStack([gridPLabel, gridCurLabel, gridVoltLabel], alignment: .trailing)
        view.addSubview(gridStack)
        gridStack.snp.makeConstraints { make in
            make.top.equalTo(pvStack.snp.bottom).offset(28)
            make.trailing.equalTo(view.snp.trailing).multipliedBy(0.88).offset(-21)
        }

        // Invert 数据 — 逆变器旁边，往左上调整避免与图标重叠
        let invertStack = makeStack([invertVoltLabel, invertCurLabel], alignment: .trailing)
        view.addSubview(invertStack)
        invertStack.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-15)
            make.trailing.equalTo(view.snp.trailing).multipliedBy(0.68)
        }

        // Batt 数据 — 电池旁边，使用百分比定位往上贴近电池图标
        let battStack = makeStack([battVoltLabel, battSOCLabel], alignment: .leading)
        view.addSubview(battStack)
        battStack.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottom).multipliedBy(0.86)
            make.leading.equalTo(view.snp.trailing).multipliedBy(0.674)
        }

        // Load 数据 — 房子下方，底部中间偏左
        let loadStack = makeStack([sloadLabel, ploadLabel, totalLabel], alignment: .leading)
        view.addSubview(loadStack)
        loadStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-12)
            make.centerX.equalToSuperview().offset(-50)
        }

        setDefaultValues()
    }

    /// 建立垂直堆叠视图
    private func makeStack(_ views: [UIView], alignment: UIStackView.Alignment) -> UIStackView {
        let sv = UIStackView(arrangedSubviews: views)
        sv.axis = .vertical
        sv.spacing = 2
        sv.alignment = alignment
        return sv
    }

    /// 设定预设数值
    private func setDefaultValues() {
        pvChargerPLabel.setValue("0 W")
        pvVoltLabel.setValue("0.0 V")
        pvChargerCurLabel.setValue("0.0 A")
        invertVoltLabel.setValue("0.0 V")
        invertCurLabel.setValue("0.0 A")
        gridPLabel.setValue("0 W")
        gridCurLabel.setValue("0.0 A")
        gridVoltLabel.setValue("0.0 V")
        sloadLabel.setValue("0 VA")
        ploadLabel.setValue("0 W")
        totalLabel.setValue("0.0 kwh")
        battVoltLabel.setValue("0.0 V")
        battSOCLabel.setValue("0 %")
    }

    /// 更新所有数据标签
    private func updateDataLabels(_ status: DeviceStatusResponse) {
        pvChargerPLabel.setValue(status.pvChargerPwrDisplay)
        pvVoltLabel.setValue(status.pvVoltDisplay)
        pvChargerCurLabel.setValue(status.pvChargerCurDisplay)
        invertVoltLabel.setValue(status.inverterVoltDisplay)
        invertCurLabel.setValue(status.inverterCurDisplay)
        gridPLabel.setValue(status.pgridDisplay)
        gridCurLabel.setValue(status.gridCurDisplay)
        gridVoltLabel.setValue(status.gridVoltDisplay)
        sloadLabel.setValue(status.sloadDisplay)
        ploadLabel.setValue(status.ploadDisplay)
        totalLabel.setValue(status.totalKwhDisplay)
        battVoltLabel.setValue(status.battVoltDisplay)

        battSOCLabel.isHidden = !status.shouldShowBattSOC
        if status.shouldShowBattSOC {
            battSOCLabel.setValue(status.bmsSocDisplay)
        }
    }
}

// MARK: - StatusViewModelDelegate

extension StatusViewController: StatusViewModelDelegate {

    func statusViewModelDidUpdateStatus(_ viewModel: StatusViewModel) {
        guard let status = viewModel.deviceStatus else { return }
        updateDataLabels(status)
    }

    func statusViewModelDidUpdateFlow(_ viewModel: StatusViewModel, flowType: EnergyFlowType) {
        energyFlowView.updateFlowType(flowType)
    }

    func statusViewModel(_ viewModel: StatusViewModel, didFailWithError error: String) {
        // 静默处理，下次轮询时重试
    }
}

// MARK: - 数据标签

/// 显示「前缀: 数值」格式的小标签（如「PV Volt: 0.0 V」）
private final class DataLabel: UIView {

    private let label: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        l.textColor = AppColors.textPrimary
        return l
    }()

    private let prefix: String

    init(prefix: String) {
        self.prefix = prefix
        super.init(frame: .zero)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        self.prefix = ""
        super.init(coder: coder)
    }

    func setValue(_ value: String) {
        label.text = "\(prefix) \(value)"
    }
}
