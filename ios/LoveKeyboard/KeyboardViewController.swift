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

    private enum Palette {
        static let background = UIColor(red: 246 / 255, green: 244 / 255, blue: 238 / 255, alpha: 1)
        static let card = UIColor(red: 255 / 255, green: 254 / 255, blue: 251 / 255, alpha: 1)
        static let primary = UIColor(red: 18 / 255, green: 67 / 255, blue: 48 / 255, alpha: 1)
        static let accent = UIColor(red: 139 / 255, green: 111 / 255, blue: 71 / 255, alpha: 1)
        static let blush = UIColor(red: 184 / 255, green: 67 / 255, blue: 92 / 255, alpha: 1)
        static let text = UIColor(red: 28 / 255, green: 28 / 255, blue: 28 / 255, alpha: 1)
        static let secondary = UIColor(red: 105 / 255, green: 96 / 255, blue: 88 / 255, alpha: 1)
        static let border = UIColor(red: 226 / 255, green: 222 / 255, blue: 214 / 255, alpha: 1)
        static let key = UIColor(red: 234 / 255, green: 232 / 255, blue: 226 / 255, alpha: 1)
        static let selectedSoft = UIColor(red: 228 / 255, green: 240 / 255, blue: 229 / 255, alpha: 1)
        static let warmYellow = UIColor(red: 245 / 255, green: 230 / 255, blue: 184 / 255, alpha: 1)
        static let roseSoft = UIColor(red: 245 / 255, green: 214 / 255, blue: 220 / 255, alpha: 1)
        static let navySoft = UIColor(red: 214 / 255, green: 224 / 255, blue: 236 / 255, alpha: 1)
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
    private var currentTemplates: [String] = []
    private var selectedStyle: ReplyStyle = .gentle
    private var selectedMode: KeyboardMode = .reply
    private var currentMessage = ""
    private var statusMode: StatusMode = .idle
    private var generationIndex = 0
    private var filledIndex: Int?

    private enum StatusMode {
        case idle
        case emptyClipboard
        case noFullAccess
        case ready
        case filled
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        renderContent()
    }

    private func setupView() {
        view.backgroundColor = Palette.background
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 352).isActive = true

        rootStack.axis = .vertical
        rootStack.spacing = 5
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -8)
        ])

        rootStack.addArrangedSubview(makeHeader())
        rootStack.addArrangedSubview(makeModeTabs())
        rootStack.addArrangedSubview(makeContentArea())
        rootStack.addArrangedSubview(makeStyleSelector())

        renderContent()
    }

    private func makeHeader() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8

        let title = UILabel()
        title.text = "LoveKey"
        title.font = .systemFont(ofSize: 16, weight: .heavy)
        title.textColor = Palette.primary
        row.addArrangedSubview(title)

        statusLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        statusLabel.textColor = Palette.accent
        statusLabel.textAlignment = .right
        statusLabel.numberOfLines = 1
        row.addArrangedSubview(statusLabel)

        return row
    }

    private func makeModeTabs() -> UIView {
        modeStack.axis = .horizontal
        modeStack.alignment = .fill
        modeStack.spacing = 6
        modeStack.distribution = .fillEqually
        modeStack.heightAnchor.constraint(equalToConstant: 34).isActive = true

        for mode in KeyboardMode.allCases {
            let button = UIButton(type: .system)
            button.setTitle(mode.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12.2, weight: .heavy)
            button.layer.cornerRadius = 12
            button.layer.borderWidth = 0.8
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
        styleStack.spacing = 8
        styleStack.distribution = .fillEqually
        styleStack.heightAnchor.constraint(equalToConstant: 46).isActive = true

        for style in ReplyStyle.allCases {
            let item = UIStackView()
            item.axis = .vertical
            item.alignment = .center
            item.spacing = 1

            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: style.symbolName), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.tintColor = Palette.primary
            button.backgroundColor = style.backgroundColor
            button.layer.cornerRadius = 17
            button.widthAnchor.constraint(equalToConstant: 34).isActive = true
            button.heightAnchor.constraint(equalToConstant: 34).isActive = true
            button.tag = style.rawValue
            button.addTarget(self, action: #selector(styleTapped(_:)), for: .touchUpInside)

            let badge = UILabel()
            badge.tag = 9001
            badge.text = "✓"
            badge.textAlignment = .center
            badge.font = .systemFont(ofSize: 8, weight: .heavy)
            badge.textColor = .white
            badge.backgroundColor = Palette.primary
            badge.layer.cornerRadius = 6.5
            badge.clipsToBounds = true
            badge.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(badge)
            NSLayoutConstraint.activate([
                badge.widthAnchor.constraint(equalToConstant: 13),
                badge.heightAnchor.constraint(equalToConstant: 13),
                badge.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -1),
                badge.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -1)
            ])

            let label = UILabel()
            label.text = style.title
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 8.6, weight: .semibold)
            label.textColor = Palette.secondary
            label.heightAnchor.constraint(equalToConstant: 9).isActive = true
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
        contentStack.spacing = 6
        contentStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 212).isActive = true
        return contentStack
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

    @objc private func readClipboardAndGenerate() {
        guard hasFullAccess else {
            currentMessage = ""
            statusMode = .noFullAccess
            filledIndex = nil
            renderContent()
            return
        }

        let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else {
            currentMessage = ""
            statusMode = .emptyClipboard
            filledIndex = nil
            renderContent()
            return
        }

        currentMessage = normalizeMessage(text)
        statusMode = .ready
        filledIndex = nil
        generationIndex += 1
        renderContent()
    }

    @objc private func styleTapped(_ sender: UIButton) {
        guard let style = ReplyStyle(rawValue: sender.tag) else { return }
        selectedStyle = style
        updateStyleButtons()
        filledIndex = nil
        if !currentMessage.isEmpty {
            generationIndex += 1
            statusMode = .ready
        }
        renderContent()
    }

    @objc private func modeTapped(_ sender: UIButton) {
        guard let mode = KeyboardMode(rawValue: sender.tag) else { return }
        selectedMode = mode
        filledIndex = nil
        if !currentMessage.isEmpty {
            statusMode = .ready
        } else if statusMode == .filled || statusMode == .ready {
            statusMode = .idle
        }
        updateModeButtons()
        renderContent()
    }

    @objc private func replyTapped(_ sender: UIControl) {
        guard !currentMessage.isEmpty else {
            statusMode = .idle
            renderContent()
            return
        }
        guard sender.tag >= 0 && sender.tag < currentReplies.count else { return }
        textDocumentProxy.insertText(currentReplies[sender.tag])
        filledIndex = sender.tag
        statusMode = .filled
        renderContent()
    }

    @objc private func templateTapped(_ sender: UIControl) {
        guard sender.tag >= 0 && sender.tag < currentTemplates.count else { return }
        textDocumentProxy.insertText(currentTemplates[sender.tag])
        filledIndex = sender.tag
        statusMode = .filled
        renderContent()
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

        switch statusMode {
        case .noFullAccess:
            statusLabel.text = "需要完整取用"
        case .emptyClipboard:
            statusLabel.text = "剪貼簿空白"
        case .filled:
            statusLabel.text = "已填入"
        case .idle, .ready:
            statusLabel.text = selectedMode.status
        }

        contentStack.addArrangedSubview(pasteCard())
        currentTemplates = templatesForCurrentMode()
        contentStack.addArrangedSubview(templatePanel())
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
        let card = UIControl()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 0.8
        card.layer.borderColor = Palette.border.withAlphaComponent(0.9).cgColor
        card.heightAnchor.constraint(equalToConstant: 50).isActive = true
        card.addTarget(self, action: #selector(readClipboardAndGenerate), for: .touchUpInside)

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        let icon = UIImageView(image: UIImage(systemName: "doc.on.clipboard"))
        icon.tintColor = statusMode == .noFullAccess ? Palette.blush : Palette.primary
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        row.addArrangedSubview(icon)

        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 12.6, weight: .semibold)
        label.textColor = Palette.text

        switch statusMode {
        case .noFullAccess:
            label.text = "開啟完整取用後，就能讀取複製的對話"
        case .emptyClipboard:
            label.text = "剪貼簿目前沒有文字，先到聊天 App 複製一句"
        case .ready, .filled:
            label.text = preview(currentMessage, limit: 34)
        case .idle:
            label.text = "貼上對方訊息，AI 會依照模式給你可直接送出的句子"
        }

        row.addArrangedSubview(label)

        let button = UIButton(type: .system)
        button.setTitle(currentMessage.isEmpty ? "貼上" : "重讀", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .heavy)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = statusMode == .noFullAccess ? Palette.blush : Palette.primary
        button.layer.cornerRadius = 12
        button.widthAnchor.constraint(equalToConstant: 54).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.addTarget(self, action: #selector(readClipboardAndGenerate), for: .touchUpInside)
        row.addArrangedSubview(button)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 6),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -6)
        ])

        return card
    }

    private func templatePanel() -> UIView {
        let panel = UIView()
        panel.backgroundColor = UIColor.clear
        panel.heightAnchor.constraint(equalToConstant: 156).isActive = true

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.spacing = 7
        row.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(row)

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 7
        grid.distribution = .fillEqually
        row.addArrangedSubview(grid)

        for rowIndex in 0..<3 {
            let templateRow = UIStackView()
            templateRow.axis = .horizontal
            templateRow.spacing = 7
            templateRow.distribution = .fillEqually
            for columnIndex in 0..<3 {
                let index = rowIndex * 3 + columnIndex
                let title = index < currentTemplates.count ? currentTemplates[index] : ""
                templateRow.addArrangedSubview(templateButton(title, index: index))
            }
            grid.addArrangedSubview(templateRow)
        }

        let side = UIStackView()
        side.axis = .vertical
        side.spacing = 7
        side.distribution = .fillEqually
        side.widthAnchor.constraint(equalToConstant: 46).isActive = true
        side.addArrangedSubview(sideCommandButton(systemName: "delete.left", title: "刪", action: #selector(deleteBackward)))
        side.addArrangedSubview(sideCommandButton(systemName: "xmark", title: "清", action: #selector(clearInput)))
        side.addArrangedSubview(sideCommandButton(systemName: "return", title: "換", action: #selector(insertReturn)))
        side.addArrangedSubview(sideCommandButton(systemName: "globe", title: "鍵", action: #selector(handleNextKeyboard)))
        row.addArrangedSubview(side)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            row.topAnchor.constraint(equalTo: panel.topAnchor),
            row.bottomAnchor.constraint(equalTo: panel.bottomAnchor)
        ])

        return panel
    }

    private func templateButton(_ title: String, index: Int) -> UIControl {
        let control = UIControl()
        let isFilled = filledIndex == index
        control.backgroundColor = isFilled ? Palette.primary : Palette.card
        control.layer.cornerRadius = 12
        control.layer.borderWidth = 0.8
        control.layer.borderColor = (isFilled ? Palette.primary : Palette.border).cgColor
        control.tag = index
        control.addTarget(self, action: #selector(templateTapped(_:)), for: .touchUpInside)

        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 13.2, weight: .bold)
        label.textColor = isFilled ? .white : Palette.text
        label.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: control.leadingAnchor, constant: 7),
            label.trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: -7),
            label.centerYAnchor.constraint(equalTo: control.centerYAnchor)
        ])

        return control
    }

    private func sideCommandButton(systemName: String, title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 9, weight: .heavy)
        button.tintColor = Palette.secondary
        button.setTitleColor(Palette.secondary, for: .normal)
        button.backgroundColor = Palette.key
        button.layer.cornerRadius = 11
        button.layer.borderWidth = 0.8
        button.layer.borderColor = Palette.border.cgColor
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: -12)
        button.titleEdgeInsets = UIEdgeInsets(top: 18, left: -12, bottom: 0, right: 0)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func templatesForCurrentMode() -> [String] {
        let dynamicReplies = currentMessage.isEmpty ? [] : makeReplies(for: selectedStyle, message: currentMessage)

        switch selectedMode {
        case .reply:
            let fallback = [
                "我懂你的意思",
                "那我來安排",
                "先別急",
                "你想怎麼做",
                "我陪你聊",
                "聽起來不錯",
                "可以啊",
                "我認真回你",
                "換個說法"
            ]
            return Array((dynamicReplies + fallback).prefix(9))
        case .opener:
            return [
                "剛忙完",
                "今天順利嗎",
                "想到你",
                "有空聊嗎",
                "分享一件事",
                "你在幹嘛",
                "早安",
                "晚安",
                "今天好嗎"
            ]
        case .invite:
            return [
                "週末有空嗎",
                "一起吃飯",
                "喝咖啡嗎",
                "去散步",
                "看電影",
                "下班見",
                "我去接你",
                "改天約",
                "想見你"
            ]
        case .comfort:
            return [
                "辛苦了",
                "我在",
                "先休息",
                "慢慢說",
                "別硬撐",
                "我聽你說",
                "抱一下",
                "不急",
                "你很棒"
            ]
        case .custom:
            return [
                "我換個說法",
                "先不急著回",
                "這句我懂",
                "短一點",
                "我認真回",
                "你說得對",
                "我先道歉",
                "這樣比較好",
                "可愛一點說"
            ]
        }
    }

    private func updateStyleButtons() {
        for button in styleButtons {
            let isSelected = button.tag == selectedStyle.rawValue
            guard let style = ReplyStyle(rawValue: button.tag) else { continue }
            let config = UIImage.SymbolConfiguration(pointSize: isSelected ? 16 : 15, weight: isSelected ? .bold : .semibold)
            button.setImage(UIImage(systemName: style.symbolName, withConfiguration: config), for: .normal)
            button.tintColor = Palette.primary
            button.backgroundColor = style.backgroundColor
            button.alpha = isSelected ? 1 : 0.74
            button.transform = isSelected ? CGAffineTransform(scaleX: 1.06, y: 1.06) : .identity
            button.layer.borderWidth = isSelected ? 1.8 : 1.1
            button.layer.borderColor = (isSelected ? Palette.primary : Palette.primary.withAlphaComponent(0.25)).cgColor
            button.viewWithTag(9001)?.isHidden = !isSelected

            if let label = styleLabels[button.tag] {
                label.text = style.title
                label.textColor = isSelected ? Palette.primary : Palette.secondary
                label.font = .systemFont(ofSize: 8.6, weight: isSelected ? .heavy : .semibold)
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
        button.addTarget(self, action: #selector(readClipboardAndGenerate), for: .touchUpInside)
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
        reload.addTarget(self, action: #selector(readClipboardAndGenerate), for: .touchUpInside)
        row.addArrangedSubview(reload)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            row.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        return card
    }

    private func normalizeMessage(_ text: String) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return lines.joined(separator: " ")
    }

    private func preview(_ text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit)) + "..."
    }

    private func makeReplies(for style: ReplyStyle, message: String) -> [String] {
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return [
                "先複製對方訊息，再點上方「讀取對話」。",
                "讀到對話後，我會給你能直接送出的回覆。",
                "點任一回覆，文字會自動填進輸入框。"
            ]
        }

        let intent = detectIntent(in: text)
        return replies(for: intent, style: style)
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
