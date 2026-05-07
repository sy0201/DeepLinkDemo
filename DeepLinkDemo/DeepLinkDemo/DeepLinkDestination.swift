// DeepLinkDestination.swift
// DeepLinkDemo
//
// 앱 내 이동 가능한 모든 딥링크 목적지를 enum으로 관리
//
// ✅ 이렇게 enum으로 관리하면 좋은 이유:
//   - 목적지 추가/삭제가 한 곳에서 관리됨
//   - 컴파일 타임에 오탈자 방지 (문자열 하드코딩 ❌)
//   - switch문으로 모든 케이스 처리 강제 → 누락 방지

import Foundation

// MARK: - DeepLinkDestination

enum DeepLinkDestination: Equatable {

    // ── 커스텀 URL 스킴으로 처리되는 목적지들 ──────────────────────────
    // URL 형태: deeplinkdemo://{path}/{id?}
    //
    // 예시:
    //   deeplinkdemo://home              → 홈 화면
    //   deeplinkdemo://profile/42        → 유저 42번 프로필
    //   deeplinkdemo://product/99        → 상품 99번 상세
    //   deeplinkdemo://order/7           → 주문 7번 상세
    //   deeplinkdemo://coupon            → 쿠폰 목록

    case home
    case profile(userID: Int)
    case product(productID: Int)
    case order(orderID: Int)
    case coupon
    case unknown(rawPath: String)

    // MARK: - URL 경로 문자열 (path 컴포넌트와 매핑)
    // 예: deeplinkdemo://profile/42 → host = "profile", pathComponent = "42"
    var path: String {
        switch self {
        case .home:             return "home"
        case .profile:          return "profile"
        case .product:          return "product"
        case .order:            return "order"
        case .coupon:           return "coupon"
        case .unknown(let raw): return raw
        }
    }
}

// MARK: - URL → DeepLinkDestination 파싱
extension DeepLinkDestination {

    /// URL을 받아서 DeepLinkDestination으로 변환
    ///
    /// 커스텀 URL 스킴 예시:
    ///   deeplinkdemo://profile/42  → .profile(userID: 42)
    ///   deeplinkdemo://home        → .home
    ///
    /// 유니버설 링크 예시:
    ///   https://deeplinkdemo.com/profile/42  → .profile(userID: 42)
    ///   https://deeplinkdemo.com/home        → .home
    static func parse(from url: URL) -> DeepLinkDestination? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ [DeepLinkDestination] URLComponents 파싱 실패: \(url)")
            return nil
        }

        // ── 경로 파싱 ────────────────────────────────────────────────
        // 커스텀 스킴: host = "profile", path = "/42"
        // 유니버설:   host = "deeplinkdemo.com", path = "/profile/42"

        var pathSegments: [String] = []

        // 커스텀 URL 스킴인 경우 host가 첫 번째 path segment
        if url.scheme != "https" && url.scheme != "http" {
            if let host = components.host, !host.isEmpty {
                pathSegments.append(host)
            }
        }

        // path 컴포넌트 추가 (앞뒤 "/" 제거 후 분리)
        let pathParts = components.path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }

        pathSegments.append(contentsOf: pathParts)

        print("🔍 [DeepLinkDestination] pathSegments: \(pathSegments)")

        guard !pathSegments.isEmpty else {
            print("❌ [DeepLinkDestination] 경로 없음")
            return nil
        }

        let destinationType = pathSegments[0]
        let destinationID   = pathSegments.count > 1 ? Int(pathSegments[1]) : nil

        switch destinationType {
        case "home":
            return .home

        case "profile":
            guard let id = destinationID else {
                print("⚠️ [DeepLinkDestination] profile에 ID 없음 → 기본값 사용")
                return .profile(userID: 0)
            }
            return .profile(userID: id)

        case "product":
            guard let id = destinationID else {
                print("❌ [DeepLinkDestination] product에 ID 필요")
                return .unknown(rawPath: destinationType)
            }
            return .product(productID: id)

        case "order":
            guard let id = destinationID else {
                print("❌ [DeepLinkDestination] order에 ID 필요")
                return .unknown(rawPath: destinationType)
            }
            return .order(orderID: id)

        case "coupon":
            return .coupon

        default:
            print("❓ [DeepLinkDestination] 알 수 없는 경로: \(destinationType)")
            return .unknown(rawPath: destinationType)
        }
    }
}

// MARK: - 디버그 출력용
extension DeepLinkDestination: CustomStringConvertible {
    var description: String {
        switch self {
        case .home:                    return "홈"
        case .profile(let id):         return "프로필 (userID: \(id))"
        case .product(let id):         return "상품 상세 (productID: \(id))"
        case .order(let id):           return "주문 상세 (orderID: \(id))"
        case .coupon:                  return "쿠폰 목록"
        case .unknown(let raw):        return "알 수 없음 (path: \(raw))"
        }
    }
}
