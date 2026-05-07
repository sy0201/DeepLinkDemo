// AppDelegate.swift
// DeepLinkDemo
//
// 딥링크 처리의 진입점 (Entry Point)
// - 커스텀 URL 스킴: application(_:open:options:)
// - 유니버설 링크:   scene(_:continue:) → SceneDelegate에서 처리

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("✅ [AppDelegate] 앱 실행됨")
        return true
    }

    // MARK: - 커스텀 URL 스킴 처리 (iOS 12 이하 / SceneDelegate 미사용 환경)
    // 예: deeplinkdemo://home, deeplinkdemo://profile/123
    //
    // ⚠️ SceneDelegate를 사용하는 프로젝트(iOS 13+)에서는
    //    이 메서드 대신 SceneDelegate의 scene(_:openURLContexts:)가 호출됨
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        print("📲 [AppDelegate] 커스텀 URL 스킴 수신: \(url.absoluteString)")
        return DeepLinkRouter.shared.handle(url: url)
    }

    // MARK: - Scene 설정
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
