// SceneDelegate.swift
// DeepLinkDemo
//
// ✅ iOS 13+ SceneDelegate 기반 딥링크 처리
//
// [케이스 1] 앱이 꺼져 있을 때 (Cold Start)
//   → willConnectTo에서 connectionOptions 확인
//
// [케이스 2] 앱이 백그라운드에 있을 때 (Warm Start)
//   → openURLContexts 또는 continue userActivity 호출

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // MARK: - [케이스 1] Cold Start: 앱이 완전히 꺼진 상태에서 딥링크로 실행될 때
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // 루트 뷰컨트롤러 세팅
        let window = UIWindow(windowScene: windowScene)
        let rootVC = HomeViewController()
        window.rootViewController = UINavigationController(rootViewController: rootVC)
        self.window = window
        window.makeKeyAndVisible()

        // ── 커스텀 URL 스킴 (Cold Start) ─────────────────────────────
        // 예: deeplinkdemo://profile/42
        if let urlContext = connectionOptions.urlContexts.first {
            let url = urlContext.url
            print("📲 [SceneDelegate] Cold Start - 커스텀 URL 스킴: \(url.absoluteString)")
            // 앱 초기화가 완료된 직후이므로 약간의 딜레이 후 처리
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                DeepLinkRouter.shared.handle(url: url)
            }
        }

        // ── 유니버설 링크 (Cold Start) ────────────────────────────────
        // 예: https://deeplinkdemo.com/profile/42
        if let userActivity = connectionOptions.userActivities.first,
           userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            print("🌐 [SceneDelegate] Cold Start - 유니버설 링크: \(url.absoluteString)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                DeepLinkRouter.shared.handle(url: url)
            }
        }
    }

    // MARK: - [케이스 2-A] Warm Start: 앱이 백그라운드에서 커스텀 URL 스킴으로 열릴 때
    // 예: deeplinkdemo://home, deeplinkdemo://product/99
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        print("📲 [SceneDelegate] Warm Start - 커스텀 URL 스킴: \(url.absoluteString)")
        DeepLinkRouter.shared.handle(url: url)
    }

    // MARK: - [케이스 2-B] Warm Start: 앱이 백그라운드에서 유니버설 링크로 열릴 때
    // 예: https://deeplinkdemo.com/product/99
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return }
        print("🌐 [SceneDelegate] Warm Start - 유니버설 링크: \(url.absoluteString)")
        DeepLinkRouter.shared.handle(url: url)
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
