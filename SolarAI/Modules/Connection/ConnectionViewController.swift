import UIKit

/// Login/connection screen matching the Android app layout:
/// Left: background image + title/version at bottom
/// Center: BT NAME / BT PASSWORD form with underline fields
/// Right: "Refresh the BT List" button + scanned SSE device list
final class ConnectionViewController: UIViewController {

    // MARK: - Properties

    private let viewModel = ConnectionViewModel()

    // MARK: - UI Elements

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = UIImage(named: "login_bg")
        return iv
    }()

    private let returnButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let chevron = UIImage(systemName: "chevron.left", withConfiguration: config)
        btn.setImage(chevron, for: .normal)
        btn.setTitle(" Return", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.tintColor = .white
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btn.contentHorizontalAlignment = .left
        return btn
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = AppConfig.appName
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 2
        return label
    }()

    private let versionLabel: UILabel = {
        let label = UILabel()
        label.text = "version:\(AppConfig.appVersion)"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = AppColors.textSecondary
        return label
    }()

    // MARK: - Form Elements

    private let formContainer = UIView()

    private let btNameLabel: UILabel = {
        let label = UILabel()
        label.text = "BT NAME:"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppColors.textSecondary
        return label
    }()

    private let btNameValueLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = AppColors.textPrimary
        label.heightAnchor.constraint(equalToConstant: 24).isActive = true
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

    // MARK: - Right Panel (Device List)

    private let rightPanel: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.93, alpha: 1.0)
        return v
    }()

    private let refreshButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.tintColor = .darkGray
        btn.contentHorizontalAlignment = .center
        return btn
    }()

    private let refreshSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.82, alpha: 1.0)
        return v
    }()

    private lazy var deviceTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.delegate = self
        tv.dataSource = self
        tv.register(DeviceListCell.self, forCellReuseIdentifier: DeviceListCell.reuseID)
        tv.separatorColor = UIColor(white: 0.82, alpha: 1.0)
        tv.separatorInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
        tv.rowHeight = 48
        return tv
    }()

    /// Scanning spinner in right panel
    private let scanningIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = .darkGray
        ai.hidesWhenStopped = true
        return ai
    }()

    private let loadingView = LoadingView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        viewModel.delegate = self
        updateRefreshButtonTitle(count: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeLeft }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = AppColors.background

        [backgroundImageView, returnButton, titleLabel, versionLabel,
         formContainer, rightPanel, loadingView].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        [btNameLabel, btNameValueLabel, btNameUnderline,
         btPasswordLabel, passwordField, togglePasswordButton, passwordUnderline,
         connectButton].forEach {
            formContainer.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        [refreshButton, refreshSeparator, scanningIndicator, deviceTableView].forEach {
            rightPanel.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let panelWidth: CGFloat = 200

        NSLayoutConstraint.activate([
            // Right panel
            rightPanel.topAnchor.constraint(equalTo: view.topAnchor),
            rightPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rightPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            rightPanel.widthAnchor.constraint(equalToConstant: panelWidth),

            // Refresh button
            refreshButton.topAnchor.constraint(equalTo: rightPanel.safeAreaLayoutGuide.topAnchor, constant: 10),
            refreshButton.leadingAnchor.constraint(equalTo: rightPanel.leadingAnchor, constant: 8),
            refreshButton.trailingAnchor.constraint(equalTo: rightPanel.trailingAnchor, constant: -8),
            refreshButton.heightAnchor.constraint(equalToConstant: 36),

            refreshSeparator.topAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 6),
            refreshSeparator.leadingAnchor.constraint(equalTo: rightPanel.leadingAnchor),
            refreshSeparator.trailingAnchor.constraint(equalTo: rightPanel.trailingAnchor),
            refreshSeparator.heightAnchor.constraint(equalToConstant: 0.5),

            scanningIndicator.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor),
            scanningIndicator.trailingAnchor.constraint(equalTo: rightPanel.trailingAnchor, constant: -12),

            deviceTableView.topAnchor.constraint(equalTo: refreshSeparator.bottomAnchor),
            deviceTableView.leadingAnchor.constraint(equalTo: rightPanel.leadingAnchor),
            deviceTableView.trailingAnchor.constraint(equalTo: rightPanel.trailingAnchor),
            deviceTableView.bottomAnchor.constraint(equalTo: rightPanel.bottomAnchor),

            // Background image — left portion
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.50),

            // Return button — top left
            returnButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            returnButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            returnButton.heightAnchor.constraint(equalToConstant: 30),

            // Title — bottom left
            titleLabel.bottomAnchor.constraint(equalTo: versionLabel.topAnchor, constant: -4),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: formContainer.leadingAnchor, constant: -10),

            // Version — bottom left
            versionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            versionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            // Form container — between image and right panel
            formContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -10),
            formContainer.leadingAnchor.constraint(equalTo: backgroundImageView.trailingAnchor, constant: 24),
            formContainer.trailingAnchor.constraint(equalTo: rightPanel.leadingAnchor, constant: -24),

            // BT NAME
            btNameLabel.topAnchor.constraint(equalTo: formContainer.topAnchor),
            btNameLabel.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),

            btNameValueLabel.topAnchor.constraint(equalTo: btNameLabel.bottomAnchor, constant: 8),
            btNameValueLabel.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            btNameValueLabel.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),

            btNameUnderline.topAnchor.constraint(equalTo: btNameValueLabel.bottomAnchor, constant: 8),
            btNameUnderline.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            btNameUnderline.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            btNameUnderline.heightAnchor.constraint(equalToConstant: 0.5),

            // BT PASSWORD
            btPasswordLabel.topAnchor.constraint(equalTo: btNameUnderline.bottomAnchor, constant: 20),
            btPasswordLabel.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),

            passwordField.topAnchor.constraint(equalTo: btPasswordLabel.bottomAnchor, constant: 8),
            passwordField.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: togglePasswordButton.leadingAnchor, constant: -8),
            passwordField.heightAnchor.constraint(equalToConstant: 24),

            togglePasswordButton.centerYAnchor.constraint(equalTo: passwordField.centerYAnchor),
            togglePasswordButton.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            togglePasswordButton.widthAnchor.constraint(equalToConstant: 30),
            togglePasswordButton.heightAnchor.constraint(equalToConstant: 30),

            passwordUnderline.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 8),
            passwordUnderline.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            passwordUnderline.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            passwordUnderline.heightAnchor.constraint(equalToConstant: 0.5),

            // Connect button
            connectButton.topAnchor.constraint(equalTo: passwordUnderline.bottomAnchor, constant: 28),
            connectButton.centerXAnchor.constraint(equalTo: formContainer.centerXAnchor),
            connectButton.widthAnchor.constraint(equalToConstant: 180),
            connectButton.heightAnchor.constraint(equalToConstant: 40),
            connectButton.bottomAnchor.constraint(equalTo: formContainer.bottomAnchor),

            // Loading overlay
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        loadingView.isHidden = true
    }

    private func setupActions() {
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        togglePasswordButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        returnButton.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Helpers

    private func updateRefreshButtonTitle(count: Int) {
        let icon = UIImage(systemName: "arrow.clockwise")?
            .withTintColor(.darkGray, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 13, weight: .medium))
        let attachment = NSTextAttachment()
        attachment.image = icon

        let text: String
        if count > 0 {
            text = "  Refresh the BT List(\(count))"
        } else {
            text = "  Refresh the BT List"
        }

        let attrStr = NSMutableAttributedString(attachment: attachment)
        attrStr.append(NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: UIColor.darkGray,
                .font: UIFont.systemFont(ofSize: 13, weight: .medium)
            ]
        ))
        refreshButton.setAttributedTitle(attrStr, for: .normal)
    }

    // MARK: - Actions

    @objc private func connectTapped() {
        dismissKeyboard()
        let ssid = btNameValueLabel.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordField.text ?? AppConfig.defaultPassword
        viewModel.connect(ssid: ssid, password: password, from: self)
    }

    @objc private func refreshTapped() {
        viewModel.refreshDeviceList()
    }

    @objc private func togglePasswordVisibility() {
        passwordField.isSecureTextEntry.toggle()
        let iconName = passwordField.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 16)
        togglePasswordButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
    }

    @objc private func returnTapped() {
        // First page — nothing to go back to
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Navigation

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

    func didStartScanning() {
        scanningIndicator.startAnimating()
        deviceTableView.reloadData()
    }

    func didStopScanning() {
        scanningIndicator.stopAnimating()
    }

    func didDiscoverDevice(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        deviceTableView.insertRows(at: [indexPath], with: .automatic)
    }

    func didUpdateRefreshCount(_ count: Int) {
        updateRefreshButtonTitle(count: count)
    }

    func didStartConnecting() {
        loadingView.show(message: "Wifi connecting")
    }

    func didConnectSuccessfully(deviceName: String) {
        loadingView.updateMessage("Device connecting")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.loadingView.hide()
            self?.navigateToMain(deviceName: deviceName)
        }
    }

    func didFailToConnect(error: String) {
        loadingView.hide()
        showAlert(title: "Connection Failed", message: error)
    }

    func didBluetoothStateChange(isAvailable: Bool, message: String?) {
        if !isAvailable, let message = message {
            showAlert(title: "Bluetooth", message: message)
        }
    }
}

// MARK: - UITableView DataSource & Delegate

extension ConnectionViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sseDevices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DeviceListCell.reuseID, for: indexPath) as? DeviceListCell else {
            return UITableViewCell()
        }
        let device = viewModel.sseDevices[indexPath.row]
        cell.configure(name: device.name)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectDevice(at: indexPath.row)
        let device = viewModel.sseDevices[indexPath.row]
        btNameValueLabel.text = device.name
        passwordField.text = AppConfig.defaultPassword
    }
}

// MARK: - DeviceListCell

/// Custom cell for the right-side device list, showing a BT icon + device name
final class DeviceListCell: UITableViewCell {

    static let reuseID = "DeviceListCell"

    private let btIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iv.image = UIImage(systemName: "dot.radiowaves.left.and.right", withConfiguration: config)
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .darkGray
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear

        let selectedBg = UIView()
        selectedBg.backgroundColor = AppColors.accent.withAlphaComponent(0.12)
        selectedBackgroundView = selectedBg

        [btIcon, nameLabel].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            btIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            btIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            btIcon.widthAnchor.constraint(equalToConstant: 24),
            btIcon.heightAnchor.constraint(equalToConstant: 24),

            nameLabel.leadingAnchor.constraint(equalTo: btIcon.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String) {
        nameLabel.text = name
    }
}
