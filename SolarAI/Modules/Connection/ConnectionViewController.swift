import UIKit
import SnapKit

/// 登入/连接页面，匹配 Android 端 UI 布局：
/// 左侧：背景图 + 底部标题/版本号
/// 中间：BT NAME / BT PASSWORD 表单（底线风格）
/// 右侧：「Refresh the BT List」按钮 + WiFi 提示
///
/// 交互流程：
/// 1. 点「Refresh the BT List」→ 跳转 iOS WiFi 设定
/// 2. 用户在设定中连接 SSE WiFi → 返回 App
/// 3. App 自动侦测网络变化 → Ping 设备
/// 4. Ping 成功 → 自动跳转主页
final class ConnectionViewController: UIViewController {

    // MARK: - 属性

    private let viewModel = ConnectionViewModel()

    // MARK: - UI 元件

    /// 左侧背景图
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = UIImage(named: "login_bg")
        return iv
    }()

    /// 左上角返回按钮
    private let returnButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        btn.setTitle(" Return", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.tintColor = .white
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btn.contentHorizontalAlignment = .left
        return btn
    }()

    /// 左下角 App 标题
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = AppConfig.appName
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 2
        return label
    }()

    /// 左下角版本号
    private let versionLabel: UILabel = {
        let label = UILabel()
        label.text = "version:\(AppConfig.appVersion)"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = AppColors.textSecondary
        return label
    }()

    // MARK: - 表单元件

    private let formContainer = UIView()

    private let btNameLabel: UILabel = {
        let label = UILabel()
        label.text = "BT NAME:"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppColors.textSecondary
        return label
    }()

    /// 显示选中的设备名称
    private let btNameValueLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let btNameUnderline: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.separator
        return v
    }()

    private let btPasswordLabel: UILabel = {
        let label = UILabel()
        label.text = "BT PASSWORD:"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppColors.textSecondary
        return label
    }()

    /// 密码输入框（预填 SSE123456）
    private let passwordField: UITextField = {
        let tf = UITextField()
        tf.backgroundColor = .clear
        tf.textColor = AppColors.textPrimary
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.isSecureTextEntry = true
        tf.text = AppConfig.defaultPassword
        tf.borderStyle = .none
        return tf
    }()

    /// 密码显示/隐藏切换按钮
    private let togglePasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16)
        btn.setImage(UIImage(systemName: "eye.slash.fill", withConfiguration: config), for: .normal)
        btn.tintColor = AppColors.textSecondary
        return btn
    }()

    private let passwordUnderline: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.separator
        return v
    }()

    /// 橙色描边连接按钮
    private let connectButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Click to connect", for: .normal)
        btn.setTitleColor(AppColors.accent, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        btn.backgroundColor = .clear
        btn.layer.cornerRadius = 20
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = AppColors.accent.cgColor
        return btn
    }()

    /// 测试入口按钮（跳过WiFi连接直接进入主页）
    private let testButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Test Entry", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        btn.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        btn.layer.cornerRadius = 14
        return btn
    }()

    // MARK: - 右侧面板

    /// 右侧浅灰面板
    private let rightPanel: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.93, alpha: 1.0)
        return v
    }()

    /// 刷新按钮（跳转 WiFi 设定）
    private let refreshButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.contentHorizontalAlignment = .center
        return btn
    }()

    private let refreshSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.82, alpha: 1.0)
        return v
    }()

    /// WiFi 提示图示
    private let wifiHintIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .light)
        iv.image = UIImage(systemName: "wifi", withConfiguration: config)
        iv.tintColor = UIColor(white: 0.75, alpha: 1.0)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// 提示文字
    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap above to open WiFi Settings.\nConnect to the SSE WiFi,\nthen return here."
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.gray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    /// 连接状态文字
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = AppColors.accent
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    /// 全屏载入遮罩
    private let loadingView = LoadingView()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        updateRefreshButtonTitle()
        viewModel.delegate = self
        viewModel.startObserving()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.resetState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeLeft }

    // MARK: - UI 布局

    private func setupUI() {
        view.backgroundColor = AppColors.background

        view.addSubview(backgroundImageView)
        view.addSubview(returnButton)
        view.addSubview(titleLabel)
        view.addSubview(versionLabel)
        view.addSubview(formContainer)
        view.addSubview(rightPanel)
        view.addSubview(loadingView)

        formContainer.addSubview(btNameLabel)
        formContainer.addSubview(btNameValueLabel)
        formContainer.addSubview(btNameUnderline)
        formContainer.addSubview(btPasswordLabel)
        formContainer.addSubview(passwordField)
        formContainer.addSubview(togglePasswordButton)
        formContainer.addSubview(passwordUnderline)
        formContainer.addSubview(connectButton)

        rightPanel.addSubview(refreshButton)
        rightPanel.addSubview(refreshSeparator)
        rightPanel.addSubview(wifiHintIcon)
        rightPanel.addSubview(hintLabel)
        rightPanel.addSubview(statusLabel)

        // 右侧面板
        rightPanel.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.width.equalTo(200)
        }

        refreshButton.snp.makeConstraints { make in
            make.top.equalTo(rightPanel.safeAreaLayoutGuide).offset(10)
            make.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(36)
        }

        refreshSeparator.snp.makeConstraints { make in
            make.top.equalTo(refreshButton.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        wifiHintIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-30)
            make.size.equalTo(40)
        }

        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(wifiHintIcon.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(refreshSeparator.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        // 左侧背景图
        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.50)
        }

        // 返回按钮
        returnButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(4)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.height.equalTo(30)
        }

        // 标题 + 版本（左下角）
        versionLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(versionLabel.snp.top).offset(-4)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.lessThanOrEqualTo(formContainer.snp.leading).offset(-10)
        }

        // 表单区域（背景图和右侧面板之间）
        formContainer.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-10)
            make.leading.equalTo(backgroundImageView.snp.trailing).offset(24)
            make.trailing.equalTo(rightPanel.snp.leading).offset(-24)
        }

        // BT NAME
        btNameLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        btNameValueLabel.snp.makeConstraints { make in
            make.top.equalTo(btNameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(24)
        }

        btNameUnderline.snp.makeConstraints { make in
            make.top.equalTo(btNameValueLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        // BT PASSWORD
        btPasswordLabel.snp.makeConstraints { make in
            make.top.equalTo(btNameUnderline.snp.bottom).offset(20)
            make.leading.equalToSuperview()
        }

        togglePasswordButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.size.equalTo(30)
        }

        passwordField.snp.makeConstraints { make in
            make.top.equalTo(btPasswordLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview()
            make.trailing.equalTo(togglePasswordButton.snp.leading).offset(-8)
            make.height.equalTo(24)
        }

        togglePasswordButton.snp.makeConstraints { make in
            make.centerY.equalTo(passwordField)
        }

        passwordUnderline.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        // 连接按钮
        connectButton.snp.makeConstraints { make in
            make.top.equalTo(passwordUnderline.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.width.equalTo(180)
            make.height.equalTo(40)
        }

        // 测试入口按钮
        formContainer.addSubview(testButton)
        testButton.snp.makeConstraints { make in
            make.top.equalTo(connectButton.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(28)
            make.bottom.equalToSuperview()
        }

        // 载入遮罩
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadingView.isHidden = true
    }

    private func setupActions() {
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        togglePasswordButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        returnButton.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)
        testButton.addTarget(self, action: #selector(testEntryTapped), for: .touchUpInside)

        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    /// 更新刷新按钮标题
    private func updateRefreshButtonTitle() {
        let icon = UIImage(systemName: "arrow.clockwise")?
            .withTintColor(.darkGray, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 13, weight: .medium))
        let attachment = NSTextAttachment()
        attachment.image = icon
        let attrStr = NSMutableAttributedString(attachment: attachment)
        attrStr.append(NSAttributedString(
            string: "  Refresh the BT List",
            attributes: [.foregroundColor: UIColor.darkGray,
                         .font: UIFont.systemFont(ofSize: 13, weight: .medium)]
        ))
        refreshButton.setAttributedTitle(attrStr, for: .normal)
    }

    // MARK: - 事件处理

    @objc private func connectTapped() {
        view.endEditing(true)
        viewModel.connectManually()
    }

    @objc private func refreshTapped() {
        viewModel.openWiFiSettings()
    }

    @objc private func togglePasswordVisibility() {
        passwordField.isSecureTextEntry.toggle()
        let name = passwordField.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 16)
        togglePasswordButton.setImage(UIImage(systemName: name, withConfiguration: config), for: .normal)
    }

    @objc private func returnTapped() {
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
    }

    @objc private func testEntryTapped() {
        navigateToMain(deviceName: "TestDevice")
    }

    @objc private func appWillEnterForeground() {
        viewModel.appDidBecomeActive()
    }

    // MARK: - 页面跳转

    private func navigateToMain(deviceName: String) {
        let mainVC = MainContainerViewController(deviceName: deviceName)
        navigationController?.pushViewController(mainVC, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ConnectionViewModelDelegate

extension ConnectionViewController: ConnectionViewModelDelegate {

    func didStartPinging() {
        loadingView.show(message: "Wifi connecting")
        statusLabel.isHidden = true
    }

    func didUpdateStatus(_ message: String) {
        loadingView.updateMessage(message)
    }

    func didConnectSuccessfully() {
        loadingView.updateMessage("Device connecting")
        let deviceName = btNameValueLabel.text?.isEmpty == false
            ? btNameValueLabel.text! : "SSE Device"

        statusLabel.text = "✓ Connected"
        statusLabel.textColor = AppColors.confirm
        statusLabel.isHidden = false
        hintLabel.isHidden = true
        wifiHintIcon.isHidden = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.loadingView.hide()
            self?.navigateToMain(deviceName: deviceName)
        }
    }

    func didFailToConnect(error: String) {
        loadingView.hide()
        statusLabel.text = error
        statusLabel.textColor = AppColors.error
        statusLabel.isHidden = false
    }
}
