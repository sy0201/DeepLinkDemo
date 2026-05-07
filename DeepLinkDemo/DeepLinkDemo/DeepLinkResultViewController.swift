// DeepLinkResultViewController.swift
// DeepLinkDemo
//
// 딥링크로 이동했을 때 보여주는 결과 화면
// 실제 프로젝트에서는 각 목적지에 맞는 ViewController로 교체

import UIKit

class DeepLinkResultViewController: UIViewController {

    // MARK: - Properties
    private let destination: DeepLinkDestination
    private let linkType: String
    private let rawURL: String

    // MARK: - UI
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Init
    init(destination: DeepLinkDestination, linkType: String, rawURL: String) {
        self.destination = destination
        self.linkType    = linkType
        self.rawURL      = rawURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateContent()
    }

    // MARK: - UI 세팅
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])
    }

    private func populateContent() {
        let isCustomScheme = linkType.contains("커스텀")

        // ── 링크 타입 배지 ──────────────────────────────────────
        addInfoRow(
            icon: isCustomScheme ? "📲" : "🌐",
            label: "링크 타입",
            value: linkType,
            valueColor: isCustomScheme ? .systemBlue : .systemGreen
        )

        // ── 목적지 ──────────────────────────────────────────────
        addInfoRow(icon: "🗺️", label: "목적지", value: destination.description)

        // ── 원본 URL ─────────────────────────────────────────────
        addInfoRow(icon: "🔗", label: "원본 URL", value: rawURL, isMono: true)

        // ── 구분선 ──────────────────────────────────────────────
        addDivider()

        // ── 동작 설명 ────────────────────────────────────────────
        let descTitle = makeLabel("이 링크는 어떻게 동작했을까?", font: .systemFont(ofSize: 16, weight: .semibold))
        contentStack.addArrangedSubview(descTitle)

        if isCustomScheme {
            addDescriptionCard(
                title: "커스텀 URL 스킴 처리 흐름",
                body: """
                1. 외부에서 "\(rawURL)" 실행
                2. iOS가 Info.plist의 CFBundleURLSchemes 확인
                3. "deeplinkdemo" 스킴이 이 앱에 등록됨 확인
                4. AppDelegate / SceneDelegate의 openURLContexts 호출
                5. DeepLinkRouter.handle(url:) 실행
                6. DeepLinkDestination.parse(from:) 로 목적지 파싱
                7. NavigationController.push() 로 이 화면 진입
                """,
                color: .systemBlue
            )

            addWarningCard(
                title: "⚠️ 커스텀 URL 스킴의 한계",
                body: """
                • 카카오톡 채팅방 링크 공유 → ❌ 차단됨
                • 페이스북/인스타그램 링크 → ❌ 인식 안 됨
                • 앱 미설치 사용자 → ❌ 오류 (App Store 미이동)
                • Deferred Deep Link → ❌ 불가
                """
            )
        } else {
            addDescriptionCard(
                title: "유니버설 링크 처리 흐름",
                body: """
                1. 외부에서 "\(rawURL)" 클릭
                2. iOS가 apple-app-site-association 파일 확인
                   (https://deeplinkdemo.com/.well-known/apple-app-site-association)
                3. 이 앱이 해당 도메인 소유자임을 확인
                4. SceneDelegate의 scene(_:continue:) 호출
                5. DeepLinkRouter.handle(url:) 실행
                6. DeepLinkDestination.parse(from:) 로 목적지 파싱
                7. NavigationController.push() 로 이 화면 진입

                앱 미설치 시: Safari에서 웹페이지로 열림 ✅
                """,
                color: .systemGreen
            )
        }
    }

    // MARK: - UI 헬퍼
    private func addInfoRow(icon: String, label: String, value: String, valueColor: UIColor = .label, isMono: Bool = false) {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 10

        let iconLabel = makeLabel(icon, font: .systemFont(ofSize: 18))
        let titleLabel = makeLabel(label, font: .systemFont(ofSize: 12, weight: .semibold), color: .secondaryLabel)
        let valueLabel = makeLabel(value, font: isMono ? .monospacedSystemFont(ofSize: 13, weight: .regular) : .systemFont(ofSize: 15, weight: .medium), color: valueColor)
        valueLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let rowStack = UIStackView(arrangedSubviews: [iconLabel, textStack])
        rowStack.axis = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            rowStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            rowStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            rowStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            iconLabel.widthAnchor.constraint(equalToConstant: 28),
        ])

        contentStack.addArrangedSubview(container)
    }

    private func addDescriptionCard(title: String, body: String, color: UIColor) {
        let container = UIView()
        container.backgroundColor = color.withAlphaComponent(0.07)
        container.layer.cornerRadius = 10
        container.layer.borderWidth = 1
        container.layer.borderColor = color.withAlphaComponent(0.25).cgColor

        let titleLabel = makeLabel(title, font: .systemFont(ofSize: 14, weight: .semibold), color: color)
        let bodyLabel = makeLabel(body, font: .monospacedSystemFont(ofSize: 12, weight: .regular))
        bodyLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
        ])

        contentStack.addArrangedSubview(container)
    }

    private func addWarningCard(title: String, body: String) {
        addDescriptionCard(title: title, body: body, color: .systemOrange)
    }

    private func addDivider() {
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        contentStack.addArrangedSubview(divider)
    }

    private func makeLabel(_ text: String, font: UIFont, color: UIColor = .label) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}
