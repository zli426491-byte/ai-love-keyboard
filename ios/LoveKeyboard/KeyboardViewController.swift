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
    }

    private enum Palette {
        static let background = UIColor(red: 248 / 255, green: 245 / 255, blue: 251 / 255, alpha: 1)
        static let card = UIColor.white
        static let primary = UIColor(red: 88 / 255, green: 58 / 255, blue: 168 / 255, alpha: 1)
        static let accent = UIColor(red: 24 / 255, green: 168 / 255, blue: 145 / 255, alpha: 1)
        static let text = UIColor(red: 34 / 255, green: 30 / 255, blue: 44 / 255, alpha: 1)
        static let secondary = UIColor(red: 105 / 255, green: 98 / 255, blue: 116 / 255, alpha: 1)
        static let border = UIColor(red: 224 / 255, green: 216 / 255, blue: 235 / 255, alpha: 1)
        static let key = UIColor(red: 238 / 255, green: 233 / 255, blue: 244 / 255, alpha: 1)
    }

    private let rootStack = UIStackView()
    private let contextLabel = UILabel()
    private let statusLabel = UILabel()
    private let styleStack = UIStackView()
    private let replyStack = UIStackView()

    private var styleButtons: [UIButton] = []
    private var currentReplies: [String] = []
    private var selectedStyle: ReplyStyle = .gentle
    private var currentMessage = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        renderReplies()
    }

    private func setupView() {
        view.backgroundColor = Palette.background
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 306).isActive = true

        rootStack.axis = .vertical
        rootStack.spacing = 8
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -8)
        ])

        rootStack.addArrangedSubview(makeHeader())
        rootStack.addArrangedSubview(makeContextCard())
        rootStack.addArrangedSubview(makeReadButton())
        rootStack.addArrangedSubview(makeStyleSelector())
        rootStack.addArrangedSubview(makeReplyList())
        rootStack.addArrangedSubview(makeUtilityRow())

        statusLabel.text = "先複製對方訊息，再按讀取剪貼簿"
    }

    private func makeHeader() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8

        let title = UILabel()
        title.text = "AI 回覆"
        title.font = .systemFont(ofSize: 15, weight: .bold)
        title.textColor = Palette.primary
        row.addArrangedSubview(title)

        statusLabel.font = .systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = Palette.secondary
        statusLabel.textAlignment = .right
        statusLabel.numberOfLines = 1
        row.addArrangedSubview(statusLabel)

        return row
    }

    private func makeContextCard() -> UIView {
        let card = UIView()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.border.cgColor
        card.heightAnchor.constraint(equalToConstant: 42).isActive = true

        contextLabel.text = "尚未讀取對話"
        contextLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        contextLabel.textColor = Palette.text
        contextLabel.numberOfLines = 1
        contextLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contextLabel)

        NSLayoutConstraint.activate([
            contextLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            contextLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            contextLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        return card
    }

    private func makeReadButton() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually

        let readButton = UIButton(type: .system)
        readButton.setTitle("讀取剪貼簿並生成", for: .normal)
        readButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        readButton.setTitleColor(.white, for: .normal)
        readButton.backgroundColor = Palette.accent
        readButton.layer.cornerRadius = 14
        readButton.heightAnchor.constraint(equalToConstant: 42).isActive = true
        readButton.addTarget(self, action: #selector(readClipboardAndGenerate), for: .touchUpInside)
        row.addArrangedSubview(readButton)

        return row
    }

    private func makeStyleSelector() -> UIView {
        styleStack.axis = .horizontal
        styleStack.spacing = 6
        styleStack.distribution = .fillEqually

        for style in ReplyStyle.allCases {
            let button = UIButton(type: .system)
            button.setTitle(style.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
            button.layer.cornerRadius = 13
            button.heightAnchor.constraint(equalToConstant: 30).isActive = true
            button.tag = style.rawValue
            button.addTarget(self, action: #selector(styleTapped(_:)), for: .touchUpInside)
            styleButtons.append(button)
            styleStack.addArrangedSubview(button)
        }

        updateStyleButtons()
        return styleStack
    }

    private func makeReplyList() -> UIView {
        replyStack.axis = .vertical
        replyStack.spacing = 7
        replyStack.distribution = .fillEqually
        replyStack.heightAnchor.constraint(equalToConstant: 142).isActive = true
        return replyStack
    }

    private func makeUtilityRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
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
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        button.setTitleColor(Palette.text, for: .normal)
        button.backgroundColor = Palette.key
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func replyButton(_ title: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.titleLabel?.numberOfLines = 2
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.setTitleColor(Palette.text, for: .normal)
        button.backgroundColor = Palette.card
        button.layer.cornerRadius = 13
        button.layer.borderWidth = 1
        button.layer.borderColor = Palette.border.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.06
        button.layer.shadowRadius = 4
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.tag = index
        button.addTarget(self, action: #selector(replyTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func readClipboardAndGenerate() {
        let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else {
            currentMessage = ""
            contextLabel.text = "剪貼簿沒有文字"
            statusLabel.text = "請先複製對方訊息"
            renderReplies()
            return
        }

        currentMessage = normalizeMessage(text)
        contextLabel.text = "已讀：" + preview(currentMessage, limit: 20)
        statusLabel.text = "已重新生成"
        renderReplies()
    }

    @objc private func styleTapped(_ sender: UIButton) {
        guard let style = ReplyStyle(rawValue: sender.tag) else { return }
        selectedStyle = style
        updateStyleButtons()
        statusLabel.text = "已切換 \(style.title)"
        renderReplies()
    }

    @objc private func replyTapped(_ sender: UIButton) {
        guard sender.tag >= 0 && sender.tag < currentReplies.count else { return }
        textDocumentProxy.insertText(currentReplies[sender.tag])
        statusLabel.text = "已填入，確認後送出"
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

    private func renderReplies() {
        for view in replyStack.arrangedSubviews {
            replyStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        currentReplies = makeReplies(for: selectedStyle, message: currentMessage)
        for (index, reply) in currentReplies.enumerated() {
            replyStack.addArrangedSubview(replyButton(reply, index: index))
        }
    }

    private func updateStyleButtons() {
        for button in styleButtons {
            let isSelected = button.tag == selectedStyle.rawValue
            button.backgroundColor = isSelected ? Palette.primary : Palette.card
            button.setTitleColor(isSelected ? .white : Palette.primary, for: .normal)
            button.layer.borderWidth = isSelected ? 0 : 1
            button.layer.borderColor = Palette.border.cgColor
        }
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
                "你可以先把對方訊息複製起來，我幫你接話。",
                "讀到對話後，我會直接給你能送出的回覆。",
                "點這裡會把回覆填進輸入框。"
            ]
        }

        let lower = text.lowercased()
        let topic = shortTopic(from: text)
        let isQuestion = containsAny(lower, ["?", "？", "嗎", "是不是", "要不要", "可不可以", "怎麼", "哪", "什麼"])
        let isFood = containsAny(lower, ["吃", "喝", "火鍋", "餐廳", "宵夜", "晚餐", "午餐", "咖啡"])
        let isTired = containsAny(lower, ["累", "忙", "煩", "壓力", "不舒服", "睡"])
        let isCold = containsAny(lower, ["嗯", "對", "好", "哈哈", "喔"]) && text.count <= 6
        let isNegative = containsAny(lower, ["算了", "不用", "沒差", "隨便", "生氣", "不爽", "吵", "討厭"])

        switch style {
        case .gentle:
            if isFood {
                return [
                    "好啊，\(topic)可以，我來看哪個時間最剛好。",
                    "可以，等等就去，今天不用想太多。",
                    "那就\(topic)，我陪你慢慢吃、慢慢聊。"
                ]
            }
            if isTired {
                return [
                    "辛苦了，先別硬撐，我陪你慢慢放鬆。",
                    "我知道你今天很累，先把自己照顧好。",
                    "沒事，你想休息就先休息，我在。"
                ]
            }
            if isQuestion {
                return [
                    "我想了一下，這件事我會比較偏向先照顧你的感受。",
                    "可以，我認真回你：我覺得先這樣安排會比較好。",
                    "你問得很對，我先說我的想法給你聽。"
                ]
            }
            if isCold {
                return [
                    "好，那我懂你的意思了。",
                    "嗯嗯，我有收到，你不用急著多說。",
                    "可以，那我先照你的節奏來。"
                ]
            }
            return [
                "我懂你說的「\(topic)」，我會好好回你。",
                "這句我有放在心上，不會隨便帶過。",
                "我想先理解你的意思，再好好接話。"
            ]
        case .funny:
            if isFood {
                return [
                    "\(topic)可以，我的胃已經先答應了。",
                    "走啊，今天就讓火鍋替我們主持公道。",
                    "可以，我負責吃肉，你負責開心。"
                ]
            }
            if isTired {
                return [
                    "辛苦了，今天先把腦袋切成省電模式。",
                    "那你現在唯一任務：躺平，不准逞強。",
                    "我批准你今天不用堅強，休息最大。"
                ]
            }
            if isNegative {
                return [
                    "收到，我先把求生欲開到最大。",
                    "這句我聽懂了，我先不亂皮。",
                    "我感覺這題不能亂答，我認真一點。"
                ]
            }
            return [
                "你這句「\(topic)」我先接住，不然我怕掉分。",
                "等我一下，我正在切換高情商模式。",
                "這題我會，我先交一版不尷尬的答案。"
            ]
        case .flirty:
            if isFood {
                return [
                    "好，等等去\(topic)，但我要坐你旁邊。",
                    "可以，吃什麼都行，重點是跟你一起。",
                    "那就走吧，我想把今天的時間留給你。"
                ]
            }
            if isTired {
                return [
                    "累的話靠近一點，我負責哄你。",
                    "今天先別撐了，我想把你的壞心情接走。",
                    "你休息，我想你這件事我來負責。"
                ]
            }
            if isQuestion {
                return [
                    "如果是你的話，我其實很願意。",
                    "你這樣問，我會忍不住想多想一點。",
                    "可以啊，只要是跟你，我都想試試看。"
                ]
            }
            return [
                "你說「\(topic)」的時候，我有點想你。",
                "我可以慢慢回，但想靠近你這件事很快。",
                "你一句話，就把我的注意力帶走了。"
            ]
        case .apology:
            if isNegative {
                return [
                    "我知道你不舒服，剛剛是我沒處理好。",
                    "對不起，我先不辯解，我想把你感受聽完。",
                    "我會改，不是說說而已。"
                ]
            }
            return [
                "如果我剛剛讓你不舒服，真的抱歉。",
                "我想把話說清楚，也想好好顧到你的感受。",
                "對不起，我會更注意自己的表達。"
            ]
        }
    }

    private func containsAny(_ text: String, _ needles: [String]) -> Bool {
        for needle in needles where text.contains(needle) {
            return true
        }
        return false
    }

    private func shortTopic(from text: String) -> String {
        var cleaned = text
        let replacements = ["你", "我", "們", "啊", "啦", "欸", "耶", "嗎", "？", "?", "，", ",", "。", ".", "！", "!"]
        for item in replacements {
            cleaned = cleaned.replacingOccurrences(of: item, with: "")
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return preview(cleaned, limit: 8)
    }
}
