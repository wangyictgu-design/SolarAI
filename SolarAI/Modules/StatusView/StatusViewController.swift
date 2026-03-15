import UIKit
import SnapKit

/// Status View 標籤頁 — 顯示能源流向圖及即時數據標籤
///
/// 標籤位置對照設計稿（image4.png）：
/// - PV 數據：右上方（太陽能板區域上方）
/// - Grid 數據：右側中間（電網塔旁邊）
/// - Invert 數據：中間偏右（逆變器設備旁）
/// - Load 數據：底部中間偏左（房子下方）
/// - Batt 數據：底部右側（電池旁邊）
final class StatusViewController: UIViewController {

    // MARK: - 屬性

    private let viewModel = StatusViewModel()

    // MARK: - UI 元件

    /// 能源流向動畫圖
    private let energyFlowView = EnergyFlowView()

    // PV 數據標籤（太陽能板）
    private let pvChargerPLabel = DataLabel(prefix: "PV Charger P:")
    private let pvVoltLabel = DataLabel(prefix: "PV Volt:")
    private let pvChargerCurLabel = DataLabel(prefix: "PV Charger Cur:")

    // 逆變器數據標籤
    private let invertVoltLabel = DataLabel(prefix: "Invert Volt:")
    private let invertCurLabel = DataLabel(prefix: "Invert Cur:")

    // 電網數據標籤
    private let gridPLabel = DataLabel(prefix: "Grid P:")
    private let gridCurLabel = DataLabel(prefix: "Grid Cur:")
    private let gridVoltLabel = DataLabel(prefix: "Grid Volt:")

    // 負載數據標籤
    private let sloadLabel = DataLabel(prefix: "SLoad:")
    private let ploadLabel = DataLabel(prefix: "PLoad:")
    private let totalLabel = DataLabel(prefix: "Total:")

    // 電池數據標籤
    private let battVoltLabel = DataLabel(prefix: "Batt Volt:")
    private let battSOCLabel = DataLabel(prefix: "Batt SOC:")

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
        view.addSubview(energyFlowView)

        // 能源流向圖：偏左居中顯示
        energyFlowView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
        }

        // PV 數據 — 太陽上方，使用百分比定位適配不同機型
        let pvStack = makeStack([pvChargerPLabel, pvVoltLabel, pvChargerCurLabel], alignment: .trailing)
        view.addSubview(pvStack)
        pvStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.trailing.equalTo(view.snp.trailing).multipliedBy(0.78)
        }

        // Grid 數據 — 電網塔旁邊，PV 下方，使用百分比靠近圖標
        let gridStack = makeStack([gridPLabel, gridCurLabel, gridVoltLabel], alignment: .trailing)
        view.addSubview(gridStack)
        gridStack.snp.makeConstraints { make in
            make.top.equalTo(pvStack.snp.bottom).offset(8)
            make.trailing.equalTo(view.snp.trailing).multipliedBy(0.88)
        }

        // Invert 數據 — 逆變器旁邊，往左上調整避免與圖標重疊
        let invertStack = makeStack([invertVoltLabel, invertCurLabel], alignment: .trailing)
        view.addSubview(invertStack)
        invertStack.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-35)
            make.trailing.equalTo(view.snp.trailing).multipliedBy(0.65)
        }

        // Batt 數據 — 電池旁邊，使用百分比定位往上貼近電池圖標
        let battStack = makeStack([battVoltLabel, battSOCLabel], alignment: .leading)
        view.addSubview(battStack)
        battStack.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottom).multipliedBy(0.86)
            make.leading.equalTo(view.snp.trailing).multipliedBy(0.65)
        }

        // Load 數據 — 房子下方，底部中間偏左
        let loadStack = makeStack([sloadLabel, ploadLabel, totalLabel], alignment: .leading)
        view.addSubview(loadStack)
        loadStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-12)
            make.centerX.equalToSuperview().offset(-50)
        }

        setDefaultValues()
    }

    /// 建立垂直堆疊視圖
    private func makeStack(_ views: [UIView], alignment: UIStackView.Alignment) -> UIStackView {
        let sv = UIStackView(arrangedSubviews: views)
        sv.axis = .vertical
        sv.spacing = 2
        sv.alignment = alignment
        return sv
    }

    /// 設定預設數值
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

    /// 更新所有數據標籤
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
        // 靜默處理，下次輪詢時重試
    }
}

// MARK: - 數據標籤

/// 顯示「前綴: 數值」格式的小標籤（如「PV Volt: 0.0 V」）
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
