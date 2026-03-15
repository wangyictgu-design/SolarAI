import UIKit
import SnapKit

/// 頂部標籤欄代理協議
protocol TopTabBarViewDelegate: AnyObject {
    func topTabBarView(_ view: TopTabBarView, didSelectTabAt index: Int)
    func topTabBarViewDidTapConnected(_ view: TopTabBarView)
}

/// 水平頂部標籤欄，對應 Android 佈局：
/// [ Connected 設備名 > ] [ General ] [ Status View ] [ Faulty Alert ] [ PAYGO ]
final class TopTabBarView: UIView {

    weak var delegate: TopTabBarViewDelegate?

    private let tabs = ["General", "Status View", "Faulty Alert", "PAYGO"]
    private(set) var selectedIndex: Int = 0
    private let deviceName: String

    // MARK: - UI 元件

    /// 左側「已連接」按鈕，顯示設備名稱與箭頭
    private lazy var connectedButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = AppColors.cardBackground
        btn.contentHorizontalAlignment = .left
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 8)
        return btn
    }()

    /// 水平堆疊視圖，放置四個等寬標籤按鈕
    private let tabStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 0
        sv.distribution = .fillEqually
        sv.alignment = .fill
        return sv
    }()

    private var tabButtons: [UIButton] = []

    // MARK: - 初始化

    init(deviceName: String) {
        self.deviceName = deviceName
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        self.deviceName = ""
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - 佈局設定

    private func setupUI() {
        backgroundColor = AppColors.cardBackground

        addSubview(connectedButton)
        addSubview(tabStackView)

        // 左側按鈕：寬度 140，其餘填滿剩餘空間
        connectedButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(140)
        }

        tabStackView.snp.makeConstraints { make in
            make.leading.equalTo(connectedButton.snp.trailing)
            make.top.trailing.bottom.equalToSuperview()
        }

        setupConnectedButton()
        connectedButton.addTarget(self, action: #selector(connectedTapped), for: .touchUpInside)

        // 建立四個等寬標籤按鈕
        for (index, title) in tabs.enumerated() {
            let button = createTabButton(title: title, index: index)
            tabButtons.append(button)
            tabStackView.addArrangedSubview(button)
        }

        updateSelection(index: 0, animated: false)
    }

    /// 設定「已連接」按鈕文字與箭頭圖示
    private func setupConnectedButton() {
        let titleStr = NSMutableAttributedString()

        titleStr.append(NSAttributedString(
            string: "Connected\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: AppColors.textPrimary
            ]
        ))
        titleStr.append(NSAttributedString(
            string: deviceName,
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: AppColors.textSecondary
            ]
        ))

        connectedButton.setAttributedTitle(titleStr, for: .normal)
        connectedButton.titleLabel?.numberOfLines = 2

        let chevron = UIImageView()
        chevron.image = UIImage(systemName: "chevron.right")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))
        chevron.tintColor = AppColors.textSecondary
        connectedButton.addSubview(chevron)

        chevron.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-8)
        }
    }

    /// 建立單一標籤按鈕
    private func createTabButton(title: String, index: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(AppColors.textPrimary, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        btn.titleLabel?.textAlignment = .center
        btn.tag = index
        btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        return btn
    }

    // MARK: - 選取狀態

    func selectTab(at index: Int) {
        updateSelection(index: index, animated: true)
    }

    /// 更新選中標籤樣式：選中為橙色背景，未選中為預設背景
    private func updateSelection(index: Int, animated: Bool) {
        selectedIndex = index
        let update = {
            for (i, button) in self.tabButtons.enumerated() {
                button.backgroundColor = i == index ? AppColors.tabSelected : AppColors.tabNormal
            }
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: update)
        } else {
            update()
        }
    }

    // MARK: - 事件處理

    @objc private func tabTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index != selectedIndex else { return }
        updateSelection(index: index, animated: true)
        delegate?.topTabBarView(self, didSelectTabAt: index)
    }

    @objc private func connectedTapped() {
        delegate?.topTabBarViewDidTapConnected(self)
    }
}
