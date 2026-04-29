import UIKit

// MARK: - Keyboard View Controller
class KeyboardViewController: UIInputViewController {

    // MARK: - Constants
    private enum Colors {
        static let primary = UIColor(red: 124/255, green: 58/255, blue: 237/255, alpha: 1)     // #7C3AED
        static let primaryLight = UIColor(red: 159/255, green: 103/255, blue: 255/255, alpha: 1)
        static let accent = UIColor(red: 45/255, green: 212/255, blue: 191/255, alpha: 1)       // #2DD4BF
        static let bgColor = UIColor(red: 248/255, green: 247/255, blue: 255/255, alpha: 1)
        static let cardBg = UIColor.white
        static let textPrimary = UIColor(red: 30/255, green: 27/255, blue: 75/255, alpha: 1)
        static let textSecondary = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)
    }

    private enum API {
        static let url = "https://api.openai.com/v1/chat/completions"
        static let model = "gpt-4o"
        // API key is loaded from App Group shared UserDefaults
        static let appGroupId = "group.com.ailovekeyboard.app"
        static let apiKeyKey = "openai_api_key"
    }

    private enum Style: String, CaseIterable {
        case humorous = "幽默"
        case romantic = "浪漫"
        case flirty = "撩人"
        case cool = "高冷"
    }

    // MARK: - Properties
    private var selectedStyle: Style = .humorous
    private var generatedReplies: [String] = []
    private var isLoading = false

    // MARK: - UI Elements
    private let containerView = UIView()
    private let inputField = UITextField()
    private var styleButtons: [UIButton] = []
    private let generateButton = UIButton(type: .system)
    private let switchKeyboardButton = UIButton(type: .system)
    private let repliesStackView = UIStackView()
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    // MARK: - UI Setup
    private func setupUI() {
        guard let inputView = self.inputView else { return }
        inputView.allowsSelfSizing = true

        // Container
        containerView.backgroundColor = Colors.bgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        inputView.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: inputView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: inputView.bottomAnchor),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 280),
        ])

        // ScrollView for the entire keyboard content
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        containerView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -6),
        ])

        // Main vertical stack
        contentStackView.axis = .vertical
        contentStackView.spacing = 8
        contentStackView.alignment = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 10),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -10),
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -20),
        ])

        // --- Header row: title + switch keyboard button ---
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .fill

        let titleLabel = UILabel()
        titleLabel.text = "💜 AI 戀愛鍵盤"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = Colors.primary
        headerStack.addArrangedSubview(titleLabel)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerStack.addArrangedSubview(spacer)

        switchKeyboardButton.setTitle("切換鍵盤 ⌨️", for: .normal)
        switchKeyboardButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        switchKeyboardButton.setTitleColor(Colors.textSecondary, for: .normal)
        switchKeyboardButton.addTarget(self, action: #selector(handleSwitchKeyboard), for: .touchUpInside)
        headerStack.addArrangedSubview(switchKeyboardButton)

        contentStackView.addArrangedSubview(headerStack)

        // --- Input field ---
        inputField.placeholder = "貼上對方的訊息..."
        inputField.font = UIFont.systemFont(ofSize: 14)
        inputField.borderStyle = .none
        inputField.backgroundColor = Colors.cardBg
        inputField.layer.cornerRadius = 10
        inputField.layer.borderWidth = 1
        inputField.layer.borderColor = UIColor.systemGray4.cgColor
        inputField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        inputField.leftViewMode = .always
        inputField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        inputField.rightViewMode = .always
        inputField.heightAnchor.constraint(equalToConstant: 38).isActive = true
        inputField.textColor = Colors.textPrimary
        contentStackView.addArrangedSubview(inputField)

        // --- Style buttons row ---
        let styleStack = UIStackView()
        styleStack.axis = .horizontal
        styleStack.spacing = 8
        styleStack.distribution = .fillEqually

        for style in Style.allCases {
            let button = UIButton(type: .system)
            button.setTitle(style.rawValue, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            button.layer.cornerRadius = 16
            button.heightAnchor.constraint(equalToConstant: 32).isActive = true
            button.tag = Style.allCases.firstIndex(of: style) ?? 0
            button.addTarget(self, action: #selector(styleButtonTapped(_:)), for: .touchUpInside)
            styleButtons.append(button)
            styleStack.addArrangedSubview(button)
        }
        updateStyleButtons()
        contentStackView.addArrangedSubview(styleStack)

        // --- Generate button ---
        generateButton.setTitle("生成回覆 ✨", for: .normal)
        generateButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.backgroundColor = Colors.primary
        generateButton.layer.cornerRadius = 12
        generateButton.heightAnchor.constraint(equalToConstant: 42).isActive = true
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        contentStackView.addArrangedSubview(generateButton)

        // --- Loading indicator ---
        loadingIndicator.color = Colors.primary
        loadingIndicator.hidesWhenStopped = true
        contentStackView.addArrangedSubview(loadingIndicator)

        // --- Replies stack ---
        repliesStackView.axis = .vertical
        repliesStackView.spacing = 6
        repliesStackView.alignment = .fill
        contentStackView.addArrangedSubview(repliesStackView)
    }

    // MARK: - Style Selection
    @objc private func styleButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        if index < Style.allCases.count {
            selectedStyle = Style.allCases[index]
            updateStyleButtons()
        }
    }

    private func updateStyleButtons() {
        for (index, button) in styleButtons.enumerated() {
            let style = Style.allCases[index]
            if style == selectedStyle {
                button.backgroundColor = Colors.primary
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = Colors.primary.withAlphaComponent(0.1)
                button.setTitleColor(Colors.primary, for: .normal)
            }
        }
    }

    // MARK: - Generate Replies
    @objc private func generateTapped() {
        guard let message = inputField.text, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showTemporaryMessage("請先輸入對方的訊息")
            return
        }

        guard !isLoading else { return }
        isLoading = true
        loadingIndicator.startAnimating()
        generateButton.isEnabled = false
        generateButton.alpha = 0.6

        // Clear previous replies
        repliesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Get API key from App Group
        let apiKey = getApiKey()
        guard !apiKey.isEmpty else {
            showTemporaryMessage("請先在 App 中設定 API Key")
            isLoading = false
            loadingIndicator.stopAnimating()
            generateButton.isEnabled = true
            generateButton.alpha = 1.0
            return
        }

        // Call OpenAI API
        callOpenAI(message: message, style: selectedStyle.rawValue, apiKey: apiKey) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.loadingIndicator.stopAnimating()
                self?.generateButton.isEnabled = true
                self?.generateButton.alpha = 1.0

                switch result {
                case .success(let replies):
                    self?.generatedReplies = replies
                    self?.displayReplies(replies)
                case .failure(let error):
                    self?.showTemporaryMessage("生成失敗：\(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - API Call
    private func getApiKey() -> String {
        let defaults = UserDefaults(suiteName: API.appGroupId)
        return defaults?.string(forKey: API.apiKeyKey) ?? ""
    }

    private func callOpenAI(message: String, style: String, apiKey: String, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: API.url) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let systemPrompt = """
        你是一位頂尖的戀愛溝通專家，專精於交友軟體和通訊軟體的對話技巧。
        你的任務是根據對方傳來的訊息，用「\(style)」的風格生成 3 個回覆建議。

        規則：
        1. 每個回覆必須自然、口語化，像真人在聊天
        2. 不要太長，控制在 1-3 句話
        3. 要能延續話題或引導新話題
        4. 用繁體中文回覆
        5. 適合台灣/香港用戶的用語習慣

        請以下列 JSON 格式回傳，不要包含其他文字：
        {"replies": [{"id": "1", "text": "回覆內容1"}, {"id": "2", "text": "回覆內容2"}, {"id": "3", "text": "回覆內容3"}]}
        """

        let body: [String: Any] = [
            "model": API.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "對方的訊息：「\(message)」"]
            ],
            "max_tokens": 512,
            "temperature": 0.8
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2)))
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {

                    // Check for API error
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorObj = json["error"] as? [String: Any],
                       let errorMessage = errorObj["message"] as? String {
                        completion(.failure(NSError(domain: errorMessage, code: -3)))
                        return
                    }
                    completion(.failure(NSError(domain: "Invalid response format", code: -4)))
                    return
                }

                // Parse the reply JSON
                var jsonStr = content.trimmingCharacters(in: .whitespacesAndNewlines)
                // Strip markdown code block if present
                if jsonStr.hasPrefix("```") {
                    jsonStr = jsonStr.replacingOccurrences(of: "```json", with: "")
                    jsonStr = jsonStr.replacingOccurrences(of: "```", with: "")
                    jsonStr = jsonStr.trimmingCharacters(in: .whitespacesAndNewlines)
                }

                guard let replyData = jsonStr.data(using: .utf8),
                      let replyJson = try JSONSerialization.jsonObject(with: replyData) as? [String: Any],
                      let replies = replyJson["replies"] as? [[String: Any]] else {
                    completion(.failure(NSError(domain: "Cannot parse replies", code: -5)))
                    return
                }

                let replyTexts = replies.compactMap { $0["text"] as? String }
                completion(.success(replyTexts))

            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Display Replies
    private func displayReplies(_ replies: [String]) {
        repliesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, reply) in replies.enumerated() {
            let card = createReplyCard(text: reply, index: index)
            repliesStackView.addArrangedSubview(card)
        }
    }

    private func createReplyCard(text: String, index: Int) -> UIView {
        let card = UIView()
        card.backgroundColor = Colors.cardBg
        card.layer.cornerRadius = 10
        card.layer.borderWidth = 1
        card.layer.borderColor = Colors.primary.withAlphaComponent(0.2).cgColor

        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = Colors.textPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(label)

        let insertIcon = UILabel()
        insertIcon.text = "📋"
        insertIcon.font = UIFont.systemFont(ofSize: 16)
        insertIcon.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(insertIcon)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: insertIcon.leadingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),

            insertIcon.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            insertIcon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            insertIcon.widthAnchor.constraint(equalToConstant: 24),
        ])

        // Tap gesture to insert text
        let tap = UITapGestureRecognizer(target: self, action: #selector(replyCardTapped(_:)))
        card.isUserInteractionEnabled = true
        card.addGestureRecognizer(tap)
        card.tag = index

        return card
    }

    @objc private func replyCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view else { return }
        let index = card.tag
        guard index < generatedReplies.count else { return }

        let reply = generatedReplies[index]
        // Insert the reply text into the current text field
        textDocumentProxy.insertText(reply)

        // Visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            card.backgroundColor = Colors.accent.withAlphaComponent(0.15)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                card.transform = .identity
                card.backgroundColor = Colors.cardBg
            }
        }
    }

    // MARK: - Switch Keyboard
    @objc private func handleSwitchKeyboard() {
        advanceToNextInputMode()
    }

    // MARK: - Helpers
    private func showTemporaryMessage(_ message: String) {
        let label = UILabel()
        label.text = message
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1)
        label.textAlignment = .center
        repliesStackView.addArrangedSubview(label)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.3, animations: {
                label.alpha = 0
            }) { _ in
                label.removeFromSuperview()
            }
        }
    }
}
