import UIKit
import SnapKit
import CoreLocation

/// 主容器视图控制器：顶部水平标签栏 + 下方内容区
/// 管理子视图控制器：General、StatusView、FaultyAlert、Paygo
final class MainContainerViewController: UIViewController {

    // MARK: - 属性

    /// 无法读取 SSID 时「Connected」副标题的兜底（通常来自蓝牙名）
    private let fallbackConnectedSubtitle: String
    private var topTabBar: TopTabBarView!
    private let contentContainer = UIView()
    private var childControllers: [UIViewController] = []
    private var currentChildIndex: Int = -1

    /// 部分系统版本下读取 SSID 需定位授权；仅用于读 Wi-Fi 名，不用于追踪位置
    private let ssidLocationManager = CLLocationManager()
    private var didAttemptLocationRequestForSSID = false

    // MARK: - 初始化

    init(fallbackConnectedSubtitle: String) {
        self.fallbackConnectedSubtitle = fallbackConnectedSubtitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        ssidLocationManager.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupChildControllers()
        setupUI()
        showChild(at: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        topTabBar.updateConnectedSubtitle(resolvedConnectedSubtitle())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshConnectedWiFiNameAsync()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeLeft }

    // MARK: - 设置

    /// 创建四个子视图控制器
    private func setupChildControllers() {
        let generalVC = GeneralViewController(deviceName: fallbackConnectedSubtitle)
        let statusVC = StatusViewController()
        let faultyVC = FaultyAlertViewController()
        let paygoVC = PaygoViewController()
        childControllers = [generalVC, statusVC, faultyVC, paygoVC]
    }

    /// 设置顶部标签栏与内容区布局
    private func setupUI() {
        view.backgroundColor = AppColors.background

        topTabBar = TopTabBarView(connectedSubtitle: resolvedConnectedSubtitle())
        topTabBar.delegate = self

        view.addSubview(topTabBar)
        view.addSubview(contentContainer)

        // 顶部标签栏：高度 50，贴齐顶部
        topTabBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }

        // 内容区：紧贴标签栏下方，填满剩余空间
        contentContainer.snp.makeConstraints { make in
            make.top.equalTo(topTabBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func resolvedConnectedSubtitle() -> String {
        if let ssid = WiFiManager.shared.currentWiFiSSID(), !ssid.isEmpty {
            return ssid
        }
        return fallbackConnectedSubtitle
    }

    /// 异步再取 SSID（NEHotspotNetwork）；失败则按需申请定位 / 精确位置后重试。
    /// 需：`SolarAI.entitlements` 含 `wifi-info` + Xcode 已设置 CODE_SIGN_ENTITLEMENTS，且 App ID 勾选 Access WiFi Information。
    private func refreshConnectedWiFiNameAsync() {
        if ssidLocationManager.authorizationStatus == .notDetermined {
            ssidLocationManager.requestWhenInUseAuthorization()
        }
        if #available(iOS 14.0, *) {
            let auth = ssidLocationManager.authorizationStatus
            if auth == .authorizedWhenInUse || auth == .authorizedAlways,
               ssidLocationManager.accuracyAuthorization == .reducedAccuracy {
                ssidLocationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "WiFiSSIDReason") { [weak self] _ in
                    self?.performFetchCurrentSSIDForTabBar()
                }
                return
            }
        }
        performFetchCurrentSSIDForTabBar()
    }

    private func performFetchCurrentSSIDForTabBar() {
        WiFiManager.shared.fetchCurrentWiFiSSID { [weak self] ssid in
            DispatchQueue.main.async {
                guard let self else { return }
                if let ssid, !ssid.isEmpty {
                    self.topTabBar.updateConnectedSubtitle(ssid)
                } else {
                    self.requestLocationPermissionForSSIDIfNeeded()
                }
            }
        }
    }

    private func requestLocationPermissionForSSIDIfNeeded() {
        guard !didAttemptLocationRequestForSSID else {
            applySSIDOrFallbackToTabBar()
            return
        }
        switch ssidLocationManager.authorizationStatus {
        case .notDetermined:
            didAttemptLocationRequestForSSID = true
            ssidLocationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            didAttemptLocationRequestForSSID = true
            applySSIDOrFallbackToTabBar()
        default:
            didAttemptLocationRequestForSSID = true
            break
        }
    }

    private func applySSIDOrFallbackToTabBar() {
        WiFiManager.shared.fetchCurrentWiFiSSID { [weak self] ssid in
            DispatchQueue.main.async {
                guard let self else { return }
                let text = (ssid?.isEmpty == false) ? ssid! : self.fallbackConnectedSubtitle
                self.topTabBar.updateConnectedSubtitle(text)
            }
        }
    }

    // MARK: - 子视图控制器管理

    /// 切换显示指定索引的子视图控制器
    private func showChild(at index: Int) {
        guard index >= 0, index < childControllers.count, index != currentChildIndex else { return }

        // 移除当前子控制器
        if currentChildIndex >= 0 && currentChildIndex < childControllers.count {
            let current = childControllers[currentChildIndex]
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        // 加入并显示新子控制器
        let child = childControllers[index]
        addChild(child)
        contentContainer.addSubview(child.view)
        child.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        child.didMove(toParent: self)

        currentChildIndex = index
    }

    // MARK: - 退出确认对话框

    private func showExitDialog() {
        let exitView = ExitConfirmView()
        exitView.delegate = self
        exitView.show(in: view)
    }
}

// MARK: - CLLocationManagerDelegate

extension MainContainerViewController: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            refreshConnectedWiFiNameAsync()
        default:
            break
        }
    }
}

// MARK: - TopTabBarViewDelegate

extension MainContainerViewController: TopTabBarViewDelegate {

    func topTabBarView(_ view: TopTabBarView, didSelectTabAt index: Int) {
        showChild(at: index)
    }

    func topTabBarViewDidTapConnected(_ view: TopTabBarView) {
        showExitDialog()
    }
}

// MARK: - ExitConfirmViewDelegate

extension MainContainerViewController: ExitConfirmViewDelegate {

    func didCancel(_ view: ExitConfirmView) {
        view.dismiss()
    }

    func didConfirm(_ view: ExitConfirmView) {
        view.dismiss()
        navigationController?.popToRootViewController(animated: true)
    }
}
