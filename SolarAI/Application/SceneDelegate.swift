import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// 避免冷启动时重复发 `networkDidChange`（会与前台通知、Reachability 叠加重试）；仅在曾经进入过后台、再次回到前台时补发，便于从系统 Wi‑Fi 设置返回后立刻重测。
    private var sceneHasBeenActiveBefore = false

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let connectionVC = ConnectionViewController()
        let navController = UINavigationController(rootViewController: connectionVC)
        navController.setNavigationBarHidden(true, animated: false)
        window.rootViewController = navController
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // 从 WiFi 设置返回时触发网络检查
        NotificationCenter.default.post(name: .networkDidChange, object: nil)
    }
}
