import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

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
        // 從 WiFi 設定返回時觸發網路檢查
        NotificationCenter.default.post(name: .networkDidChange, object: nil)
    }
}
