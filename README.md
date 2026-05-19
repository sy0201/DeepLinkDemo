# DeepLink Demo

> **Branch.io, Firebase Dynamic Links 같은 서드파티 없이**  
> 커스텀 URL 스킴 + 유니버설 링크를 직접 구현하는 레퍼런스 프로젝트

딥링크 처리 방식을 분석하고, 실제 운영 앱 수준의 딥링크 시스템을 순수 iOS 네이티브로 구현합니다.

---

## 💡 왜 Branch.io 대신 직접 구현하나요?

| | Branch.io / Firebase Dynamic Links | 직접 구현 (이 프로젝트) |
|---|---|---|
| **비용** | 월 수십~수백만 원 (트래픽 기반) | 무료 |
| **외부 의존성** | SDK 업데이트, 서비스 종료 리스크 | 없음 |
| **커스터마이징** | 제한적 | 완전 자유 |
| **디버깅** | 블랙박스 (내부 동작 불투명) | 코드 레벨 추적 가능 |
| **앱 용량** | SDK 추가로 증가 | 증가 없음 |
| **데이터 주권** | 서드파티 서버에 링크 데이터 저장 | 자체 서버에서 관리 |

### Branch.io가 해주는 것들, 직접 구현하면?

```
Branch.io 기능                →  직접 구현 방법
─────────────────────────────────────────────────────────────
딥링크 라우팅                 →  DeepLinkRouter (이 프로젝트)
커스텀 URL 스킴               →  Info.plist CFBundleURLSchemes
유니버설 링크                 →  apple-app-site-association + Entitlements
Deferred Deep Link            →  서버에 링크 파라미터 저장 후 첫 실행 시 조회
링크 클릭 통계                →  자체 서버 로깅 or Firebase Analytics
앱 미설치 시 스토어 이동      →  apple-app-site-association paths 설정
```

> ⚠️ **Deferred Deep Link** (앱 미설치 상태에서 링크 클릭 → 설치 후 해당 화면으로 이동)는  
> 서버 연동이 필요한 부분으로, 이 프로젝트에서는 다루지 않습니다.  
> 해당 기능만 Branch.io에 의존하거나, 자체 서버로 구현 가능합니다.

---

## 📌 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 목적 | 서드파티 없이 iOS 딥링크 직접 구현 레퍼런스 |
| 지원 iOS | 15.0+ |
| 언어 | Swift 5.9 |
| 아키텍처 | MVC + Singleton Router |
| 외부 라이브러리 | 없음 (Zero dependency) |

---

## 🔗 지원하는 딥링크 방식

### 1. 커스텀 URL 스킴 (Custom URL Scheme)
```
deeplinkdemo://profile/42
deeplinkdemo://product/99
deeplinkdemo://orders
deeplinkdemo://settings
```
- 앱이 설치되어 있어야만 동작
- `Info.plist`의 `CFBundleURLSchemes`에 등록
- Branch.io의 `bnc.lt` 단축 URL 없이 직접 스킴 사용

### 2. 유니버설 링크 (Universal Link)
```
https://deeplinkdemo.com/profile/42
https://deeplinkdemo.com/product/99
```
- 앱이 없으면 웹, 있으면 앱으로 자동 연결
- `apple-app-site-association` 파일을 서버에 배포
- `Signing & Capabilities` → Associated Domains 설정 필요

---

## 🗂 프로젝트 구조

```
DeepLinkDemo/
├── App/
│   ├── AppDelegate.swift          # URL Scheme 처리 (iOS 12 이하)
│   ├── SceneDelegate.swift        # Cold Start / Warm Start 딥링크 진입점
│   ├── Info.plist                 # CFBundleURLSchemes 등록
│   └── DeepLinkDemo.entitlements  # Associated Domains 설정
│
├── Core/
│   ├── DeepLinkDestination.swift  # 딥링크 목적지 enum + URL 파싱
│   └── DeepLinkRouter.swift       # 싱글톤 라우터 (pending 큐 포함)
│
├── Screens/
│   ├── Home/
│   │   └── HomeViewController.swift            # 딥링크 수신 + 화면 이동
│   └── DeepLinkTest/
│       └── DeepLinkResultViewController.swift  # 딥링크 결과 표시
│
└── apple-app-site-association     # 유니버설 링크용 서버 배포 파일
```

---

## 🏗 아키텍처 설계

### 핵심 흐름

```
외부에서 URL 진입
        ↓
AppDelegate / SceneDelegate
        ↓
DeepLinkRouter.handle(url:)   ← 싱글톤, Zero dependency
        ↓
DeepLinkDestination 파싱      ← Branch.io의 파싱 역할을 직접 구현
        ↓
NotificationCenter.post(.deepLinkReceived)
        ↓
HomeViewController.handleDeepLinkReceived()
        ↓
navigate(to: destination)
```

### Cold Start vs Warm Start

| 상태 | 의미 | 처리 방식 |
|------|------|----------|
| **Cold Start** | 앱 완전 종료 상태에서 딥링크 진입 | `pendingURLs` 큐에 저장 → `markAppAsReady()` 시 일괄 처리 |
| **Warm Start** | 백그라운드에서 딥링크 진입 | 즉시 처리 |

```swift
// Cold Start 시 앱 준비 완료 전 들어온 딥링크를 큐에 저장
func markAppAsReady() {
    isAppReady = true
    pendingURLs.forEach { handle(url: $0) }  // 일괄 처리
    pendingURLs.removeAll()
}
```

---

## 🧭 지원하는 딥링크 목적지

| 목적지 | 커스텀 스킴 | 유니버설 링크 |
|--------|------------|--------------|
| 메인 화면 | `deeplinkdemo://app` | `https://deeplinkdemo.com/app` |
| 프로필 | `deeplinkdemo://profile/42` | `https://deeplinkdemo.com/profile/42` |
| 상품 상세 | `deeplinkdemo://product/99` | `https://deeplinkdemo.com/product/99` |
| 주문 목록 | `deeplinkdemo://orders` | `https://deeplinkdemo.com/orders` |
| 설정 | `deeplinkdemo://settings` | `https://deeplinkdemo.com/settings` |

---

## 🧪 테스트 방법

### 방법 1: 앱 내 테스트 버튼 (가장 쉬움)
앱 실행 후 홈 화면의 테스트 버튼 클릭

### 방법 2: 터미널에서 시뮬레이터 테스트
```bash
# 커스텀 URL 스킴
xcrun simctl openurl booted "deeplinkdemo://profile/42"
xcrun simctl openurl booted "deeplinkdemo://product/99"

# 유니버설 링크
xcrun simctl openurl booted "https://deeplinkdemo.com/profile/42"
```

### 방법 3: Safari에서 테스트
시뮬레이터 Safari 주소창에 직접 입력:
```
deeplinkdemo://profile/42
```

---

## ⚙️ 실제 앱에 적용하는 방법

### Step 1. Info.plist 스킴 교체
```xml
<!-- deeplinkdemo → 실제 앱 스킴으로 교체 -->
<key>CFBundleURLSchemes</key>
<array>
    <string>myapp</string>
</array>
```

### Step 2. Entitlements Associated Domains 교체
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:myapp.com</string>
</array>
```

### Step 3. apple-app-site-association 서버 배포
```
https://myapp.com/.well-known/apple-app-site-association
```
파일 내 `TEAMID`를 본인 Team ID로 교체 후 배포.  
Team ID 확인: [Apple Developer 콘솔](https://developer.apple.com/account) → Membership

### Step 4. DeepLinkDestination에 목적지 추가
```swift
enum DeepLinkDestination {
    case main
    case profile(userID: Int)
    // 필요한 목적지 추가
}
```

---

## 📚 참고 자료

- [Apple - Defining a custom URL scheme](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- [Apple - Supporting universal links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [AASA 파일 검증 도구](https://branch.io/resources/aasa-validator/) — Branch.io가 무료로 제공
