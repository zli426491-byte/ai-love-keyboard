import UIKit

final class KeyboardViewController: UIInputViewController {
    private enum ReplyStyle: Int, CaseIterable {
        case gentle = 0
        case funny = 1
        case flirty = 2
        case apology = 3

        var title: String {
            switch self {
            case .gentle: return "溫柔"
            case .funny: return "幽默"
            case .flirty: return "曖昧"
            case .apology: return "道歉"
            }
        }

        var symbolName: String {
            switch self {
            case .gentle: return "leaf.fill"
            case .funny: return "sun.max.fill"
            case .flirty: return "heart.fill"
            case .apology: return "drop.fill"
            }
        }

        var backgroundColor: UIColor {
            switch self {
            case .gentle: return Palette.selectedSoft
            case .funny: return Palette.warmYellow
            case .flirty: return Palette.roseSoft
            case .apology: return Palette.navySoft
            }
        }
    }

    private enum KeyboardMode: Int, CaseIterable {
        case reply = 0
        case opener = 1
        case invite = 2
        case comfort = 3
        case custom = 4

        var title: String {
            switch self {
            case .reply: return "接話"
            case .opener: return "破冰"
            case .invite: return "邀約"
            case .comfort: return "安撫"
            case .custom: return "自訂"
            }
        }

        var status: String {
            switch self {
            case .reply: return "根據對話回覆"
            case .opener: return "開場話題"
            case .invite: return "約出去"
            case .comfort: return "穩住情緒"
            case .custom: return "常用句"
            }
        }
    }

    private enum ChatIntent {
        case conflict
        case emotionalLow
        case logistics
        case foodOrDate
        case flirting
        case complimentStory
        case choice
        case casualBanter
        case cold
        case topicDead
        case daily
    }

    private enum AiConfig {
        static let proxyURLString = "__AI_PROXY_URL__"
        static var keyboardReplyEndpoint: URL? {
            guard
                !proxyURLString.isEmpty,
                !proxyURLString.contains("__AI_PROXY_URL__")
            else {
                return nil
            }
            return URL(string: proxyURLString.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/v1/keyboard-reply")
        }
    }

    private enum SharedConfig {
        static let appGroupID = "group.com.ailovekeyboard.app"
        static let subscriptionKey = "is_subscribed"

        static var isPro: Bool {
            UserDefaults(suiteName: appGroupID)?.bool(forKey: subscriptionKey) ?? false
        }
    }

    private enum Palette {
        static let background = UIColor(red: 255 / 255, green: 244 / 255, blue: 249 / 255, alpha: 1)
        static let card = UIColor(red: 255 / 255, green: 255 / 255, blue: 255 / 255, alpha: 1)
        static let primary = UIColor(red: 255 / 255, green: 70 / 255, blue: 124 / 255, alpha: 1)
        static let accent = UIColor(red: 178 / 255, green: 72 / 255, blue: 232 / 255, alpha: 1)
        static let blush = UIColor(red: 255 / 255, green: 128 / 255, blue: 166 / 255, alpha: 1)
        static let text = UIColor(red: 35 / 255, green: 24 / 255, blue: 38 / 255, alpha: 1)
        static let secondary = UIColor(red: 128 / 255, green: 104 / 255, blue: 122 / 255, alpha: 1)
        static let border = UIColor(red: 242 / 255, green: 216 / 255, blue: 228 / 255, alpha: 1)
        static let key = UIColor(red: 250 / 255, green: 240 / 255, blue: 246 / 255, alpha: 1)
        static let selectedSoft = UIColor(red: 255 / 255, green: 235 / 255, blue: 241 / 255, alpha: 1)
        static let warmYellow = UIColor(red: 255 / 255, green: 239 / 255, blue: 202 / 255, alpha: 1)
        static let roseSoft = UIColor(red: 255 / 255, green: 216 / 255, blue: 234 / 255, alpha: 1)
        static let navySoft = UIColor(red: 240 / 255, green: 232 / 255, blue: 255 / 255, alpha: 1)
        static let headerPill = UIColor(red: 255 / 255, green: 228 / 255, blue: 239 / 255, alpha: 1)
        static let commandKey = UIColor(red: 248 / 255, green: 240 / 255, blue: 247 / 255, alpha: 1)
        static let commandPink = UIColor(red: 255 / 255, green: 239 / 255, blue: 244 / 255, alpha: 1)
    }

    private let rootStack = UIStackView()
    private let contentStack = UIStackView()
    private let statusLabel = UILabel()
    private let styleStack = UIStackView()
    private let modeStack = UIStackView()

    private var styleButtons: [UIButton] = []
    private var styleLabels: [Int: UILabel] = [:]
    private var modeButtons: [UIButton] = []
    private var currentReplies: [String] = []
    private var displayedReplies: [String] = []
    private var selectedStyle: ReplyStyle = .gentle
    private var selectedMode: KeyboardMode = .invite
    private var currentMessage = ""
    private var statusMode: StatusMode = .idle
    private var generationIndex = 0
    private var filledIndex: Int?
    private var isGenerating = false
    private var aiErrorText: String?
    private var generationInstruction: String?
    private let messageTextView = PasteInputTextView()
    private let messagePlaceholderLabel = UILabel()
    private weak var modePillButton: UIButton?
    private weak var pasteActionButton: UIButton?
    private var isSyncingMessageText = false

    private enum StatusMode {
        case idle
        case emptyClipboard
        case noFullAccess
        case ready
        case filled
    }

    private enum SideButtonKind {
        case neutral
        case pink
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        renderContent()
    }

    private func setupView() {
        view.backgroundColor = Palette.background
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        configureMessageTextView()

        rootStack.axis = .vertical
        rootStack.spacing = 8
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 7),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -7)
        ])

        rootStack.addArrangedSubview(makeHeader())
        rootStack.addArrangedSubview(makeContentArea())

        renderContent()
    }

    private func makeHeader() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 7
        row.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let modeButton = UIButton(type: .system)
        modeButton.setTitle("開場邀約", for: .normal)
        modeButton.setImage(UIImage(systemName: "arrow.left.arrow.right"), for: .normal)
        modeButton.semanticContentAttribute = .forceRightToLeft
        modeButton.titleLabel?.font = .systemFont(ofSize: 14.5, weight: .heavy)
        modeButton.tintColor = Palette.primary
        modeButton.setTitleColor(Palette.text, for: .normal)
        modeButton.backgroundColor = Palette.headerPill
        modeButton.layer.cornerRadius = 16
        modeButton.layer.borderWidth = 0.8
        modeButton.layer.borderColor = Palette.border.cgColor
        modeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 8)
        modeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -4)
        modeButton.addTarget(self, action: #selector(cycleModeTapped), for: .touchUpInside)
        modeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 112).isActive = true
        modeButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        modePillButton = modeButton
        row.addArrangedSubview(modeButton)

        let brand = UILabel()
        brand.text = "LoveKey"
        brand.font = .systemFont(ofSize: 15, weight: .heavy)
        brand.textColor = Palette.accent
        brand.textAlignment = .center
        row.addArrangedSubview(brand)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(spacer)

        let badge = UILabel()
        badge.text = "30%"
        badge.textAlignment = .center
        badge.font = .systemFont(ofSize: 11, weight: .black)
        badge.textColor = .white
        badge.backgroundColor = Palette.blush
        badge.layer.cornerRadius = 15
        badge.layer.masksToBounds = true
        badge.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        badge.layer.borderWidth = 1
        badge.widthAnchor.constraint(equalToConstant: 42).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 30).isActive = true
        row.addArrangedSubview(badge)

        let settings = headerIconButton(systemName: "gearshape.fill", action: #selector(handleNextKeyboard))
        row.addArrangedSubview(settings)

        let collapse = headerIconButton(systemName: "chevron.down.circle.fill", action: #selector(handleNextKeyboard))
        row.addArrangedSubview(collapse)

        statusLabel.isHidden = true

        return row
    }

    private func headerIconButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = Palette.secondary
        button.backgroundColor = UIColor.white.withAlphaComponent(0.82)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 0.8
        button.layer.borderColor = Palette.border.cgColor
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeModeTabs() -> UIView {
        modeStack.axis = .horizontal
        modeStack.alignment = .fill
        modeStack.spacing = 7
        modeStack.distribution = .fillEqually
        modeStack.heightAnchor.constraint(equalToConstant: 42).isActive = true

        for mode in KeyboardMode.allCases {
            let button = UIButton(type: .system)
            button.setTitle(mode.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13.2, weight: .heavy)
            button.layer.cornerRadius = 15
            button.layer.borderWidth = 1
            button.tag = mode.rawValue
            button.addTarget(self, action: #selector(modeTapped(_:)), for: .touchUpInside)
            modeButtons.append(button)
            modeStack.addArrangedSubview(button)
        }

        updateModeButtons()
        return modeStack
    }

    private func makeStyleSelector() -> UIView {
        styleStack.axis = .horizontal
        styleStack.alignment = .center
        styleStack.spacing = 7
        styleStack.distribution = .fillEqually
        styleStack.heightAnchor.constraint(equalToConstant: 56).isActive = true

        for style in ReplyStyle.allCases {
            let item = UIStackView()
            item.axis = .vertical
            item.alignment = .center
            item.spacing = 2

            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: style.symbolName), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.tintColor = Palette.primary
            button.backgroundColor = style.backgroundColor
            button.layer.cornerRadius = 19
            button.layer.borderWidth = 1
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.03
            button.layer.shadowRadius = 4
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.widthAnchor.constraint(equalToConstant: 38).isActive = true
            button.heightAnchor.constraint(equalToConstant: 38).isActive = true
            button.tag = style.rawValue
            button.accessibilityLabel = "\(style.title)生成"
            button.addTarget(self, action: #selector(styleTapped(_:)), for: .touchUpInside)

            let badge = UILabel()
            badge.tag = 9001
            badge.text = "✓"
            badge.textAlignment = .center
            badge.font = .systemFont(ofSize: 8, weight: .heavy)
            badge.textColor = .white
            badge.backgroundColor = Palette.primary
            badge.layer.cornerRadius = 7
            badge.clipsToBounds = true
            badge.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(badge)
            NSLayoutConstraint.activate([
                badge.widthAnchor.constraint(equalToConstant: 15),
                badge.heightAnchor.constraint(equalToConstant: 15),
                badge.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -1),
                badge.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -1)
            ])

            let label = UILabel()
            label.text = style.title
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 9.8, weight: .semibold)
            label.textColor = Palette.secondary
            label.heightAnchor.constraint(equalToConstant: 11).isActive = true
            styleLabels[style.rawValue] = label

            styleButtons.append(button)
            item.addArrangedSubview(button)
            item.addArrangedSubview(label)
            styleStack.addArrangedSubview(item)
        }

        updateStyleButtons()
        return styleStack
    }

    private func makeContentArea() -> UIView {
        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 228).isActive = true
        return contentStack
    }

    private func configureMessageTextView() {
        messageTextView.delegate = self
        messageTextView.backgroundColor = .clear
        messageTextView.textColor = Palette.text
        messageTextView.tintColor = Palette.primary
        messageTextView.font = .systemFont(ofSize: 13.6, weight: .heavy)
        messageTextView.isScrollEnabled = false
        messageTextView.isEditable = true
        messageTextView.isSelectable = true
        messageTextView.returnKeyType = .done
        messageTextView.autocorrectionType = .no
        messageTextView.spellCheckingType = .no
        messageTextView.smartQuotesType = .no
        messageTextView.smartDashesType = .no
        messageTextView.textContainerInset = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.textContainer.maximumNumberOfLines = 2
        messageTextView.textContainer.lineBreakMode = .byTruncatingTail
        messageTextView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        messagePlaceholderLabel.font = .systemFont(ofSize: 13.4, weight: .heavy)
        messagePlaceholderLabel.textColor = Palette.primary.withAlphaComponent(0.9)
        messagePlaceholderLabel.numberOfLines = 2
        messagePlaceholderLabel.isUserInteractionEnabled = false
        messagePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.addSubview(messagePlaceholderLabel)
        NSLayoutConstraint.activate([
            messagePlaceholderLabel.leadingAnchor.constraint(equalTo: messageTextView.leadingAnchor),
            messagePlaceholderLabel.trailingAnchor.constraint(equalTo: messageTextView.trailingAnchor),
            messagePlaceholderLabel.topAnchor.constraint(equalTo: messageTextView.topAnchor, constant: 6)
        ])
    }

    private func makeUtilityRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 7
        row.distribution = .fillEqually

        row.addArrangedSubview(commandButton("刪除", action: #selector(deleteBackward)))
        row.addArrangedSubview(commandButton("空白", action: #selector(insertSpace)))
        row.addArrangedSubview(commandButton("換行", action: #selector(insertReturn)))
        row.addArrangedSubview(commandButton("切換鍵盤", action: #selector(handleNextKeyboard)))

        return row
    }

    private func commandButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.setTitleColor(Palette.secondary, for: .normal)
        button.backgroundColor = Palette.key
        button.layer.cornerRadius = 9
        button.layer.borderWidth = 0.5
        button.layer.borderColor = Palette.border.cgColor
        button.heightAnchor.constraint(equalToConstant: 31).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func replyButton(_ title: String, index: Int) -> UIControl {
        let control = UIControl()
        let isRecommended = index == 0
        let isFilled = filledIndex == index

        control.backgroundColor = Palette.card
        control.layer.cornerRadius = 12
        control.layer.borderWidth = isRecommended ? 1.2 : 0.8
        control.layer.borderColor = (isRecommended ? Palette.primary.withAlphaComponent(0.28) : Palette.border.withAlphaComponent(0.86)).cgColor
        control.layer.shadowColor = UIColor.black.cgColor
        control.layer.shadowOpacity = isRecommended ? 0.07 : 0.035
        control.layer.shadowRadius = isRecommended ? 8 : 5
        control.layer.shadowOffset = CGSize(width: 0, height: 3)
        control.heightAnchor.constraint(equalToConstant: isRecommended ? 50 : 44).isActive = true
        control.tag = index
        control.addTarget(self, action: #selector(replyTapped(_:)), for: .touchUpInside)

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(row)

        let marker = UIView()
        marker.backgroundColor = isRecommended ? Palette.primary : Palette.border
        marker.layer.cornerRadius = 2
        marker.widthAnchor.constraint(equalToConstant: 4).isActive = true
        marker.heightAnchor.constraint(equalToConstant: isRecommended ? 28 : 22).isActive = true
        row.addArrangedSubview(marker)

        let textLabel = UILabel()
        textLabel.text = title
        textLabel.font = .systemFont(ofSize: isRecommended ? 13.8 : 13.2, weight: isRecommended ? .bold : .semibold)
        textLabel.textColor = isFilled || isRecommended ? Palette.primary : Palette.text
        textLabel.numberOfLines = 2
        textLabel.lineBreakMode = .byTruncatingTail
        row.addArrangedSubview(textLabel)

        let actionLabel = UILabel()
        actionLabel.text = isFilled ? "已填入" : "填入"
        actionLabel.textAlignment = .center
        actionLabel.font = .systemFont(ofSize: 11, weight: .heavy)
        actionLabel.textColor = isFilled ? .white : Palette.primary
        actionLabel.backgroundColor = isFilled ? Palette.primary : Palette.selectedSoft
        actionLabel.layer.cornerRadius = 12
        actionLabel.clipsToBounds = true
        actionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        actionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: isFilled ? 52 : 42).isActive = true
        actionLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
        row.addArrangedSubview(actionLabel)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: control.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: -12),
            row.topAnchor.constraint(equalTo: control.topAnchor, constant: 7),
            row.bottomAnchor.constraint(equalTo: control.bottomAnchor, constant: -7)
        ])

        return control
    }

    @objc private func readClipboard() {
        loadClipboard(generateAfterRead: false)
    }

    @objc private func readClipboardAndGenerate() {
        loadClipboard(generateAfterRead: true)
    }

    @objc private func pasteActionTapped() {
        if currentReplies.first != nil && !isGenerating {
            insertPrimaryReply()
            return
        }

        let typedMessage = normalizeMessage(messageTextView.text)
        guard !typedMessage.isEmpty else {
            if hasFullAccess {
                loadClipboard(generateAfterRead: false)
            } else {
                statusMode = .noFullAccess
                messageTextView.becomeFirstResponder()
                updateStatusText()
                updatePasteInputDecorations()
            }
            return
        }

        currentMessage = typedMessage
        statusMode = .ready
        filledIndex = nil
        currentReplies = []
        aiErrorText = nil
        generationIndex += 1
        generationInstruction = "Use the selected mode and tone. Generate a direct reply for the pasted message."
        regenerateReplies()
    }

    private func loadClipboard(generateAfterRead: Bool) {
        guard hasFullAccess else {
            currentMessage = ""
            statusMode = .noFullAccess
            filledIndex = nil
            currentReplies = []
            isGenerating = false
            aiErrorText = nil
            renderContent()
            return
        }

        let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else {
            currentMessage = ""
            statusMode = .emptyClipboard
            filledIndex = nil
            currentReplies = []
            isGenerating = false
            aiErrorText = nil
            renderContent()
            return
        }

        currentMessage = normalizeMessage(text)
        statusMode = .ready
        filledIndex = nil
        currentReplies = []
        aiErrorText = nil
        isGenerating = false
        generationIndex += 1
        if generateAfterRead {
            if generationInstruction == nil {
                generationInstruction = "Use the selected mode and tone. Generate a direct reply for the copied message."
            }
            regenerateReplies()
        } else {
            renderContent()
        }
    }

    @objc private func styleTapped(_ sender: UIButton) {
        guard let style = ReplyStyle(rawValue: sender.tag) else { return }
        selectedStyle = style
        updateStyleButtons()
        filledIndex = nil
        generationIndex += 1
        generationInstruction = "Rewrite based on this tone: \(style.title). Keep it natural and paste-ready."
        generateForSelectedStyle()
    }

    @objc private func modeTapped(_ sender: UIButton) {
        guard let mode = KeyboardMode(rawValue: sender.tag) else { return }
        selectedMode = mode
        filledIndex = nil
        generationIndex += 1
        currentReplies = []
        isGenerating = false
        aiErrorText = nil
        generationInstruction = nil
        if !currentMessage.isEmpty {
            statusMode = .ready
        } else if statusMode == .filled || statusMode == .ready {
            statusMode = .idle
        }
        updateModeButtons()
        renderContent()
    }

    @objc private func cycleModeTapped() {
        let modes: [KeyboardMode] = [.invite, .reply, .opener, .comfort, .custom]
        let nextIndex = (modes.firstIndex(of: selectedMode) ?? 0) + 1
        selectedMode = modes[nextIndex % modes.count]
        modePillButton?.setTitle(headerModeTitle(), for: .normal)
        filledIndex = nil
        currentReplies = []
        isGenerating = false
        aiErrorText = nil
        generationInstruction = nil
        renderContent()
    }

    private func generateForSelectedStyle() {
        guard !currentMessage.isEmpty else {
            readClipboardAndGenerate()
            return
        }

        statusMode = .ready
        currentReplies = []
        aiErrorText = nil
        regenerateReplies()
    }

    @objc private func replyTapped(_ sender: UIControl) {
        guard sender.tag >= 0 && sender.tag < displayedReplies.count else { return }
        applyMatrixAction(sender.tag)
    }

    @objc private func insertPrimaryReply() {
        guard let reply = currentReplies.first, !reply.isEmpty else {
            readClipboard()
            return
        }
        textDocumentProxy.insertText(reply)
        filledIndex = 0
        statusMode = .filled
        renderContent()
    }

    private func applyMatrixAction(_ index: Int) {
        selectedStyle = styleForMatrixIndex(index)
        selectedMode = modeForMatrixIndex(index)
        generationInstruction = matrixInstruction(index: index)

        guard !currentMessage.isEmpty else {
            readClipboardAndGenerate()
            return
        }

        filledIndex = nil
        generationIndex += 1
        regenerateReplies()
    }

    @objc private func deleteBackward() {
        textDocumentProxy.deleteBackward()
    }

    @objc private func clearInput() {
        for _ in 0..<36 {
            textDocumentProxy.deleteBackward()
        }
        filledIndex = nil
        statusMode = currentMessage.isEmpty ? .idle : .ready
        renderContent()
    }

    @objc private func clearMessageInput() {
        currentMessage = ""
        currentReplies = []
        displayedReplies = []
        aiErrorText = nil
        generationInstruction = nil
        isGenerating = false
        generationIndex += 1
        statusMode = .idle
        syncMessageTextView()
        renderContent()
    }

    @objc private func sendPrimaryReply() {
        if let reply = currentReplies.first, !reply.isEmpty {
            textDocumentProxy.insertText(reply)
            filledIndex = 0
            statusMode = .filled
            updateStatusText()
            updatePasteInputDecorations()
        } else if currentMessage.isEmpty {
            readClipboardAndGenerate()
        } else {
            applyMatrixAction(4)
        }
    }

    @objc private func insertSpace() {
        textDocumentProxy.insertText(" ")
    }

    @objc private func insertReturn() {
        textDocumentProxy.insertText("\n")
    }

    @objc private func handleNextKeyboard() {
        advanceToNextInputMode()
    }

    private func renderContent() {
        for view in contentStack.arrangedSubviews {
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        updateModeButtons()

        updateStatusText()
        modePillButton?.setTitle(headerModeTitle(), for: .normal)

        contentStack.addArrangedSubview(pasteCard())
        if currentMessage.isEmpty {
            currentReplies = []
        }
        contentStack.addArrangedSubview(replyPanel())
    }

    private func updateStatusText() {
        if isGenerating {
            statusLabel.text = "AI 生成中"
        } else if let aiErrorText {
            statusLabel.text = aiErrorText
        } else {
            switch statusMode {
            case .noFullAccess:
                statusLabel.text = "需要完整取用"
            case .emptyClipboard:
                statusLabel.text = "剪貼簿空白"
            case .filled:
                statusLabel.text = "已填入"
            case .ready:
                statusLabel.text = currentReplies.isEmpty ? "選一格生成" : "點第一格填入"
            case .idle:
                statusLabel.text = selectedMode.status
            }
        }
    }

    private func updateModeButtons() {
        for button in modeButtons {
            let isSelected = button.tag == selectedMode.rawValue
            button.backgroundColor = isSelected ? Palette.primary : Palette.card
            button.setTitleColor(isSelected ? .white : Palette.secondary, for: .normal)
            button.layer.borderColor = (isSelected ? Palette.primary : Palette.border).cgColor
            button.alpha = isSelected ? 1 : 0.9
        }
    }

    private func pasteCard() -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)

        let inputCard = UIView()
        inputCard.backgroundColor = Palette.card
        inputCard.layer.cornerRadius = 11
        inputCard.layer.borderWidth = 0.6
        inputCard.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        inputCard.layer.shadowColor = UIColor.black.cgColor
        inputCard.layer.shadowOpacity = 0.18
        inputCard.layer.shadowRadius = 4
        inputCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        row.addArrangedSubview(inputCard)

        let inputRow = UIStackView()
        inputRow.axis = .horizontal
        inputRow.alignment = .center
        inputRow.spacing = 8
        inputRow.translatesAutoresizingMaskIntoConstraints = false
        inputCard.addSubview(inputRow)

        let icon = UIImageView(image: UIImage(systemName: "doc.on.clipboard"))
        icon.tintColor = statusMode == .noFullAccess ? Palette.blush : Palette.primary
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        inputRow.addArrangedSubview(icon)

        syncMessageTextView()
        inputRow.addArrangedSubview(messageTextView)

        let button = UIButton(type: .system)
        button.setTitle(pasteButtonTitle(), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15.2, weight: .heavy)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = statusMode == .noFullAccess ? Palette.blush : Palette.primary
        button.layer.cornerRadius = 11
        button.widthAnchor.constraint(equalToConstant: 74).isActive = true
        button.addTarget(self, action: #selector(pasteActionTapped), for: .touchUpInside)
        pasteActionButton = button
        row.addArrangedSubview(button)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            inputRow.leadingAnchor.constraint(equalTo: inputCard.leadingAnchor, constant: 16),
            inputRow.trailingAnchor.constraint(equalTo: inputCard.trailingAnchor, constant: -12),
            inputRow.topAnchor.constraint(equalTo: inputCard.topAnchor, constant: 5),
            inputRow.bottomAnchor.constraint(equalTo: inputCard.bottomAnchor, constant: -5)
        ])

        return container
    }

    private func syncMessageTextView() {
        isSyncingMessageText = true
        if messageTextView.text != currentMessage {
            messageTextView.text = currentMessage
        }
        isSyncingMessageText = false
        updatePasteInputDecorations()
    }

    private func updatePasteInputDecorations() {
        messagePlaceholderLabel.text = pastePlaceholderText()
        messagePlaceholderLabel.isHidden = !normalizeMessage(messageTextView.text).isEmpty
        messageTextView.isEditable = !isGenerating
        messageTextView.isSelectable = true
        pasteActionButton?.setTitle(pasteButtonTitle(), for: .normal)
        pasteActionButton?.backgroundColor = statusMode == .noFullAccess ? Palette.blush : Palette.primary
    }

    private func pasteButtonTitle() -> String {
        if isGenerating {
            return "..."
        }
        if currentReplies.first != nil {
            return "填入"
        }
        if !normalizeMessage(messageTextView.text).isEmpty || !currentMessage.isEmpty {
            return "生成"
        }
        return "粘貼"
    }

    private func pastePlaceholderText() -> String {
        switch statusMode {
        case .noFullAccess:
            return "點擊此處粘貼TA的對話"
        case .emptyClipboard:
            return "剪貼簿沒有文字，可長按粘貼"
        case .ready, .filled:
            return "點擊此處粘貼TA的對話"
        case .idle:
            return "點擊此處粘貼TA的對話"
        }
    }

    private func replyPanel() -> UIView {
        let panel = UIView()
        panel.backgroundColor = UIColor.clear
        panel.heightAnchor.constraint(equalToConstant: 158).isActive = true

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(row)

        row.addArrangedSubview(replyMatrix())

        let side = UIStackView()
        side.axis = .vertical
        side.spacing = 7
        side.distribution = .fillEqually
        side.widthAnchor.constraint(equalToConstant: 70).isActive = true
        side.addArrangedSubview(keyboardSideButton(systemName: "delete.left", title: nil, kind: .neutral, action: #selector(deleteBackward)))
        side.addArrangedSubview(keyboardSideButton(systemName: nil, title: "清空", kind: .neutral, action: #selector(clearMessageInput)))
        side.addArrangedSubview(keyboardSideButton(systemName: nil, title: "發送", kind: .pink, action: #selector(sendPrimaryReply)))
        row.addArrangedSubview(side)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            row.topAnchor.constraint(equalTo: panel.topAnchor),
            row.bottomAnchor.constraint(equalTo: panel.bottomAnchor)
        ])

        return panel
    }

    private func replyMatrix() -> UIStackView {
        displayedReplies = matrixReplies()

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 7
        grid.distribution = .fillEqually

        for rowIndex in 0..<3 {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 7
            row.distribution = .fillEqually

            for columnIndex in 0..<3 {
                let index = rowIndex * 3 + columnIndex
                let title = index < displayedReplies.count ? displayedReplies[index] : " "
                row.addArrangedSubview(matrixReplyButton(title, index: index))
            }

            grid.addArrangedSubview(row)
        }

        return grid
    }

    private func matrixReplyButton(_ title: String, index: Int) -> UIControl {
        let control = UIControl()
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let isPrimary = index == 4
        let isFilled = filledIndex == index
        let isDisabled = trimmedTitle.isEmpty || isGenerating
        control.tag = index
        control.backgroundColor = Palette.card
        control.layer.cornerRadius = 11
        control.layer.borderWidth = isPrimary ? 1.2 : 0.6
        control.layer.borderColor = (isPrimary ? Palette.primary.withAlphaComponent(0.34) : UIColor.black.withAlphaComponent(0.1)).cgColor
        control.layer.shadowColor = UIColor.black.cgColor
        control.layer.shadowOpacity = 0.16
        control.layer.shadowRadius = 3
        control.layer.shadowOffset = CGSize(width: 0, height: 2)
        control.alpha = isDisabled ? 0.5 : 1
        control.isUserInteractionEnabled = !isDisabled
        if !isDisabled {
            control.addTarget(self, action: #selector(replyTapped(_:)), for: .touchUpInside)
        }

        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.72
        label.font = .systemFont(ofSize: 16.2, weight: .heavy)
        label.textColor = isDisabled ? Palette.secondary : Palette.text
        label.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: control.leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: -6),
            label.topAnchor.constraint(equalTo: control.topAnchor, constant: 5),
            label.bottomAnchor.constraint(equalTo: control.bottomAnchor, constant: -5)
        ])

        return control
    }

    private func matrixReplies() -> [String] {
        [
            "😁 幽默",
            "😉 高情商",
            "😌 溫柔",
            "💞 曖昧拉扯",
            "😀 智能回覆",
            "😊 可愛",
            "😎 大男子",
            "☺️ 撒嬌",
            "🍷 甄嬛文學"
        ]
    }

    private func defaultMatrixReplies(for mode: KeyboardMode) -> [String] {
        switch mode {
        case .reply:
            return [
                "幽默",
                "智慧回覆",
                "撒嬌",
                "溫柔",
                "可愛",
                "短句",
                "曖昧拉扯",
                "直球",
                "高冷"
            ]
        case .opener:
            return [
                "日常開場",
                "共同話題",
                "輕鬆提問",
                "稱讚開場",
                "限動回覆",
                "低壓開頭",
                "可愛開場",
                "成熟開場",
                "重新開始"
            ]
        case .invite:
            return [
                "自然約",
                "吃飯",
                "咖啡",
                "週末",
                "看電影",
                "散步",
                "讓她選",
                "改天也行",
                "收尾"
            ]
        case .comfort:
            return [
                "先共感",
                "陪她",
                "安慰",
                "別說教",
                "給空間",
                "晚點聊",
                "小關心",
                "安全感",
                "不急解決"
            ]
        case .custom:
            return [
                "更自然",
                "更短",
                "更甜",
                "更冷靜",
                "更成熟",
                "更幽默",
                "別太油",
                "留問題",
                "再輕鬆點"
            ]
        }
    }

    private func matrixInstruction(index: Int) -> String {
        switch index {
        case 0:
            return "Use light humor. Make it playful and natural, not childish or exaggerated."
        case 1:
            return "Use high emotional intelligence. Read the hidden emotion, validate briefly, then give a smooth reply."
        case 2:
            return "Use a warm and gentle tone. Reassure without sounding like customer support."
        case 3:
            return "Use subtle push-pull flirting. Keep it respectful, not greasy, not sexual."
        case 4:
            return "Choose the most suitable natural reply for the context. Prioritize usefulness over style."
        case 5:
            return "Make it cute and easy to answer, but avoid acting childish or clingy."
        case 6:
            return "Make it confident and masculine, direct but respectful, no pressure."
        case 7:
            return "Make it lightly coquettish and playful, like a real chat message."
        case 8:
            return "Use elegant dramatic literary wording inspired by palace-drama style, but keep it short and paste-ready."
        default:
            return "Use the selected mode and tone. Generate one paste-ready reply."
        }
    }

    private func styleForMatrixIndex(_ index: Int) -> ReplyStyle {
        switch index {
        case 0:
            return .funny
        case 2:
            return .gentle
        case 3:
            return .flirty
        case 5, 7:
            return .gentle
        case 8:
            return .flirty
        default:
            return .gentle
        }
    }

    private func modeForMatrixIndex(_ index: Int) -> KeyboardMode {
        switch index {
        case 1, 4:
            return .reply
        case 8:
            return .custom
        default:
            return selectedMode == .custom ? .reply : selectedMode
        }
    }

    private func headerModeTitle() -> String {
        switch selectedMode {
        case .reply:
            return "根據對話"
        case .opener:
            return "開場破冰"
        case .invite:
            return "開場邀約"
        case .comfort:
            return "安撫情緒"
        case .custom:
            return "自訂語氣"
        }
    }

    private func emptyReplyCard() -> UIControl {
        let card = UIControl()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 0.8
        card.layer.borderColor = Palette.border.withAlphaComponent(0.9).cgColor
        card.addTarget(self, action: #selector(readClipboard), for: .touchUpInside)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 9
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = Palette.primary
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 24).isActive = true
        stack.addArrangedSubview(icon)

        let title = UILabel()
        title.text = isGenerating ? "正在幫你想回覆" : (currentMessage.isEmpty ? "先讀取對方訊息" : "選一種語氣生成")
        title.font = .systemFont(ofSize: 15, weight: .heavy)
        title.textColor = Palette.text
        title.textAlignment = .center
        stack.addArrangedSubview(title)

        let subtitle = UILabel()
        subtitle.text = isGenerating
            ? "通常 1-3 秒完成，完成後會自動更新回覆。"
            : (currentMessage.isEmpty ? "先到聊天 App 複製一句，再回來按讀取。" : "每按一次只產生一句，畫面更乾淨。")
        subtitle.font = .systemFont(ofSize: 11.6, weight: .semibold)
        subtitle.textColor = Palette.secondary
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 2
        stack.addArrangedSubview(subtitle)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        return card
    }

    private func aiReplyCard(_ title: String, index: Int) -> UIControl {
        let control = UIControl()
        let isFilled = filledIndex == index
        control.backgroundColor = isFilled ? Palette.primary : Palette.card
        control.layer.cornerRadius = 14
        control.layer.borderWidth = index == 0 ? 1.2 : 0.8
        control.layer.borderColor = (isFilled ? Palette.primary : (index == 0 ? Palette.primary.withAlphaComponent(0.34) : Palette.border)).cgColor
        control.layer.shadowColor = UIColor.black.cgColor
        control.layer.shadowOpacity = index == 0 ? 0.07 : 0.035
        control.layer.shadowRadius = index == 0 ? 8 : 5
        control.layer.shadowOffset = CGSize(width: 0, height: 3)
        control.tag = index
        control.addTarget(self, action: #selector(replyTapped(_:)), for: .touchUpInside)

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 9
        row.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(row)

        let label = UILabel()
        label.text = title
        label.textAlignment = .left
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 13.4, weight: index == 0 ? .heavy : .bold)
        label.textColor = isFilled ? .white : Palette.text
        row.addArrangedSubview(label)

        let action = UILabel()
        action.text = isFilled ? "已填" : "填入"
        action.textAlignment = .center
        action.font = .systemFont(ofSize: 10.4, weight: .heavy)
        action.textColor = isFilled ? Palette.primary : .white
        action.backgroundColor = isFilled ? Palette.selectedSoft : Palette.primary
        action.layer.cornerRadius = 11
        action.clipsToBounds = true
        action.setContentCompressionResistancePriority(.required, for: .horizontal)
        action.widthAnchor.constraint(greaterThanOrEqualToConstant: 42).isActive = true
        action.heightAnchor.constraint(equalToConstant: 22).isActive = true
        row.addArrangedSubview(action)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: control.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: -10),
            row.topAnchor.constraint(equalTo: control.topAnchor, constant: 7),
            row.bottomAnchor.constraint(equalTo: control.bottomAnchor, constant: -7)
        ])

        return control
    }

    private func keyboardSideButton(systemName: String?, title: String?, kind: SideButtonKind, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        if let systemName {
            let config = UIImage.SymbolConfiguration(pointSize: 21, weight: .heavy)
            button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        }
        if let title {
            button.setTitle(title, for: .normal)
        }

        let isPink = kind == .pink
        button.titleLabel?.font = .systemFont(ofSize: 15.8, weight: .heavy)
        button.tintColor = isPink ? Palette.primary : Palette.text
        button.setTitleColor(isPink ? Palette.primary : Palette.text, for: .normal)
        button.backgroundColor = isPink ? Palette.commandPink : Palette.commandKey
        button.layer.cornerRadius = 11
        button.layer.borderWidth = 0.6
        button.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.13
        button.layer.shadowRadius = 3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func sideCommandButton(systemName: String, title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 12.5, weight: .bold)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 8.8, weight: .heavy)
        button.tintColor = Palette.secondary
        button.setTitleColor(Palette.secondary, for: .normal)
        button.backgroundColor = Palette.card
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 0.7
        button.layer.borderColor = Palette.border.withAlphaComponent(0.9).cgColor
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 13, right: -12)
        button.titleEdgeInsets = UIEdgeInsets(top: 18, left: -12, bottom: 0, right: 0)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func updateStyleButtons() {
        for button in styleButtons {
            let isSelected = button.tag == selectedStyle.rawValue
            guard let style = ReplyStyle(rawValue: button.tag) else { continue }
            let config = UIImage.SymbolConfiguration(pointSize: isSelected ? 17 : 15.5, weight: isSelected ? .bold : .semibold)
            button.setImage(UIImage(systemName: style.symbolName, withConfiguration: config), for: .normal)
            button.setTitle(nil, for: .normal)
            button.tintColor = Palette.primary
            button.backgroundColor = style.backgroundColor
            button.alpha = isSelected ? 1 : 0.94
            button.transform = .identity
            button.layer.borderWidth = isSelected ? 2 : 0.9
            button.layer.borderColor = (isSelected ? Palette.primary : Palette.border).cgColor
            button.layer.shadowOpacity = isSelected ? 0.055 : 0.02
            button.viewWithTag(9001)?.isHidden = !isSelected

            if let label = styleLabels[button.tag] {
                label.text = style.title
                label.textColor = isSelected ? Palette.primary : Palette.secondary
                label.font = .systemFont(ofSize: 9.8, weight: isSelected ? .heavy : .semibold)
            }
        }
    }

    private func actionCard(title: String, subtitle: String, buttonTitle: String, toneHint: String, isWarning: Bool) -> UIView {
        let card = UIView()
        card.backgroundColor = isWarning ? UIColor(red: 251 / 255, green: 233 / 255, blue: 238 / 255, alpha: 1) : Palette.card
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = (isWarning ? Palette.blush.withAlphaComponent(0.28) : Palette.border).cgColor
        card.heightAnchor.constraint(equalToConstant: 166).isActive = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .heavy)
        titleLabel.textColor = isWarning ? Palette.blush : Palette.text
        titleLabel.textAlignment = .center
        stack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        subtitleLabel.textColor = Palette.secondary
        subtitleLabel.textAlignment = .center
        stack.addArrangedSubview(subtitleLabel)

        let button = UIButton(type: .system)
        button.setTitle(buttonTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .heavy)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Palette.primary
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 174).isActive = true
        button.addTarget(self, action: #selector(readClipboard), for: .touchUpInside)
        stack.addArrangedSubview(button)

        let hintLabel = UILabel()
        hintLabel.text = toneHint
        hintLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        hintLabel.textColor = Palette.accent
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 2
        stack.addArrangedSubview(hintLabel)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        return card
    }

    private func readPreviewCard() -> UIView {
        let card = UIView()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 11
        card.layer.borderWidth = 0.8
        card.layer.borderColor = Palette.border.withAlphaComponent(0.86).cgColor
        card.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 7
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        let icon = UIImageView(image: UIImage(systemName: "doc.on.clipboard"))
        icon.tintColor = Palette.primary.withAlphaComponent(0.76)
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 14).isActive = true
        row.addArrangedSubview(icon)

        let label = UILabel()
        label.text = preview(currentMessage, limit: 20)
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = Palette.primary
        label.numberOfLines = 1
        row.addArrangedSubview(label)

        let reload = UIButton(type: .system)
        reload.setTitle("重讀", for: .normal)
        reload.titleLabel?.font = .systemFont(ofSize: 11, weight: .bold)
        reload.setTitleColor(Palette.blush, for: .normal)
        reload.addTarget(self, action: #selector(readClipboard), for: .touchUpInside)
        row.addArrangedSubview(reload)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            row.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        return card
    }

    private func regenerateReplies() {
        let message = currentMessage
        guard !message.isEmpty else {
            currentReplies = []
            isGenerating = false
            aiErrorText = nil
            renderContent()
            return
        }

        let requestID = generationIndex
        currentReplies = []
        isGenerating = true
        aiErrorText = nil
        renderContent()

        requestAIReplies(
            message: message,
            style: selectedStyle,
            mode: selectedMode,
            instruction: generationInstruction,
            requestID: requestID
        )
    }

    private func requestAIReplies(message: String, style: ReplyStyle, mode: KeyboardMode, instruction: String?, requestID: Int) {
        guard let endpoint = AiConfig.keyboardReplyEndpoint else {
            finishAIRequest(requestID: requestID, replies: [], errorText: "AI 尚未設定")
            return
        }

        let userID = keyboardUserID()
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 18
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userID, forHTTPHeaderField: "X-Device-Fingerprint")

        let payload: [String: Any] = [
            "user_id": userID,
            "message": message,
            "user_message": message,
            "system_prompt": aiSystemPrompt(style: style, mode: mode, instruction: instruction),
            "tone": style.title,
            "mode": mode.title,
            "instruction": instruction ?? "",
            "is_pro": SharedConfig.isPro
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            finishAIRequest(requestID: requestID, replies: [], errorText: "AI 暫時不可用")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            var replies: [String] = []
            var errorText: String?

            if error != nil {
                errorText = "AI 網路失敗"
            } else if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                errorText = "AI 服務忙碌"
            } else if let data {
                replies = self.parseAIReplies(from: data)
                if replies.isEmpty {
                    errorText = "AI 格式錯誤"
                }
            } else {
                errorText = "AI 沒有回覆"
            }

            self.finishAIRequest(requestID: requestID, replies: replies, errorText: errorText)
        }.resume()
    }

    private func finishAIRequest(requestID: Int, replies: [String], errorText: String?) {
        DispatchQueue.main.async {
            guard requestID == self.generationIndex else { return }
            self.isGenerating = false

            var cleaned = replies
                .map { self.cleanReply($0) }
                .filter { !$0.isEmpty }
                .prefix(1)

            if cleaned.isEmpty {
                cleaned = self.makeReplies(
                    for: self.selectedStyle,
                    mode: self.selectedMode,
                    message: self.currentMessage
                )
                .map { self.cleanReply($0) }
                .filter { !$0.isEmpty }
                .prefix(1)
            }

            if !cleaned.isEmpty && self.statusMode != .filled {
                self.currentReplies = Array(cleaned)
                self.aiErrorText = nil
                self.statusMode = .ready
            } else if let errorText, self.statusMode != .filled {
                self.aiErrorText = errorText
            }

            self.renderContent()
        }
    }

    private func aiSystemPrompt(style: ReplyStyle, mode: KeyboardMode, instruction: String?) -> String {
        let extraInstruction = instruction.map { "\n        - Extra user-selected action: \($0)" } ?? ""
        return """
        You are LoveKey, an AI keyboard assistant for dating and everyday chat.
        The user input is a message from the other person, not a question to you.
        Return only a JSON object with one key "replies" and exactly one string item in an array.

        Requirements:
        - Reply only in the same language as the user's message. If the message is English, reply in English only. If it is Japanese, reply in Japanese only. If it is Traditional Chinese, use natural Taiwan Traditional Chinese.
        - Generate exactly 1 reply that can be pasted directly into a chat app.
        - Scenario: \(mode.title). Tone: \(style.title).
        - Treat the input as the other person's latest chat message. Infer whether it is teasing, tired, cold, angry, inviting, refusing, casual slang, or small talk.
        - If the message means "隨便 / 你決定 / 都可以", do not say "驚喜". Choose a simple low-pressure next step instead.
        \(extraInstruction)
        - Each reply must be natural, concise, and context-aware. Do not sound like a template, customer support, motivational quote, or generic assistant answer.
        - Do not invent specific past facts, places, restaurants, movies, promises, or plans unless the user's message already mentions them.
        - Avoid exaggerated certainty such as "你一定會喜歡", "保證", "絕對", unless the user already said it.
        - For casual slang or profanity, keep the reply relaxed and socially natural. Do not over-explain or moralize.
        - Prefer replies that keep the conversation moving with a light question or an easy next step.
        - Never output placeholder text such as "reply 1", "sentence A", "回覆1", or "句子A".
        - Avoid manipulation, guilt-tripping, pressure, sexual explicitness, insults, or promises.
        - Do not mention AI, model, high EQ, prompt, template, or the app.
        - Do not explain. JSON only. Example shape: {"replies":["actual message"]}

        Style examples to learn from, not copy blindly:
        - "幹免費的喔" -> {"replies":["對啊，這麼好康我也想確認一下 😂"]}
        - "我今天真的有點累" -> {"replies":["辛苦了，先休息一下，晚點再慢慢聊。"]}
        - "隨便啦 你決定就好" -> {"replies":["那我來安排一個輕鬆的，你只要負責出現。"]}
        - "哈哈哈" -> {"replies":["笑這麼開心，快說你剛剛想到什麼。"]}
        """
    }

    private func parseAIReplies(from data: Data) -> [String] {
        if
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let reply = object["reply"] as? String
        {
            return [reply]
        }

        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = object["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            return []
        }

        let jsonText = extractJSONObject(from: content)
        if
            let jsonData = jsonText.data(using: .utf8),
            let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let replies = parsed["replies"] as? [String]
        {
            return replies
        }

        if
            let jsonData = jsonText.data(using: .utf8),
            let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let reply = parsed["replies"] as? String
        {
            return [reply]
        }

        if
            let jsonData = jsonText.data(using: .utf8),
            let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let reply = parsed["reply"] as? String
        {
            return [reply]
        }

        if
            let jsonData = jsonText.data(using: .utf8),
            let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let replies = parsed["replies"] as? [[String: Any]]
        {
            return replies.compactMap { $0["text"] as? String }
        }

        return content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func extractJSONObject(from text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard
            let start = cleaned.firstIndex(of: "{"),
            let end = cleaned.lastIndex(of: "}"),
            start <= end
        else {
            return cleaned
        }

        return String(cleaned[start...end])
    }

    private func cleanReply(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixes = ["1.", "2.", "3.", "-", "•", "\""]
        for prefix in prefixes where cleaned.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if cleaned.hasSuffix("\"") {
            cleaned.removeLast()
        }
        return cleaned
    }

    private func normalizeMessage(_ text: String) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return lines.joined(separator: " ")
    }

    private func keyboardUserID() -> String {
        let key = "lovekey_keyboard_user_id"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }

        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: key)
        return created
    }

    private func preview(_ text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit)) + "..."
    }

    private func makeReplies(for style: ReplyStyle, mode: KeyboardMode, message: String) -> [String] {
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return []
        }

        switch mode {
        case .reply:
            break
        case .opener:
            return openerReplies(for: style, message: text)
        case .invite:
            return inviteReplies(for: style, message: text)
        case .comfort:
            return comfortReplies(for: style, message: text)
        case .custom:
            return rewriteReplies(for: style, message: text)
        }

        let intent = detectIntent(in: text)
        return replies(for: intent, style: style)
    }

    private func openerReplies(for style: ReplyStyle, message: String) -> [String] {
        switch style {
        case .gentle:
            return [
                "剛看到你這句，想問你現在還好嗎？",
                "我先不亂接話，想聽你多說一點。",
                "你剛剛那句讓我有點在意，可以聊聊嗎？"
            ]
        case .funny:
            return [
                "我腦袋剛重新開機，先讓我接住這句。",
                "這句有點難，我先用不尷尬模式回你。",
                "我本來想裝懂，但還是想認真問一下。"
            ]
        case .flirty:
            return [
                "看到你這句，我突然很想多跟妳聊一下。",
                "妳這樣講，我會忍不住想接近一點。",
                "我先承認，我有被妳這句吸引到。"
            ]
        case .apology:
            return [
                "我先確認一下，我是不是剛剛沒有理解好？",
                "如果我剛剛接得不好，我想重新回你。",
                "我不想敷衍你，這句我想好好接。"
            ]
        }
    }

    private func inviteReplies(for style: ReplyStyle, message: String) -> [String] {
        switch style {
        case .gentle:
            return [
                "那找個你舒服的時間，我們一起去放鬆一下。",
                "如果你願意，我可以安排一個不趕的地方。",
                "我們改天見面慢慢聊，應該會比打字更好。"
            ]
        case .funny:
            return [
                "這題適合面對面解，我負責找地方，你負責出現。",
                "不如把這段聊天升級成吃飯任務？",
                "我覺得我們需要一杯飲料來協助破案。"
            ]
        case .flirty:
            return [
                "那我想約妳出來，把這句話當面聽完。",
                "給我一個機會，帶妳去一個適合慢慢聊的地方。",
                "比起一直打字，我更想坐在妳旁邊聽妳說。"
            ]
        case .apology:
            return [
                "如果你願意，我想找時間當面把話說清楚。",
                "我不想只靠訊息補救，想認真跟你聊一次。",
                "找個你方便的時間，我好好跟你說。"
            ]
        }
    }

    private func comfortReplies(for style: ReplyStyle, message: String) -> [String] {
        switch style {
        case .gentle:
            return [
                "你先不用急著回，我在這裡。",
                "今天已經夠累了，先照顧好自己。",
                "想說我就聽，不想說我也陪你安靜一下。"
            ]
        case .funny:
            return [
                "今天先把自己放第一順位，其他等等再說。",
                "壞心情先暫停，我幫你守一下出口。",
                "你先休息，我晚點負責講點不太爛的話。"
            ]
        case .flirty:
            return [
                "妳不用一直很堅強，在我這裡可以放鬆一點。",
                "如果可以，我現在會想抱妳一下。",
                "妳先把情緒放下來，我陪妳慢慢整理。"
            ]
        case .apology:
            return [
                "我剛剛沒有顧到你的感受，抱歉。",
                "你現在不舒服，我先不逼你回我。",
                "我會把語氣放慢一點，先陪你把心情穩住。"
            ]
        }
    }

    private func rewriteReplies(for style: ReplyStyle, message: String) -> [String] {
        let shortText = preview(message, limit: 18)
        switch style {
        case .gentle:
            return [
                "我懂你的意思，我們慢慢來就好。",
                "我想把這句說得溫柔一點：\(shortText)",
                "先不急著下結論，我想聽你真正的想法。"
            ]
        case .funny:
            return [
                "這句我幫你換成比較不尷尬的版本。",
                "我先把氣氛救回來：\(shortText)",
                "我認真回，但盡量不要讓場面太硬。"
            ]
        case .flirty:
            return [
                "我想把這句說得更靠近你一點。",
                "如果是對妳，我會這樣說：\(shortText)",
                "這句我不想太普通，想讓妳感覺到我在意。"
            ]
        case .apology:
            return [
                "我換個方式說，剛剛那句可能不夠好。",
                "我想重新表達一次，不讓你誤會。",
                "如果我剛剛說重了，我先收回，重新講。"
            ]
        }
    }

    private func detectIntent(in text: String) -> ChatIntent {
        let lower = text.lowercased()
        let isConflict = containsAny(lower, ["算了", "不用", "沒差", "隨便", "生氣", "不爽", "吵", "討厭", "不想理", "你每次", "又來", "失望", "不適合"])
        let isEmotionalLow = containsAny(lower, ["好累", "很累", "心情不好", "壓力", "煩", "不舒服", "想哭", "崩潰", "不想說話", "沒力", "好難過"])
        let isLogistics = containsAny(lower, ["煮飯", "收完", "上樓", "小孩", "孩子", "接小孩", "回家", "差不多時間", "家裡", "忙完", "開會", "在路上", "等等回", "晚點回"])
        let isFoodOrDate = containsAny(lower, ["吃", "喝", "火鍋", "餐廳", "宵夜", "晚餐", "午餐", "咖啡", "無聊", "出去", "週末", "放假", "逛", "電影", "見面"])
        let isFlirting = containsAny(lower, ["想你", "想妳", "你猜", "妳猜", "不要", "你很煩", "妳很煩", "壞欸", "討厭啦", "害羞", "想見", "撒嬌"])
        let isComplimentStory = containsAny(lower, ["照片", "自拍", "限動", "穿搭", "好看", "漂亮", "可愛", "風景", "妝", "髮型", "衣服", "裙", "洋裝"])
        let isChoice = containsAny(lower, ["哪個", "哪一個", "選哪", "a還是b", "a 或 b", "a或b", "要不要", "吃什麼", "去哪", "你覺得", "你決定"])
        let isCasualBanter = containsAny(lower, ["幹", "靠", "笑死", "真的假的", "太扯", "免費", "不用錢", "用的喔", "蛤", "傻眼", "哇靠", "扯欸", "也太"])
        let isCold = containsAny(lower, ["嗯", "對", "好", "哈哈", "喔"]) && text.count <= 6
        let isTopicDead = containsAny(lower, ["哈哈哈", "😂", "🤣", "貼圖", "表情", "已讀", "不知道", "沒事", "還好"])

        if isConflict { return .conflict }
        if isEmotionalLow { return .emotionalLow }
        if isLogistics { return .logistics }
        if isFoodOrDate { return .foodOrDate }
        if isFlirting { return .flirting }
        if isComplimentStory { return .complimentStory }
        if isChoice { return .choice }
        if isCasualBanter { return .casualBanter }
        if isCold { return .cold }
        if isTopicDead { return .topicDead }
        return .daily
    }

    private func replies(for intent: ChatIntent, style: ReplyStyle) -> [String] {
        switch intent {
        case .conflict:
            switch style {
            case .gentle:
                return [
                    "我先聽你說",
                    "我不想跟你硬碰硬，先把你的感受聽完整。",
                    "如果剛剛讓你不舒服，是我沒處理好，我想重新說。"
                ]
            case .funny:
                return [
                    "我先閉嘴三秒",
                    "這題我不能嘴硬，不然等等我會輸得更慘。",
                    "給我一次重答機會，我這次不用爛答案敷衍你。"
                ]
            case .flirty:
                return [
                    "我不想惹妳氣",
                    "妳生氣我會緊張，但我更想把妳哄好。",
                    "先別判我死刑，讓我好好補償妳一次。"
                ]
            case .apology:
                return [
                    "我剛剛沒做好",
                    "先不辯解，我想把你的感受聽完。",
                    "如果是我讓你失望，我會改，不是只說說。"
                ]
            }

        case .emotionalLow:
            switch style {
            case .gentle:
                return [
                    "先別硬撐",
                    "今天已經夠累了，先把自己照顧好。",
                    "你想安靜一下也可以，我在這裡陪你。"
                ]
            case .funny:
                return [
                    "今天先省電",
                    "你今天的任務只剩活著和好好休息。",
                    "壞心情先丟旁邊，我負責晚點逗你一下。"
                ]
            case .flirty:
                return [
                    "想抱一下妳",
                    "今天辛苦妳了，壞心情先交給我保管。",
                    "妳不用一直很堅強，在我這裡可以放鬆一點。"
                ]
            case .apology:
                return [
                    "我剛剛沒注意到",
                    "你已經很累了，我不該再讓你有壓力。",
                    "你先休息，我會把節奏放慢一點。"
                ]
            }

        case .logistics:
            switch style {
            case .gentle:
                return [
                    "你先忙完",
                    "家裡的事先處理，晚點有空再回我就好。",
                    "不急，我等你忙完再聊。"
                ]
            case .funny:
                return [
                    "先解主線任務",
                    "你先處理現實副本，我先在旁邊乖乖掛機。",
                    "等你忙完再回我，我不搶小孩和家務的順位。"
                ]
            case .flirty:
                return [
                    "那我等妳忙完",
                    "妳先忙家裡，我晚點再找妳撒嬌。",
                    "等妳空下來，我再把妳的時間偷一點走。"
                ]
            case .apology:
                return [
                    "那你先忙",
                    "剛剛是我沒抓好時間，你先處理手邊的事。",
                    "你忙完再回我就好，我不催你。"
                ]
            }

        case .foodOrDate:
            switch style {
            case .gentle:
                return [
                    "我來安排",
                    "你不用想太多，我找個舒服一點的地方。",
                    "我們吃完可以慢慢散步，不用趕行程。"
                ]
            case .funny:
                return [
                    "胃已經投票了",
                    "我覺得現在最該解決的是我們的晚餐危機。",
                    "要不要交給我選，選難吃我負責被你唸。"
                ]
            case .flirty:
                return [
                    "想坐妳旁邊",
                    "吃什麼都可以，重點是跟妳一起。",
                    "要不要我帶妳去一家，我覺得很適合妳的店。"
                ]
            case .apology:
                return [
                    "我來決定",
                    "剛剛不該一直丟給你選，我來安排就好。",
                    "這次我負責找地方，你只要舒服出門就好。"
                ]
            }

        case .flirting:
            switch style {
            case .gentle:
                return [
                    "你這樣說我會想很多",
                    "我先不亂猜，但你這句真的有點可愛。",
                    "那我可以把這句當成你有一點想我嗎?"
                ]
            case .funny:
                return [
                    "這句有陷阱",
                    "你這樣講我會誤會，而且是自願誤會的那種。",
                    "我先記下來，等等當成你偷偷想我。"
                ]
            case .flirty:
                return [
                    "有點犯規",
                    "妳這樣說，我會忍不住更想靠近妳。",
                    "那妳要不要承認，其實也有一點想我?"
                ]
            case .apology:
                return [
                    "我剛剛太急了",
                    "如果我撩得太快，你跟我說，我會放慢。",
                    "我想靠近你，但不想讓你有壓力。"
                ]
            }

        case .complimentStory:
            switch style {
            case .gentle:
                return [
                    "這張很好看",
                    "你今天的狀態看起來很舒服，很自然。",
                    "這種感覺很適合你，不會太刻意但很有氣質。"
                ]
            case .funny:
                return [
                    "這張有加分",
                    "這張照片有點危險，會讓人多看兩眼。",
                    "我本來想滑走，結果被你這張攔住了。"
                ]
            case .flirty:
                return [
                    "妳今天很好看",
                    "這張有點犯規，我看完會想見妳。",
                    "妳這樣出現，我很難假裝沒被吸引。"
                ]
            case .apology:
                return [
                    "我剛剛沒誇到重點",
                    "不是敷衍，你這張真的很好看。",
                    "我應該直接說，你今天很有魅力。"
                ]
            }

        case .choice:
            switch style {
            case .gentle:
                return [
                    "我選第一個",
                    "我覺得第一個比較適合你，舒服又不容易出錯。",
                    "如果你想輕鬆一點，我會選比較不累的那個。"
                ]
            case .funny:
                return [
                    "我投第一個",
                    "我選第一個，錯了我負責被你笑。",
                    "不要再讓選擇困難霸凌我們了，我先選。"
                ]
            case .flirty:
                return [
                    "我選跟妳一起",
                    "選哪個都可以，但我比較想選能多陪妳的那個。",
                    "如果是跟妳，我其實兩個都願意。"
                ]
            case .apology:
                return [
                    "我來決定",
                    "剛剛不該讓你一直想，我先選一個。",
                    "你如果不喜歡，我們再換，我不會硬拗。"
                ]
            }

        case .casualBanter:
            switch style {
            case .gentle:
                return [
                    "可以先試看看",
                    "免費的先用用看，不順再換掉也不虧。",
                    "你先試，我比較想知道你用起來覺得順不順。"
                ]
            case .funny:
                return [
                    "免費最香了",
                    "先試用，不好用我再陪你一起吐槽。",
                    "免費的先收下，真的雷再把它列入黑名單。"
                ]
            case .flirty:
                return [
                    "免費是重點嗎",
                    "免費可以先用，但我比較想知道妳喜不喜歡。",
                    "妳先試，覺得好用再回來跟我炫耀一下。"
                ]
            case .apology:
                return [
                    "我剛剛沒講清楚",
                    "意思是可以先免費試用，不合適再停掉。",
                    "你先不用有壓力，覺得不好用就不要勉強。"
                ]
            }

        case .cold:
            switch style {
            case .gentle:
                return [
                    "我懂",
                    "你如果現在不想多說也沒關係。",
                    "那我先不吵你，等你想聊我再陪你。"
                ]
            case .funny:
                return [
                    "收到一個字",
                    "這個回覆很精簡，我先合理懷疑你在省電。",
                    "那我先派一個輕鬆話題來救場。"
                ]
            case .flirty:
                return [
                    "妳好冷淡喔",
                    "只回一個字，我會忍不住想多討一點注意。",
                    "那我晚點再來煩妳一下，讓妳多回幾個字。"
                ]
            case .apology:
                return [
                    "是不是我剛剛太煩",
                    "如果我剛剛講得不對，你可以直接跟我說。",
                    "我先放慢一點，不逼你現在回。"
                ]
            }

        case .topicDead:
            switch style {
            case .gentle:
                return [
                    "換個輕鬆的",
                    "那我問你一個不用動腦的問題。",
                    "今天有沒有一件小事，讓你覺得還不錯?"
                ]
            case .funny:
                return [
                    "我來救場",
                    "這個話題好像快陣亡了，我先換一個。",
                    "快問快答：今天心情是幾分?"
                ]
            case .flirty:
                return [
                    "那我換個問題",
                    "如果晚點只能跟一個人聊天，妳會選誰?",
                    "我先自薦一下，陪妳聊到不無聊。"
                ]
            case .apology:
                return [
                    "我剛剛接得不好",
                    "這個話題有點乾，我換個自然一點的。",
                    "你今天比較想聊輕鬆的，還是想安靜一下?"
                ]
            }

        case .daily:
            switch style {
            case .gentle:
                return [
                    "今天還順利嗎",
                    "我剛剛想到你，就想問你今天過得怎麼樣。",
                    "如果今天有點累，晚點可以慢慢跟我說。"
                ]
            case .funny:
                return [
                    "今天戰況如何",
                    "我來例行關心一下，你今天有沒有被生活追著跑?",
                    "如果今天很累，我可以先提供精神鼓掌服務。"
                ]
            case .flirty:
                return [
                    "有點想妳",
                    "今天忙歸忙，但我還是有想到妳。",
                    "妳今天過得好不好，我想聽妳親口說。"
                ]
            case .apology:
                return [
                    "我剛剛回慢了",
                    "不是不想回你，是剛剛真的卡住了。",
                    "現在有空了，我想好好跟你聊。"
                ]
            }
        }
    }

    private func containsAny(_ text: String, _ needles: [String]) -> Bool {
        for needle in needles where text.contains(needle) {
            return true
        }
        return false
    }

}

extension KeyboardViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard textView === messageTextView, !isSyncingMessageText else { return }

        let previousMessageWasEmpty = currentMessage.isEmpty
        let newMessage = normalizeMessage(textView.text)
        let needsReplyPanelRefresh = !currentReplies.isEmpty || aiErrorText != nil || isGenerating || filledIndex != nil

        currentMessage = newMessage
        statusMode = newMessage.isEmpty ? .idle : .ready
        currentReplies = []
        displayedReplies = []
        filledIndex = nil
        aiErrorText = nil
        isGenerating = false
        generationInstruction = nil
        generationIndex += 1

        if needsReplyPanelRefresh || previousMessageWasEmpty != newMessage.isEmpty {
            renderContent()
            messageTextView.becomeFirstResponder()
        } else {
            updateStatusText()
            updatePasteInputDecorations()
        }
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

private final class PasteInputTextView: UITextView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
