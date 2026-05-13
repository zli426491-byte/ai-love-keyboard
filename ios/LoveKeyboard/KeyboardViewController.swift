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
        static let background = UIColor(red: 247 / 255, green: 243 / 255, blue: 250 / 255, alpha: 1)
        static let card = UIColor.white
        static let primary = UIColor(red: 88 / 255, green: 58 / 255, blue: 168 / 255, alpha: 1)
        static let accent = UIColor(red: 24 / 255, green: 168 / 255, blue: 145 / 255, alpha: 1)
        static let text = UIColor(red: 34 / 255, green: 30 / 255, blue: 44 / 255, alpha: 1)
        static let secondary = UIColor(red: 108 / 255, green: 101 / 255, blue: 119 / 255, alpha: 1)
        static let border = UIColor(red: 222 / 255, green: 213 / 255, blue: 234 / 255, alpha: 1)
        static let key = UIColor(red: 253 / 255, green: 252 / 255, blue: 255 / 255, alpha: 1)
    }

    private let rootStack = UIStackView()
    private let statusLabel = UILabel()
    private let replyScrollView = UIScrollView()
    private let replyStack = UIStackView()
    private let styleStack = UIStackView()
    private let quickTextStack = UIStackView()
    private let keyboardStack = UIStackView()
    private let nextKeyboardButton = UIButton(type: .system)
    private let pasteButton = UIButton(type: .system)
    private let refreshButton = UIButton(type: .system)

    private var styleButtons: [UIButton] = []
    private var currentReplies: [String] = []
    private var selectedStyle: ReplyStyle = .gentle
    private var pastedMessage = ""
    private var isUppercase = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        renderReplies()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        if pastedMessage.isEmpty {
            refreshStatus("可用輸入框文字生成，點回覆直接填入")
        }
    }

    private func setupView() {
        view.backgroundColor = Palette.background
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 348).isActive = true

        rootStack.axis = .vertical
        rootStack.spacing = 7
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -8)
        ])

        rootStack.addArrangedSubview(makeHeader())
        rootStack.addArrangedSubview(makeStyleSelector())
        rootStack.addArrangedSubview(makeActionRow())
        rootStack.addArrangedSubview(makeReplyList())
        rootStack.addArrangedSubview(makeQuickTextRow())

        keyboardStack.axis = .vertical
        keyboardStack.spacing = 6
        rootStack.addArrangedSubview(keyboardStack)
        renderTypingKeys()
        refreshStatus("複製對話後點貼上，點回覆會直接填入")
    }

    private func makeHeader() -> UIView {
        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8

        let titleLabel = UILabel()
        titleLabel.text = "AI 戀愛鍵盤"
        titleLabel.font = .systemFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = Palette.primary
        header.addArrangedSubview(titleLabel)

        statusLabel.font = .systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = Palette.secondary
        statusLabel.numberOfLines = 1
        statusLabel.textAlignment = .center
        header.addArrangedSubview(statusLabel)

        nextKeyboardButton.setTitle("切換", for: .normal)
        nextKeyboardButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nextKeyboardButton.setTitleColor(Palette.primary, for: .normal)
        nextKeyboardButton.addTarget(self, action: #selector(handleNextKeyboard), for: .touchUpInside)
        nextKeyboardButton.widthAnchor.constraint(equalToConstant: 46).isActive = true
        header.addArrangedSubview(nextKeyboardButton)

        return header
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

    private func makeActionRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 7
        row.distribution = .fillEqually

        pasteButton.setTitle("貼上並生成", for: .normal)
        styleSecondaryButton(pasteButton)
        pasteButton.addTarget(self, action: #selector(pasteFromClipboard), for: .touchUpInside)
        row.addArrangedSubview(pasteButton)

        refreshButton.setTitle("用輸入框生成", for: .normal)
        refreshButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        refreshButton.setTitleColor(.white, for: .normal)
        refreshButton.backgroundColor = Palette.accent
        refreshButton.layer.cornerRadius = 13
        refreshButton.heightAnchor.constraint(equalToConstant: 38).isActive = true
        refreshButton.addTarget(self, action: #selector(refreshRepliesTapped), for: .touchUpInside)
        row.addArrangedSubview(refreshButton)

        return row
    }

    private func makeReplyList() -> UIView {
        let container = UIView()
        container.heightAnchor.constraint(equalToConstant: 106).isActive = true

        replyStack.axis = .vertical
        replyStack.spacing = 7
        replyStack.distribution = .fillEqually
        replyStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(replyStack)

        NSLayoutConstraint.activate([
            replyStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            replyStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            replyStack.topAnchor.constraint(equalTo: container.topAnchor),
            replyStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func makeQuickTextRow() -> UIView {
        quickTextStack.axis = .horizontal
        quickTextStack.spacing = 6
        quickTextStack.distribution = .fillEqually

        let words = ["好呀", "哈哈", "可以", "等等", "沒事", "晚點回"]
        for (index, word) in words.enumerated() {
            let button = quickTextButton(word)
            button.tag = index
            quickTextStack.addArrangedSubview(button)
        }

        return quickTextStack
    }

    private func renderTypingKeys() {
        for view in keyboardStack.arrangedSubviews {
            keyboardStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        keyboardStack.addArrangedSubview(makeKeyRow(["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]))
        keyboardStack.addArrangedSubview(makeKeyRow(["a", "s", "d", "f", "g", "h", "j", "k", "l"], inset: 18))

        let thirdRow = UIStackView()
        thirdRow.axis = .horizontal
        thirdRow.spacing = 5
        thirdRow.distribution = .fill
        thirdRow.addArrangedSubview(commandKey(isUppercase ? "ABC" : "abc", width: 48, action: #selector(toggleCase)))

        let thirdKeys = ["z", "x", "c", "v", "b", "n", "m"]
        for key in thirdKeys {
            thirdRow.addArrangedSubview(letterKey(key))
        }

        thirdRow.addArrangedSubview(commandKey("刪除", width: 54, action: #selector(deleteBackward)))
        keyboardStack.addArrangedSubview(thirdRow)

        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.spacing = 6
        bottomRow.distribution = .fill
        bottomRow.addArrangedSubview(commandKey("？", width: 48, action: #selector(insertQuestionMark)))
        bottomRow.addArrangedSubview(commandKey("空白", width: 0, action: #selector(insertSpace)))
        bottomRow.addArrangedSubview(commandKey("換行", width: 58, action: #selector(insertReturn)))
        keyboardStack.addArrangedSubview(bottomRow)
    }

    private func makeKeyRow(_ keys: [String], inset: CGFloat = 0) -> UIView {
        let container = UIView()
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 5
        row.distribution = .fillEqually
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)

        for key in keys {
            row.addArrangedSubview(letterKey(key))
        }

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 38)
        ])

        return container
    }

    private func letterKey(_ value: String) -> UIButton {
        let button = UIButton(type: .system)
        let title = isUppercase ? value.uppercased() : value
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(Palette.text, for: .normal)
        button.backgroundColor = Palette.key
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 0.5
        button.layer.borderColor = Palette.border.cgColor
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        button.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
        return button
    }

    private func commandKey(_ title: String, width: CGFloat, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        button.setTitleColor(Palette.text, for: .normal)
        button.backgroundColor = UIColor(red: 232 / 255, green: 226 / 255, blue: 238 / 255, alpha: 1)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        if width > 0 {
            button.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func quickTextButton(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        button.setTitleColor(Palette.primary, for: .normal)
        button.backgroundColor = Palette.card
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 0.5
        button.layer.borderColor = Palette.border.cgColor
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.addTarget(self, action: #selector(quickTextTapped(_:)), for: .touchUpInside)
        return button
    }

    private func replyButton(_ title: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("填入  " + title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.titleLabel?.numberOfLines = 2
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
        button.setTitleColor(Palette.text, for: .normal)
        button.backgroundColor = Palette.card
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = Palette.border.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowRadius = 6
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.tag = index
        button.addTarget(self, action: #selector(replyTapped(_:)), for: .touchUpInside)
        return button
    }

    private func styleSecondaryButton(_ button: UIButton) {
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.setTitleColor(Palette.primary, for: .normal)
        button.backgroundColor = Palette.card
        button.layer.cornerRadius = 13
        button.layer.borderWidth = 1
        button.layer.borderColor = Palette.border.cgColor
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
    }

    @objc private func renderReplies() {
        for view in replyStack.arrangedSubviews {
            replyStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        currentReplies = makeReplies(for: selectedStyle, message: sourceMessage())
        var index = 0
        while index < currentReplies.count {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 7
            row.distribution = .fillEqually

            for _ in 0..<2 {
                if index < currentReplies.count {
                    row.addArrangedSubview(replyButton(currentReplies[index], index: index))
                    index += 1
                } else {
                    let spacer = UIView()
                    row.addArrangedSubview(spacer)
                }
            }

            replyStack.addArrangedSubview(row)
        }
    }

    @objc private func refreshRepliesTapped() {
        let inputText = textDocumentProxy.documentContextBeforeInput?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !inputText.isEmpty {
            pastedMessage = inputText
        }
        renderReplies()
        refreshStatus(sourceMessage().isEmpty ? "沒有讀到文字，請先複製對話或在輸入框貼上" : "已生成候選，點回覆直接填入")
    }

    @objc private func styleTapped(_ sender: UIButton) {
        guard let style = ReplyStyle(rawValue: sender.tag) else { return }
        selectedStyle = style
        updateStyleButtons()
        renderReplies()
        refreshStatus("已切換成\(style.title)語氣")
    }

    @objc private func pasteFromClipboard() {
        let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.isEmpty {
            pastedMessage = ""
            renderReplies()
            refreshStatus("沒有讀到剪貼簿，請確認允許完整取用")
            return
        }

        pastedMessage = text
        renderReplies()
        let preview = text.count > 12 ? String(text.prefix(12)) + "..." : text
        refreshStatus("已讀取：\(preview)，點回覆直接填入")
    }

    @objc private func replyTapped(_ sender: UIButton) {
        guard sender.tag >= 0 && sender.tag < currentReplies.count else { return }
        textDocumentProxy.insertText(currentReplies[sender.tag])
        refreshStatus("已填入輸入框，確認後按送出")
    }

    @objc private func quickTextTapped(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(text)
    }

    @objc private func letterTapped(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(text)
    }

    @objc private func toggleCase() {
        isUppercase.toggle()
        renderTypingKeys()
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

    @objc private func insertQuestionMark() {
        textDocumentProxy.insertText("？")
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

    private func refreshStatus(_ text: String) {
        statusLabel.text = text
    }

    @objc private func handleNextKeyboard() {
        advanceToNextInputMode()
    }

    private func sourceMessage() -> String {
        if !pastedMessage.isEmpty {
            return pastedMessage
        }
        return textDocumentProxy.documentContextBeforeInput?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func makeReplies(for style: ReplyStyle, message: String) -> [String] {
        let normalized = message.lowercased()
        let tired = normalized.contains("累") || normalized.contains("tired")
        let casual = normalized.contains("隨便") || normalized.contains("都可以")
        let angry = normalized.contains("算了") || normalized.contains("不用") || normalized.contains("生氣")

        switch style {
        case .gentle:
            if tired {
                return ["辛苦了，先好好休息，我晚點陪你聊。", "今天一定很累吧，先把自己照顧好。", "我在，你想說的時候我都會聽。"]
            }
            if casual {
                return ["那我來安排，你只要負責開心就好。", "交給我，我選一個你會舒服的。", "好，我決定，但會以你喜歡為主。"]
            }
            return ["我懂你的意思，我會好好回你。", "你這樣說我有放在心上。", "我想先聽聽你真正的想法。"]
        case .funny:
            if tired {
                return ["辛苦了，今天先下班，腦袋也一起打卡。", "那你現在的任務只有一個：躺平。", "我批准你今天不用堅強。"]
            }
            if casual {
                return ["隨便是最難的題目，但我準備好了。", "收到，我來當選擇困難終結者。", "那我選一個不會被扣分的答案。"]
            }
            return ["我剛剛認真想了一下，差點把 CPU 燒了。", "這題我會，我先交一版答案。", "等我三秒，我切換高情商模式。"]
        case .flirty:
            if tired {
                return ["那今晚別硬撐，我想把你的壞心情接走。", "累的話靠過來一點，我負責哄你。", "今天先休息，明天換我讓你開心。"]
            }
            if casual {
                return ["那我決定見你，其他都不重要。", "我選你喜歡的，也選跟你一起。", "好，我安排一個適合我們的。"]
            }
            return ["你這樣說，我會忍不住一直想你。", "我可以慢慢回，但想你這件事很快。", "你一句話，我心情就被你帶走了。"]
        case .apology:
            if angry {
                return ["我知道你不舒服，剛剛是我沒處理好。", "對不起，我先不辯解，我想把你感受聽完。", "我會改，不是說說而已。"]
            }
            return ["如果我剛剛讓你不舒服，真的抱歉。", "我想把話說清楚，也想好好顧到你的感受。", "對不起，我會更注意自己的表達。"]
        }
    }
}
