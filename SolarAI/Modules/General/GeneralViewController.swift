import UIKit
import SnapKit

/// General 标签页 — 显示连接状态、硬件模组网格、设备版本
final class GeneralViewController: UIViewController {

    // MARK: - 属性

    private let viewModel = GeneralViewModel()
    private let deviceName: String

    // MARK: - UI 元件

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    /// 连接状态区段标题
    private let connectStateHeader = SectionHeaderView(title: "Connect state")

    /// 连接状态图示网格（Heartbeat, Bluetooth, WiFi, 4G, GPS）
    private lazy var connectCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 6
        layout.minimumInteritemSpacing = 6
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.tag = 0
        cv.register(HardwareStatusCell.self, forCellWithReuseIdentifier: HardwareStatusCell.reuseIdentifier)
        cv.isScrollEnabled = false
        return cv
    }()

    /// 硬件状态区段标题
    private let hardwareStateHeader = SectionHeaderView(title: "Hardware state")

    /// 硬件状态图示网格（PV Input, Load, Battery 等）
    private lazy var hardwareCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 6
        layout.minimumInteritemSpacing = 6
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.tag = 1
        cv.register(HardwareStatusCell.self, forCellWithReuseIdentifier: HardwareStatusCell.reuseIdentifier)
        cv.isScrollEnabled = false
        return cv
    }()

    /// 基本信息区段标题
    private let baseInfoHeader = SectionHeaderView(title: "BaseInfo")

    /// 设备版本标签
    private let versionLabel: UILabel = {
        let label = UILabel()
        label.text = "Device version: --"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = AppColors.textPrimary
        return label
    }()

    /// 连接状态的图示（前 5 个：Heartbeat ~ GPS）
    private var connectIcons: [HardwareIcon] {
        return Array(HardwareIcon.allCases.prefix(5))
    }

    /// 硬件状态的图示（后 11 个：PV Input ~ CT）
    private var hardwareIcons: [HardwareIcon] {
        return Array(HardwareIcon.allCases.dropFirst(5))
    }

    // MARK: - 初始化

    init(deviceName: String) {
        self.deviceName = deviceName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 6
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-12)
            make.width.equalTo(scrollView).offset(-40)
        }

        // 连接状态区段（5 个图示 → 1 行）
        contentStack.addArrangedSubview(connectStateHeader)
        contentStack.addArrangedSubview(connectCollectionView)
        connectCollectionView.snp.makeConstraints { make in
            make.height.equalTo(70)
        }

        // 硬件状态区段（11 个图示 → 2 行）
        contentStack.addArrangedSubview(hardwareStateHeader)
        contentStack.addArrangedSubview(hardwareCollectionView)
        hardwareCollectionView.snp.makeConstraints { make in
            make.height.equalTo(145)
        }

        // 基本信息区段
        contentStack.addArrangedSubview(baseInfoHeader)
        contentStack.addArrangedSubview(versionLabel)
    }
}

// MARK: - GeneralViewModelDelegate

extension GeneralViewController: GeneralViewModelDelegate {

    func generalViewModelDidUpdateData(_ viewModel: GeneralViewModel) {
        versionLabel.text = "Device version: \(viewModel.deviceVersion)"
        connectCollectionView.reloadData()
        hardwareCollectionView.reloadData()
    }

    func generalViewModel(_ viewModel: GeneralViewModel, didFailWithError error: String) {
        // 静默处理，下次轮询时重试
    }
}

// MARK: - UICollectionView 资料源和代理

extension GeneralViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView.tag == 0 ? connectIcons.count : hardwareIcons.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HardwareStatusCell.reuseIdentifier, for: indexPath
        ) as! HardwareStatusCell
        let icon = collectionView.tag == 0 ? connectIcons[indexPath.item] : hardwareIcons[indexPath.item]
        let isActive = viewModel.activeHardwareModules.contains(icon.rawValue)
        cell.configure(icon: icon, isActive: isActive)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let columns: CGFloat = 6
        let spacing: CGFloat = 6
        let totalSpacing = spacing * (columns - 1)
        let width = (collectionView.bounds.width - totalSpacing) / columns
        return CGSize(width: width, height: 65)
    }
}

// MARK: - 区段标题视图

/// 带橙色竖条的区段标题（如「Connect state」「Hardware state」「BaseInfo」）
final class SectionHeaderView: UIView {

    private let accentBar: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.accent
        v.layer.cornerRadius = 1.5
        return v
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = AppColors.textPrimary
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(accentBar)
        addSubview(titleLabel)

        accentBar.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(3)
            make.height.equalTo(18)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(accentBar.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        self.snp.makeConstraints { make in
            make.height.equalTo(28)
        }
    }
}
