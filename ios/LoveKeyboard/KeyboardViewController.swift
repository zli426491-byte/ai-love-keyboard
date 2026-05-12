import UIKit

final class KeyboardViewController: UIInputViewController {
    private enum Style: String, CaseIterable {
        case gentle = "溫柔"
        case funny = "幽默"
        case flirty = "曖昧"
        case apology = "道歉"
    }

    private enum Palette {
        static let background = UIColor(red: 250 / 255, green: 247 / 255, blue: 255 / 255, alpha: 1)
        static let card = UIColor.white
        static let primary = UIColor(red: 126 / 255, green: 87 / 255, blue: 255 / 255, alpha: 1)
        static let accent = UIColor(red: 22 / 255, green: 178 / 255, blue: 160 / 255, alpha: 1)
        static let text = UIColor(red: 35 / 255, green: 30 / 255, blue: 48 / 255, alpha: 1)
        static let secondary = UIColor(red: 112 / 255, green: 103 / 255, blue: 125 / 255, alpha: 1)
        static let border = UIColor(red: 226 / 255, green: 216 / 255, blue: 238 / 255, alpha: 1)
    }

    private let rootStack = UIStackView()
    private let inputField = UITextField()
    private let replyStack = UIStackView()
    private let generateButton = UIButton(type: .system)
    private let nextKeyboardButton = UIButton(type: .system)
    private var styleButtons: [UIButton] = []
    private var selectedStyle: Style = .gentle
    private var currentReplies: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
        generateReplies()
    }

    private func setupKeyboard() {
        view.backgroundColor = Palette.background
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 292).isActive = true

        rootStack.axis = .vertical
        rootStack.spacing = 8
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -8),
        ])

        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center

        let titleLabel = UILabel()
        titleLabel.text = "AI 戀愛鍵盤"
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = Palette.primary
        header.addArrangedSubview(titleLabel)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        header.addArrangedSubview(spacer)

        nextKeyboardButton.setTitle("切換鍵盤", for: .normal)
        nextKeyboardButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        nextKeyboardButton.setTitleColor(Palette.secondary, for: .normal)
        nextKeyboardButton.addTarget(self, action: #selector(handleNextKeyboard), for: .touchUpInside)
        header.addArrangedSubview(nextKeyboardButton)
        rootStack.addArrangedSubview(header)

        inputField.placeholder = "貼上對方訊息，產生回覆"
        inputField.font = .systemFont(ofSize: 14)
        inputField.textColor = Palette.text
        inputField.backgroundColor = Palette.card
        inputField.layer.cornerRadius = 12
        inputField.layer.borderWidth = 1
        inputField.layer.borderColor = Palette.border.cgColor
        inputField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        inputField.leftViewMode = .always
        inputField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        inputField.rightViewMode = .always
        inputField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        rootStack.addArrangedSubview(inputField)

        let styleStack = UIStackView()
        styleStack.axis = .horizontal
        styleStack.spacing = 8
        styleStack.distribution = .fillEqually
        for style in Style.allCases {
            let button = UIButton(type: .system)
            button.setTitle(style.rawValue, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
            button.layer.cornerRadius = 15
            button.heightAnchor.constraint(equalToConstant: 32).isActive = true
            button.tag = styleButtons.count
            button.addTarget(self, action: #selector(styleTapped(_:)), for: .touchUpInside)
            styleButtons.append(button)
            styleStack.addArrangedSubview(button)
        }
        rootStack.addArrangedSubview(styleStack)
        updateStyleButtons()

        generateButton.setTitle("產生回覆", for: .normal)
        generateButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.backgroundColor = Palette.accent
        generateButton.layer.cornerRadius = 13
        generateButton.heightAnchor.constraint(equalToConstant: 42).isActive = true
        generateButton.addTarget(self, action: #selector(generateReplies), for: .touchUpInside)
        rootStack.addArrangedSubview(generateButton)

        replyStack.axis = .vertical
        replyStack.spacing = 7
        rootStack.addArrangedSubview(replyStack)
    }

    @objc private func styleTapped(_ sender: UIButton) {
        selectedStyle = Style.allCases[sender.tag]
        updateStyleButtons()
        generateReplies()
    }

    private func updateStyleButtons() {
        for (index, button) in styleButtons.enumerated() {
            let isSelected = Style.allCases[index] == selectedStyle
            button.backgroundColor = isSelected ? Palette.primary : UIColor.white
            button.setTitleColor(isSelected ? .white : Palette.primary, for: .normal)
            button.layer.borderColor = Palette.border.cgColor
            button.layer.borderWidth = isSelected ? 0 : 1
        }
    }

    @objc private func generateReplies() {
        replyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        currentReplies = replies(for: inputField.text ?? "", style: selectedStyle)

        for (index, reply) in currentReplies.enumerated() {
            replyStack.addArrangedSubview(replyCard(reply, index: index))
        }
    }

    private func replies(for message: String, style: Style) -> [String] {
        let hasMessage = !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch style {
        case .gentle:
            return hasMessage
                ? ["我懂你的意思，先不用急著回我。等你比較有心情時，我再慢慢聽你說。", "辛苦了，你先照顧好自己。晚點想聊的話，我都在。"]
                : ["你先好好休息，不用急著回我。", "我懂，等你想聊時我都在。"]
        case .funny:
            return ["那我先把聊天頻道調成低打擾模式，等你回來再重新開播。", "收到，我先安靜一下，但你不能偷偷忘記我。"]
        case .flirty:
            return ["好，那我先不吵你。只是你休息好之後，要記得回來找我。", "那你先休息，我會乖乖等你回覆。"]
        case .apology:
            return ["剛剛如果讓你有壓力，我先跟你說抱歉。我會注意語氣，也給你一點空間。", "我不是想逼你回覆，只是有點在意。抱歉，我會放慢一點。"]
        }
    }

    private func replyCard(_ reply: String, index: Int) -> UIView {
        let card = UIView()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.border.cgColor
        card.tag = index

        let label = UILabel()
        label.text = reply
        label.font = .systemFont(ofSize: 13)
        label.textColor = Palette.text
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(label)

        let action = UILabel()
        action.text = "插入"
        action.font = .systemFont(ofSize: 12, weight: .bold)
        action.textColor = Palette.accent
        action.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(action)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 54),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: action.leadingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            action.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            action.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(replyTapped(_:)))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
        return card
    }

    @objc private func replyTapped(_ recognizer: UITapGestureRecognizer) {
        guard let card = recognizer.view, card.tag < currentReplies.count else { return }
        textDocumentProxy.insertText(currentReplies[card.tag])
    }

    @objc private func handleNextKeyboard() {
        advanceToNextInputMode()
    }
}
