import UIKit
import SnapKit

/// 顶部标签栏代理协议
protocol TopTabBarViewDelegate: AnyObject {
    func topTabBarView(_ view: TopTabBarView, didSelectTabAt index: Int)
    func topTabBarViewDidTapConnected(_ view: TopTabBarView)
}

/// 水平顶部标签栏，对应 Android 布局：
/// [ Connected 设备名 > ] [ General ] [ Status View ] [ Faulty Alert ] [ PAYGO ]
final class TopTabBarView: UIView {

    weak var delegate: TopTabBarViewDelegate?

    private let tabs = ["General", "Status View", "Faulty Alert", "PAYGO"]
    private(set) var selectedIndex: Int = 0
    /// 「Connected」下方副标题（优先为 WiFi SSID，否则为蓝牙名等兜底）
    private var connectedSubtitle: String

    // MARK: - UI 组件

    /// 左侧"已连接"按钮，显示设备名称与箭头
    private lazy var connectedButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = AppColors.background
        btn.contentHorizontalAlignment = .left
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 8)
        return btn
    }()

    /// Tab 行：[竖线][按钮][竖线][按钮]… 首条竖线即 Connected 与 General 之间的分隔
    private let tabRowStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 0
        sv.distribution = .fill
        sv.alignment = .fill
        return sv
    }()

    private let bottomHairline: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.tabBarDivider
        return v
    }()

    private var tabButtons: [UIButton] = []

    // MARK: - 初始化

    init(connectedSubtitle: String) {
        self.connectedSubtitle = connectedSubtitle
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        self.connectedSubtitle = ""
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - 布局设置

    private func setupUI() {
        backgroundColor = AppColors.background

        addSubview(connectedButton)
        addSubview(tabRowStack)
        addSubview(bottomHairline)

        // 左侧按钮：宽度 140，其余填满剩余空间
        connectedButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(140)
        }

        tabRowStack.snp.makeConstraints { make in
            make.leading.equalTo(connectedButton.snp.trailing)
            make.top.trailing.bottom.equalToSuperview()
        }

        bottomHairline.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        configureConnectedButtonChrome()
        applyConnectedSubtitleToButton()
        connectedButton.addTarget(self, action: #selector(connectedTapped), for: .touchUpInside)

        // Tab 行：竖线 + 等分宽按钮
        for (index, title) in tabs.enumerated() {
            tabRowStack.addArrangedSubview(VerticalTabSeparatorView())
            let button = createTabButton(title: title, index: index)
            tabButtons.append(button)
            tabRowStack.addArrangedSubview(button)
        }

        if let firstTab = tabButtons.first {
            for btn in tabButtons.dropFirst() {
                btn.snp.makeConstraints { make in
                    make.width.equalTo(firstTab)
                }
            }
        }

        updateSelection(index: 0, animated: false)
    }

    /// 箭头与布局（仅一次）
    private func configureConnectedButtonChrome() {
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

    /// 更新「Connected」下方文案（如从仅蓝牙名刷新为 WiFi SSID）
    func updateConnectedSubtitle(_ text: String) {
        connectedSubtitle = text
        applyConnectedSubtitleToButton()
    }

    private func applyConnectedSubtitleToButton() {
        let titleStr = NSMutableAttributedString()
        titleStr.append(NSAttributedString(
            string: "Connected\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: AppColors.textPrimary
            ]
        ))
        titleStr.append(NSAttributedString(
            string: connectedSubtitle,
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: AppColors.textSecondary
            ]
        ))
        connectedButton.setAttributedTitle(titleStr, for: .normal)
    }

    /// 创建单一标签按钮
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

    // MARK: - 选中状态

    func selectTab(at index: Int) {
        updateSelection(index: index, animated: true)
    }

    /// 更新选中标签样式：选中为橙色背景，未选中为默认背景
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

    // MARK: - 事件处理

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

// MARK: - 竖向实线分隔

/// Tab 之间的竖向实线，通顶通底，与底部分割线相接无间断
private final class VerticalTabSeparatorView: UIView {

    private let shapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        shapeLayer.strokeColor = AppColors.tabBarDivider.cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.lineCap = .butt
        shapeLayer.fillColor = nil
        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 1, height: UIView.noIntrinsicMetric)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let midX = bounds.midX
        let y1: CGFloat = 0
        let y2 = max(y1 + 1, bounds.height)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: midX, y: y1))
        path.addLine(to: CGPoint(x: midX, y: y2))
        shapeLayer.frame = bounds
        shapeLayer.path = path.cgPath
    }
}
