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

    private var styleButtons: [UIButton] = []
    private var styleLabels: [Int: UILabel] = [:]
    private var currentReplies: [String] = []
    private var selectedStyle: ReplyStyle = .gentle
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
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 304).isActive = true

        rootStack.axis = .vertical
        rootStack.spacing = 7
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 7),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -8)
        ])

        rootStack.addArrangedSubview(makeHeader())
        rootStack.addArrangedSubview(makeContentArea())
        rootStack.addArrangedSubview(makeStyleSelector())
        rootStack.addArrangedSubview(makeUtilityRow())

        renderContent()
    }

    private func makeHeader() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8

        let title = UILabel()
        title.text = "AI 回覆"
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

    private func makeStyleSelector() -> UIView {
        styleStack.axis = .horizontal
        styleStack.alignment = .center
        styleStack.spacing = 10
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
            button.layer.cornerRadius = 22
            button.widthAnchor.constraint(equalToConstant: 44).isActive = true
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
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
            label.font = .systemFont(ofSize: 9, weight: .semibold)
            label.textColor = Palette.secondary
            label.heightAnchor.constraint(equalToConstant: 10).isActive = true
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
        contentStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 170).isActive = true
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

    @objc private func deleteBackward() {
        textDocumentProxy.deleteBackward()
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

        switch statusMode {
        case .idle:
            statusLabel.text = "等你開始"
            contentStack.addArrangedSubview(actionCard(
                title: "先複製對方訊息",
                subtitle: "再回來點一下，3 秒給你 3 句",
                buttonTitle: "我已複製，產生 3 句",
                toneHint: "讀到對話後套用\(selectedStyle.title)語氣",
                isWarning: false
            ))
        case .emptyClipboard:
            statusLabel.text = "剪貼簿空"
            contentStack.addArrangedSubview(actionCard(
                title: "剪貼簿沒內容",
                subtitle: "回聊天 App 長按訊息複製",
                buttonTitle: "再試一次",
                toneHint: "複製完整一句，AI 比較好接話",
                isWarning: true
            ))
        case .noFullAccess:
            statusLabel.text = "需要權限"
            contentStack.addArrangedSubview(actionCard(
                title: "開完整取用",
                subtitle: "才能讀取你複製的訊息",
                buttonTitle: "我開好了，重試",
                toneHint: "App 只讀剪貼簿文字，不儲存聊天",
                isWarning: true
            ))
        case .ready, .filled:
            statusLabel.text = statusMode == .filled ? "已填入" : "\(selectedStyle.title) · 第\(generationIndex)組"
            contentStack.addArrangedSubview(readPreviewCard())
            currentReplies = makeReplies(for: selectedStyle, message: currentMessage)
            for (index, reply) in currentReplies.enumerated() {
                contentStack.addArrangedSubview(replyButton(reply, index: index))
            }
        }
    }

    private func updateStyleButtons() {
        for button in styleButtons {
            let isSelected = button.tag == selectedStyle.rawValue
            guard let style = ReplyStyle(rawValue: button.tag) else { continue }
            let config = UIImage.SymbolConfiguration(pointSize: isSelected ? 19 : 18, weight: isSelected ? .bold : .semibold)
            button.setImage(UIImage(systemName: style.symbolName, withConfiguration: config), for: .normal)
            button.tintColor = Palette.primary
            button.backgroundColor = style.backgroundColor
            button.alpha = isSelected ? 1 : 0.72
            button.transform = isSelected ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity
            button.layer.borderWidth = isSelected ? 2 : 1.5
            button.layer.borderColor = (isSelected ? Palette.primary : Palette.primary.withAlphaComponent(0.25)).cgColor
            button.viewWithTag(9001)?.isHidden = !isSelected

            if let label = styleLabels[button.tag] {
                label.text = style.title
                label.textColor = isSelected ? Palette.primary : Palette.secondary
                label.font = .systemFont(ofSize: 9, weight: isSelected ? .heavy : .semibold)
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

        let lower = text.lowercased()
        let isQuestion = containsAny(lower, ["?", "？", "嗎", "是不是", "要不要", "可不可以", "怎麼", "哪", "什麼"])
        let isFood = containsAny(lower, ["吃", "喝", "火鍋", "餐廳", "宵夜", "晚餐", "午餐", "咖啡"])
        let isTired = containsAny(lower, ["累", "忙", "煩", "壓力", "不舒服", "睡"])
        let isCold = containsAny(lower, ["嗯", "對", "好", "哈哈", "喔"]) && text.count <= 6
        let isNegative = containsAny(lower, ["算了", "不用", "沒差", "隨便", "生氣", "不爽", "吵", "討厭", "不適合"])

        switch style {
        case .gentle:
            if isFood {
                return [
                    "就吃這個",
                    "我來找時間，今天不用你費心。",
                    "那我們吃完再散步一下，好不好?"
                ]
            }
            if isTired {
                return [
                    "先休息，我在",
                    "今天別硬撐，把力氣留給自己。",
                    "晚點想說話的時候，我陪你慢慢聊好嗎?"
                ]
            }
            if isQuestion {
                return [
                    "我認真想了",
                    "這題我會先照顧你的感受。",
                    "要不要我先說我的想法，再一起決定?"
                ]
            }
            if isCold {
                return [
                    "我懂你的意思",
                    "你不用急著多說，我先陪著。",
                    "等你想聊時再丟給我，我都會接住好嗎?"
                ]
            }
            return [
                "我有放在心上",
                "這句我不會隨便帶過。",
                "要不要慢慢說，我想把你的意思聽完整?"
            ]
        case .funny:
            if isFood {
                return [
                    "胃先答應了",
                    "今天讓晚餐替我們主持公道。",
                    "要不要直接出發，我負責不讓氣氛冷掉?"
                ]
            }
            if isTired {
                return [
                    "先開省電模式",
                    "你今天唯一任務是躺平。",
                    "要不要先休息，我晚點再帶笑話來報到?"
                ]
            }
            if isNegative {
                return [
                    "我先收起嘴砲",
                    "這題不能亂答，我認真一點。",
                    "要不要給我一次補考，我想把話講好?"
                ]
            }
            return [
                "我先接住這題",
                "等我切換高情商模式。",
                "要不要我交一版不尷尬的答案給你?"
            ]
        case .flirty:
            if isFood {
                return [
                    "想坐妳旁邊",
                    "吃什麼都行，重點是跟妳一起。",
                    "要不要我帶妳去那家，妳上次說想吃的?"
                ]
            }
            if isTired {
                return [
                    "靠近一點吧",
                    "今天別撐了，我想接走妳的壞心情。",
                    "要不要休息一下，我晚點再溫柔地吵妳?"
                ]
            }
            if isQuestion {
                return [
                    "如果是妳我願意",
                    "妳這樣問，我會忍不住多想。",
                    "要不要讓我用行動回答，比文字更清楚?"
                ]
            }
            return [
                "有點想妳了",
                "妳一句話就把我的注意力帶走。",
                "要不要晚點聊，我想把今天留一點給妳?"
            ]
        case .apology:
            if isNegative {
                return [
                    "我剛剛沒做好",
                    "先不辯解，我想把你的感受聽完。",
                    "要不要給我一點時間，我會把態度改給你看?"
                ]
            }
            return [
                "是我沒顧好",
                "我想把話說清楚，也顧到你。",
                "要不要讓我重新說一次，這次我會更小心?"
            ]
        }
    }

    private func containsAny(_ text: String, _ needles: [String]) -> Bool {
        for needle in needles where text.contains(needle) {
            return true
        }
        return false
    }

}
