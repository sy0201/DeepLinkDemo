// DeepLinkRouter.swift
// DeepLinkDemo
//
// ✅ 딥링크 라우터 — 커스텀 URL 스킴 & 유니버설 링크를 통합 처리
//
// 역할:
//   1. URL을 받아서 어떤 타입인지 판별 (커스텀 스킴 vs 유니버설 링크)
//   2. DeepLinkDestination으로 파싱
//   3. 해당 화면으로 네비게이션
//
// 설계 원칙 (pill-ios 패턴 참고):
//   - 앱이 아직 초기화 중이면 pending 큐에 저장
//   - 앱 준비 완료(markAppAsReady) 시점에 일괄 처리
//   - 싱글톤으로 앱 어디서든 접근 가능

import UIKit

final class DeepLinkRouter {

    // MARK: - 싱글톤
    static let shared = DeepLinkRouter()
    private init() {}

    // MARK: - 커스텀 URL 스킴 설정
    // Info.plist의 CFBundleURLSchemes에 등록된 값과 동일해야 함
    // 예: "deeplinkdemo"  →  deeplinkdemo://home
    private let customScheme = "deeplinkdemo"

    // MARK: - 유니버설 링크 도메인 설정
    // Associated Domains에 등록된 도메인과 동일해야 함
    // 예: "deeplinkdemo.com"  →  https://deeplinkdemo.com/home
    private let universalLinkDomain = "deeplinkdemo.com"

    // MARK: - Pending Queue
    // 앱 초기화 전에 도착한 딥링크를 임시 저장
    private var pendingURLs: [URL] = []
    private var isAppReady = false

    // MARK: - 앱 준비 완료 표시
    /// 홈 화면 로드 완료 시점에 호출
    func markAppAsReady() {
        print("✅ [DeepLinkRouter] 앱 준비 완료 — 대기 중인 딥링크 처리 시작")
        isAppReady = true
        processPendingURLs()
    }

    // MARK: - 대기 중인 URL 일괄 처리
    private func processPendingURLs() {
        guard isAppReady else { return }
        let pendingCopy = pendingURLs
        pendingURLs.removeAll()
        for url in pendingCopy {
            print("🔄 [DeepLinkRouter] Pending URL 처리: \(url.absoluteString)")
            route(url: url)
        }
    }

    // MARK: - 메인 진입점
    /// AppDelegate / SceneDelegate에서 URL을 받으면 이 메서드 하나만 호출
    @discardableResult
    func handle(url: URL) -> Bool {
        print("\n── DeepLinkRouter.handle() ─────────────────────")
        print("   URL: \(url.absoluteString)")
        print("   Scheme: \(url.scheme ?? "없음")")
        print("   Host: \(url.host ?? "없음")")
        print("   Path: \(url.path)")
        print("────────────────────────────────────────────────\n")

        // 유효한 딥링크인지 확인
        guard isValidDeepLink(url: url) else {
            print("❌ [DeepLinkRouter] 지원하지 않는 URL: \(url.absoluteString)")
            return false
        }

        // 앱이 아직 준비 안 됐으면 pending 큐에 저장
        if !isAppReady {
            print("⏳ [DeepLinkRouter] 앱 준비 전 — Pending 큐에 저장")
            if !pendingURLs.contains(where: { $0.absoluteString == url.absoluteString }) {
                pendingURLs.append(url)
            }
            return true
        }

        route(url: url)
        return true
    }

    // MARK: - URL 유효성 검사
    private func isValidDeepLink(url: URL) -> Bool {
        // 커스텀 URL 스킴 확인
        if url.scheme == customScheme { return true }
        // 유니버설 링크 확인
        if (url.scheme == "https" || url.scheme == "http"),
           url.host == universalLinkDomain { return true }
        return false
    }

    // MARK: - 실제 라우팅 (화면 이동)
    private func route(url: URL) {
        guard let destination = DeepLinkDestination.parse(from: url) else {
            print("❌ [DeepLinkRouter] 목적지 파싱 실패")
            return
        }

        print("🗺️ [DeepLinkRouter] 목적지: \(destination)")

        // 딥링크 타입 로깅
        let linkType = url.scheme == customScheme ? "커스텀 URL 스킴" : "유니버설 링크"
        print("🔗 [DeepLinkRouter] 링크 타입: \(linkType)")

        // NotificationCenter로 화면 이동 위임
        // → ViewController에서 직접 의존하지 않고 느슨하게 연결
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .deepLinkReceived,
                object: nil,
                userInfo: [
                    DeepLinkNotificationKey.destination: destination,
                    DeepLinkNotificationKey.linkType: linkType,
                    DeepLinkNotificationKey.rawURL: url.absoluteString
                ]
            )
        }
    }
}

// MARK: - Notification 이름 & 키 정의
extension Notification.Name {
    /// 딥링크 수신 시 발송되는 알림
    static let deepLinkReceived = Notification.Name("DeepLinkReceived")
}

enum DeepLinkNotificationKey {
    static let destination = "destination"   // DeepLinkDestination
    static let linkType    = "linkType"      // String ("커스텀 URL 스킴" / "유니버설 링크")
    static let rawURL      = "rawURL"        // String
}
