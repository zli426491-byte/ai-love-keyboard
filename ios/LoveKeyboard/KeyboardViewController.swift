import UIKit

final class KeyboardViewController: UIInputViewController {
    private enum ReplyStyle: String, CaseIterable {
        case gentle = "溫柔"
        case funny = "幽默"
        case flirty = "曖昧"
        case apology = "道歉"
    }

    private enum Palette {
        static let background = UIColor(red: 247 / 255, green: 243 / 255, blue: 250 / 255, alpha: 1)
        static let card = UIColor.white
        static let primary = UIColor(red: 94 / 255, green: 54 / 255, blue: 168 / 255, alpha: 1)
        static let accent = UIColor(red: 20 / 255, green: 170 / 255, blue: 148 / 255, alpha: 1)
        static let text = UIColor(red: 35 / 255, green: 30 / 255, blue: 48 / 255, alpha: 1)
        static let secondary = UIColor(red: 112 / 255, green: 103 / 255, blue: 125 / 255, alpha: 1)
        static let border = UIColor(red: 222 / 255, green: 213 / 255, blue: 234 / 255, alpha: 1)
        static let key = UIColor(red: 253 / 255, green: 252 / 255, blue: 255 / 255, alpha: 1)
    }

    private let rootStack = UIStackView()
    private let statusLabel = UILabel()
    private let replyScrollView = UIScrollView()
    private let replyStack = UIStackView()
    private let styleStack = UIStackView()
    private let keyboardStack = UIStackView()
    private let nextKeyboardButton = UIButton(type: .system)
    private let pasteButton = UIButton(type: .system)
    private let generateButton = UIButton(type: .system)

    private var styleButtons: [UIButton] = []
    private var selectedStyle: ReplyStyle = .gentle
    private var pastedMessage = ""
    private var isUppercase = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
        renderReplies()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        refreshStatus()
    }

    private func setupKeyboard() {
        view.backgroundColor = Palette.background
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 340).isActive = true

        rootStack.axis = .vertical
        rootStack.spacing = 7
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -8),
        ])

        rootStack.addArrangedSubview(headerView())
        rootStack.addArrangedSubview(styleSelector())
        rootStack.addArrangedSubview(actionRow())
        rootStack.addArrangedSubview(replyList())

        keyboardStack.axis = .vertical
        keyboardStack.spacing = 6
        rootStack.addArrangedSubview(keyboardStack)
        renderTypingKeys()

        refreshStatus()
    }

    private func headerView() -> UIView {
        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center

        let title = UILabel()
        title.text = "AI 戀愛鍵盤"
        title.font = .systemFont(ofSize: 14, weight: .bold)
        title.textColor = Palette.primary
        header.addArrangedSubview(title)

        statusLabel.font = .systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = Palette.secondary
        statusLabel.numberOfLines = 1
        statusLabel.textAlignment = .center
        header.addArrangedSubview(statusLabel)

        nextKeyboardButton.setTitle("🌐", for: .normal)
        nextKeyboardButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        nextKeyboardButton.addTarget(self, action: #selector(handleNextKeyboard), for: .touchUpInside)
        nextKeyboardButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        header.addArrangedSubview(nextKeyboardButton)

        return header
    }

    private func styleSelector() -> UIView {
        styleStack.axis = .horizontal
        styleStack.spacing = 6
        styleStack.distribution = .fillEqually

        for style in ReplyStyle.allCases {
            let button = UIButton(type: .system)
            button.setTitle(style.rawValue, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
            button.layer.cornerRadius = 13
            button.heightAnchor.constraint(equalToConstant: 30).isActive = true
            button.tag = styleButtons.count
            button.addTarget(self, action: #selector(styleTapped(_:)), for: .touchUpInside)
            styleButtons.append(button)
            styleStack.addArrangedSubview(button)
        }

        updateStyleButtons()
        return styleStack
    }

    private func actionRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 7
        row.distribution = .fillEqually

        pasteButton.setTitle("貼上訊息", for: .normal)
        styleSecondaryButton(pasteButton)
        pasteButton.addTarget(self, action: #selector(pasteFromClipboard), for: .touchUpInside)
        row.addArrangedSubview(pasteButton)

        generateButton.setTitle("更新回覆", for: .normal)
        generateButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.backgroundColor = Palette.accent
        generateButton.layer.cornerRadius = 13
        generateButton.heightAnchor.constraint(equalToConstant: 38).isActive = true
        generateButton.addTarget(self, action: #selector(renderReplies), for: .touchUpInside)
        row.addArrangedSubview(generateButton)

        return row
    }

    private func replyList() -> UIView {
        replyScrollView.showsHorizontalScrollIndicator = false
        replyScrollView.heightAnchor.constraint(equalToConstant: 58).isActive = true

        replyStack.axis = .horizontal
        replyStack.spacing = 8
        replyStack.translatesAutoresizingMaskIntoConstraints = false
        replyScrollView.addSubview(replyStack)

        NSLayoutConstraint.activate([
            replyStack.leadingAnchor.constraint(equalTo: replyScrollView.leadingAnchor),
            replyStack.trailingAnchor.constraint(equalTo: replyScrollView.trailingAnchor),
            replyStack.topAnchor.constraint(equalTo: replyScrollView.topAnchor),
            replyStack.bottomAnchor.constraint(equalTo: replyScrollView.bottomAnchor),
            replyStack.heightAnchor.constraint(equalTo: replyScrollView.heightAnchor),
        ])

        return replyScrollView
    }

    private func renderTypingKeys() {
        keyboardStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let rows = [
            Array("qwertyuiop").map(String.init),
            Array("asdfghjkl").map(String.init),
            Array("zxcvbnm").map(String.init),
        ]

        keyboardStack.addArrangedSubview(keyRow(rows[0]))
        keyboardStack.addArrangedSubview(keyRow(rows[1], horizontalInset: 18))

        let third = UIStackView()
        third.axis = .horizontal
        third.spacing = 5
        third.distribution = .fill
        third.addArrangedSubview(commandKey(isUppercase ? "ABC" : "abc", width: 48, action: #selector(toggleCase)))
        for key in rows[2] {
            third.addArrangedSubview(letterKey(key))
        }
        third.addArrangedSubview(commandKey("⌫", width: 48, action: #selector(deleteBackward)))
        keyboardStack.addArrangedSubview(third)

        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 6
        bottom.distribution = .fill
        bottom.addArrangedSubview(commandKey("123", width: 52, action: #selector(insertQuestionMark)))
        bottom.addArrangedSubview(commandKey("空白", width: 0, action: #selector(insertSpace)))
        bottom.addArrangedSubview(commandKey("換行", width: 62, action: #selector(insertReturn)))
        keyboardStack.addArrangedSubview(bottom)
    }

    private func keyRow(_ keys: [String], horizontalInset: CGFloat = 0) -> UIView {
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
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: horizontalInset),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -horizontalInset),
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 38),
        ])
        return container
    }

    private func letterKey(_ value: String) -> UIButton {
        let button = UIButton(type: .system)
        let display = isUppercase ? value.uppercased() : value
        button.setTitle(display, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(Palette.text, for: .normal)
        button.backgroundColor = Palette.key
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 0.5
        button.layer.borderColor = Palette.border.cgColor
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        button.addAction(UIAction { [weak self] _ in
            self?.textDocumentProxy.insertText(display)
        }, for: .touchUpInside)
        return button
    }

    private func commandKey(_ title: String, width: CGFloat, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
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

    private func styleSecondaryButton(_ button: UIButton) {
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.setTitleColor(Palette.primary, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 13
        button.layer.borderWidth = 1
        button.layer.borderColor = Palette.border.cgColor
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
    }

    private func updateStyleButtons() {
        for (index, button) in styleButtons.enumerated() {
            let isSelected = ReplyStyle.allCases[index] == selectedStyle
            button.backgroundColor = isSelected ? Palette.primary : .white
            button.setTitleColor(isSelected ? .white : Palette.primary, for: .normal)
            button.layer.borderColor = Palette.border.cgColor
            button.layer.borderWidth = isSelected ? 0 : 1
        }
    }

    @objc private func styleTapped(_ sender: UIButton) {
        selectedStyle = ReplyStyle.allCases[sender.tag]
        updateStyleButtons()
        renderReplies()
    }

    @objc private func renderReplies() {
        replyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for reply in replies(for: sourceMessage(), style: selectedStyle) {
            replyStack.addArrangedSubview(replyButton(reply))
        }
        refreshStatus()
    }

    private func replyButton(_ text: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.titleLabel?.numberOfLines = 2
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.setTitleColor(Palette.text, for: .normal)
        button.backgroundColor = Palette.card
        button.layer.cornerRadius = 13
        button.layer.borderWidth = 1
        button.layer.borderColor = Palette.border.cgColor
        button.widthAnchor.constraint(equalToConstant: 220).isActive = true
        button.addAction(UIAction { [weak self] _ in
            self?.textDocumentProxy.insertText(text)
            self?.statusLabel.text = "已插入回覆"
        }, for: .touchUpInside)
        return button
    }

    @objc private func pasteFromClipboard() {
        guard hasFullAccess else {
            statusLabel.text = "請先開啟完整取用才能貼上"
            return
        }

        guard let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty
        else {
            statusLabel.text = "剪貼簿沒有文字"
            return
        }

        pastedMessage = String(text.prefix(240))
        statusLabel.text = "已讀取剪貼簿"
        renderReplies()
    }

    private func sourceMessage() -> String {
        if !pastedMessage.isEmpty {
            return pastedMessage
        }
        return (textDocumentProxy.documentContextBeforeInput ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func refreshStatus() {
        let source = sourceMessage()
        if source.isEmpty {
            statusLabel.text = hasFullAccess ? "可打字，也可貼上訊息" : "可打字；貼上需完整取用"
        } else {
            statusLabel.text = "參考：" + String(source.prefix(18))
        }
    }

    private func replies(for message: String, style: ReplyStyle) -> [String] {
        let hasMessage = !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch style {
        case .gentle:
            return hasMessage
                ? ["我懂，你先不用急著回我。", "辛苦了，晚點我陪你聊。", "先照顧好自己，我在。"]
                : ["你先好好休息。", "我懂，想聊時我都在。", "慢慢來，不急。"]
        case .funny:
            return ["收到，我先把吵鬧模式關掉。", "那我先安靜，但你不能忘記我。", "懂了，今天少鬧你一點。"]
        case .flirty:
            return ["那你先休息，記得回來找我。", "好，我乖乖等你回覆。", "休息好再回我，我會想你。"]
        case .apology:
            return ["剛剛讓你有壓力的話，抱歉。", "我不是想逼你，只是有點在意。", "我會放慢一點，給你空間。"]
        }
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
        textDocumentProxy.insertText("?")
    }

    @objc private func handleNextKeyboard() {
        advanceToNextInputMode()
    }
}
