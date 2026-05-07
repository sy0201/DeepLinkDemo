// HomeViewController.swift
// DeepLinkDemo
//
// 딥링크 이벤트를 구독하고 실제 화면 이동을 담당

import UIKit

class HomeViewController: UIViewController {

    // MARK: - UI
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "DeepLink Demo"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "딥링크 또는 유니버설 링크로 진입하면\n아래에 결과가 표시됩니다"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let resultCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let linkTypeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let destinationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let rawURLLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let testButtonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDeepLinkObserver()

        // 앱 초기화 완료 — 이 시점부터 딥링크 처리 가능
        DeepLinkRouter.shared.markAppAsReady()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI 세팅
    private func setupUI() {
        title = "홈"
        view.backgroundColor = .systemBackground

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(resultCard)
        view.addSubview(testButtonStack)

        resultCard.addSubview(linkTypeLabel)
        resultCard.addSubview(destinationLabel)
        resultCard.addSubview(rawURLLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            resultCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            resultCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            linkTypeLabel.topAnchor.constraint(equalTo: resultCard.topAnchor, constant: 16),
            linkTypeLabel.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 16),
            linkTypeLabel.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -16),

            destinationLabel.topAnchor.constraint(equalTo: linkTypeLabel.bottomAnchor, constant: 6),
            destinationLabel.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 16),
            destinationLabel.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -16),

            rawURLLabel.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: 8),
            rawURLLabel.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 16),
            rawURLLabel.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -16),
            rawURLLabel.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: -16),

            testButtonStack.topAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: 32),
            testButtonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            testButtonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])

        // 테스트 버튼 추가
        setupTestButtons()
    }

    private func setupTestButtons() {
        let sectionLabel = UILabel()
        sectionLabel.text = "테스트 — 시뮬레이터에서 딥링크 직접 실행"
        sectionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        sectionLabel.textColor = .secondaryLabel
        testButtonStack.addArrangedSubview(sectionLabel)

        let testCases: [(title: String, url: String)] = [
            ("🏠  deeplinkdemo://home",          "deeplinkdemo://home"),
            ("👤  deeplinkdemo://profile/42",     "deeplinkdemo://profile/42"),
            ("📦  deeplinkdemo://product/99",     "deeplinkdemo://product/99"),
            ("📋  deeplinkdemo://order/7",        "deeplinkdemo://order/7"),
            ("🎟️  deeplinkdemo://coupon",         "deeplinkdemo://coupon"),
        ]

        for testCase in testCases {
            let button = makeTestButton(title: testCase.title, urlString: testCase.url)
            testButtonStack.addArrangedSubview(button)
        }
    }

    private func makeTestButton(title: String, urlString: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        button.contentHorizontalAlignment = .left
        button.backgroundColor = UIColor.systemGray6
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        button.addAction(UIAction { [weak self] _ in
            self?.simulateDeepLink(urlString: urlString)
        }, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }

    // MARK: - 딥링크 수신 구독
    private func setupDeepLinkObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeepLinkNotification(_:)),
            name: .deepLinkReceived,
            object: nil
        )
    }

    @objc private func handleDeepLinkNotification(_ notification: Notification) {
        guard let destination = notification.userInfo?[DeepLinkNotificationKey.destination] as? DeepLinkDestination,
              let linkType    = notification.userInfo?[DeepLinkNotificationKey.linkType] as? String,
              let rawURL      = notification.userInfo?[DeepLinkNotificationKey.rawURL] as? String
        else { return }

        print("🏠 [HomeViewController] 딥링크 수신: \(destination)")
        navigate(to: destination, linkType: linkType, rawURL: rawURL)
    }

    // MARK: - 화면 이동
    private func navigate(to destination: DeepLinkDestination, linkType: String, rawURL: String) {
        // 결과 카드 업데이트
        updateResultCard(destination: destination, linkType: linkType, rawURL: rawURL)

        // 실제 화면 이동
        switch destination {
        case .home:
            // 이미 홈이므로 pop to root
            navigationController?.popToRootViewController(animated: true)

        case .profile(let userID):
            let vc = DeepLinkResultViewController(
                destination: destination,
                linkType: linkType,
                rawURL: rawURL
            )
            vc.title = "프로필 (ID: \(userID))"
            navigationController?.pushViewController(vc, animated: true)

        case .product(let productID):
            let vc = DeepLinkResultViewController(
                destination: destination,
                linkType: linkType,
                rawURL: rawURL
            )
            vc.title = "상품 (ID: \(productID))"
            navigationController?.pushViewController(vc, animated: true)

        case .order(let orderID):
            let vc = DeepLinkResultViewController(
                destination: destination,
                linkType: linkType,
                rawURL: rawURL
            )
            vc.title = "주문 (ID: \(orderID))"
            navigationController?.pushViewController(vc, animated: true)

        case .coupon:
            let vc = DeepLinkResultViewController(
                destination: destination,
                linkType: linkType,
                rawURL: rawURL
            )
            vc.title = "쿠폰 목록"
            navigationController?.pushViewController(vc, animated: true)

        case .unknown(let raw):
            print("❓ [HomeViewController] 알 수 없는 딥링크 경로: \(raw)")
        }
    }

    private func updateResultCard(destination: DeepLinkDestination, linkType: String, rawURL: String) {
        let isCustomScheme = linkType.contains("커스텀")
        linkTypeLabel.text = isCustomScheme ? "📲 커스텀 URL 스킴" : "🌐 유니버설 링크"
        linkTypeLabel.textColor = isCustomScheme ? .systemBlue : .systemGreen
        destinationLabel.text = "→ \(destination.description)"
        rawURLLabel.text = rawURL
        resultCard.isHidden = false
    }

    // MARK: - 시뮬레이터 테스트용 (실제 URL 오픈 시뮬레이션)
    private func simulateDeepLink(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        print("🧪 [HomeViewController] 테스트 딥링크 시뮬레이션: \(urlString)")
        DeepLinkRouter.shared.handle(url: url)
    }
}
