# P0 工程任務清單 — AI 戀愛鍵盤 UX 改版

> 對應規格：`CLAUDE_KEYBOARD_UX_SPEC.md` v1.1
> 目標版本：v1.0.5 build 18+
> 此清單可直接交給 GPT / Codex / 其他 AI agent 接手實作
> **每個 task 都附：檔案路徑、改動範圍、驗收條件**

---

## 🎯 P0 — 今天到 1 天內完成（9 個 task）

### TASK 1 — 主按鈕語意改為「我已複製，產生 3 句」

**檔案**：`ios/LoveKeyboard/KeyboardViewController.swift`

**改動**：
- L128：`readButton.setTitle("讀取對話", for: .normal)` → `readButton.setTitle("我已複製，產生 3 句", for: .normal)`
- 按下後行為不變（仍呼叫 `readClipboardAndGenerate`），但因為文案改了，需確認按鈕寬度與字體 fit

**注意**：
- 按鈕高度維持 38pt
- 字體 weight 維持 800
- 如字會擠到，把字體從 15pt 降到 14pt

**驗收**：
- [ ] 按鈕顯示「我已複製，產生 3 句」一行不換行
- [ ] iPhone SE / 13 mini / 15 Pro Max 都不溢出
- [ ] 點擊行為不變

---

### TASK 2 — 3 句回覆異質化規則

**檔案**：`ios/LoveKeyboard/KeyboardViewController.swift`

**改動**：重寫 `makeReplies(for:message:)` 函式（L309-430）的生成邏輯。

**新規則**（給 GPT 寫成 Swift code 時必須遵守）：

```
給定 (style, message)，回傳 [String, String, String]，必須符合：

句 1（主推薦）：
- 字數 < 15 字
- 短直接、有力
- 結尾可句點

句 2（補充）：
- 字數 15-25 字
- 補充細節、情境描繪
- 結尾句點或感嘆號

句 3（邀約/問句）：
- 字數 25-40 字 或 結尾用 "?" 問句
- 內含邀約詞（要不要、一起、來、找天）或 提問
- 結尾用問號 "?" 或邀請語氣

通用約束：
- 3 句的第一個字不能相同（避免「我...我...我...」）
- 3 句結尾不能都用句點（至少 1 句問句或邀約）
- 不用 emoji
- 不用「請」「謝謝」等敬語
- 第二人稱用「妳」（女性對象）或「你」（中性）
```

**注意**：
- 既有 `containsAny()` 和 `shortTopic()` helpers 可繼續用
- 4 種語氣（gentle/funny/flirty/apology）× 多種情境（food/tired/question/cold/negative）的 case 都要更新
- 為了符合異質規則，可能需要重寫每個 case 的句子

**驗收**：
- [ ] 對「我今天有點累」生成的 3 句：句 1 < 15 字，句 2 = 15-25 字，句 3 含問句或邀約
- [ ] 切換 4 種語氣後，異質規則仍成立
- [ ] 句頭字不重複
- [ ] 至少 1 句非句點結尾

---

### TASK 3 — 主推薦卡片視覺強化

**檔案**：`ios/LoveKeyboard/KeyboardViewController.swift`

**改動**：修改 `replyButton(_:index:)` 函式（L201-220）。

**規格**：

```swift
if index == 0 {
    // 主推薦卡
    button.heightAnchor.constraint(equalToConstant: 52).isActive = true  // 從原 ~42 升到 52
    button.backgroundColor = Palette.selectedSoft  // sage
    button.layer.borderWidth = 1.5  // 從 1 升到 1.5
    button.layer.borderColor = Palette.primary.withAlphaComponent(0.30).cgColor  // 從 0.26 升到 0.30
    button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)  // 從 13.5/semibold 升到 14/bold
    button.setTitleColor(Palette.primary, for: .normal)

    // 左側加 ★ 標記
    let starLabel = UILabel()
    starLabel.text = "★"
    starLabel.font = .systemFont(ofSize: 12, weight: .bold)
    starLabel.textColor = Palette.primary
    // ...加到 button 左側 padding 內
} else {
    button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    // 其他保持原本
}
```

**驗收**：
- [ ] 第 1 張卡視覺明顯比第 2/3 張大
- [ ] 第 1 張卡左側有 `★`
- [ ] 第 1 張卡邊框深綠色更明顯
- [ ] 點擊第 1 張仍能正常 insertText

---

### TASK 4 — 語氣 chip 加 ✓ 標記

**檔案**：`ios/LoveKeyboard/KeyboardViewController.swift`

**改動**：修改 `updateStyleButtons()` 函式（L286-294）。

**規格**：

```swift
for button in styleButtons {
    let isSelected = button.tag == selectedStyle.rawValue
    let style = ReplyStyle(rawValue: button.tag)!

    if isSelected {
        button.setTitle("\(style.title) ✓", for: .normal)
        button.backgroundColor = Palette.primary
        button.setTitleColor(.white, for: .normal)
    } else {
        button.setTitle(style.title, for: .normal)
        button.backgroundColor = Palette.card
        button.setTitleColor(Palette.secondary, for: .normal)
    }

    button.layer.borderWidth = 1
    button.layer.borderColor = (isSelected ? Palette.primary : Palette.border).cgColor
}
```

**驗收**：
- [ ] 選中的 chip 文字顯示「{語氣} ✓」
- [ ] 未選中的 chip 只顯示語氣名
- [ ] 切換語氣時 ✓ 跟著移動

---

### TASK 5 — 狀態文字字數收斂

**檔案**：`ios/LoveKeyboard/KeyboardViewController.swift`

**改動**：把所有 `statusLabel.text = "..."` 的字串改成 ≤ 8 字。

**對照表**：

| 原文案 | 新文案 | 字數 |
|---|---|---|
| 複製訊息後讀取 | 等你開始 | 4 |
| 先複製對方訊息 | 剪貼簿空 | 4 |
| {語氣}語氣 | {語氣} · 第 1 組 | ≤ 8 |
| 已選{語氣} | {語氣} · 待讀取 | ≤ 8 |
| 先點讀取對話 | 先點上方按鈕 | 6 |
| 已填入，確認送出 | ✓ 已填入，可送出 | 8 |

**規格**：
- 在 `KeyboardViewController` class 加一個變數 `private var generationCount = 0`
- 每次 `readClipboardAndGenerate` 成功時 `generationCount += 1`
- statusLabel 改顯示「{selectedStyle.title} · 第 \(generationCount) 組」

**驗收**：
- [ ] 所有 statusLabel 文字 ≤ 8 字
- [ ] 讀取成功後顯示「{語氣} · 第 N 組」
- [ ] 切換語氣自動重新生成，N + 1

---

### TASK 6 — 教學頁加「完整取用權限說明」區塊

**檔案**：`lib/views/keyboard/keyboard_guide_view.dart`

**改動**：在 `_SetupCard` 後、`_SwitchKeyboardCard` 前，新增一個 `_PermissionExplainCard` widget。

**內容規格**：

```dart
class _PermissionExplainCard extends StatelessWidget {
  const _PermissionExplainCard();

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      title: '為什麼要「完整取用」',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: 開了會怎樣
          _ExplainRow(icon: '✓', text: '讓鍵盤讀到你剛複製的訊息'),
          _ExplainRow(icon: '✓', text: '才能對訊息生成合適回覆'),
          SizedBox(height: 12),
          Divider(color: KeyboardGuideView._line),
          SizedBox(height: 12),
          Text('不開會怎樣？', style: /* H3 */),
          _ExplainRow(icon: '•', text: '只能用 4 種固定模板'),
          _ExplainRow(icon: '•', text: '無法依對方訊息個人化生成'),
          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 12),
          Text('我們的承諾', style: /* H3, forest 色 */),
          _ExplainRow(icon: '✓', text: '不蒐集你的訊息內容', color: forest),
          _ExplainRow(icon: '✓', text: '不上傳到任何伺服器', color: forest),
          _ExplainRow(icon: '✓', text: '處理完成立即丟棄', color: forest),
        ],
      ),
    );
  }
}
```

**注意**：
- 沿用 `_GuideCard` 樣式（已有）
- 文案完全照規格走，不要改字
- 「我們的承諾」三條要用 forest 色強化信任感

**驗收**：
- [ ] 教學頁出現新區塊「為什麼要『完整取用』」
- [ ] 三個小節：開了怎樣 / 不開怎樣 / 我們的承諾
- [ ] 視覺與其他卡片一致

---

### TASK 7 — 「尚未讀取」狀態大型卡片

**檔案**：`ios/LoveKeyboard/KeyboardViewController.swift`

**改動**：當 `currentMessage.isEmpty` 時，把 `replyStack` 內容換成一張大型空狀態卡片，而不是顯示 3 條空文字提示。

**規格**：
- 卡片高度 ~120pt
- 內容：標題「先複製對方訊息」+ 副標「再回來點一下，3 秒給你 3 句」+ 主按鈕「我已複製，產生 3 句」
- 按鈕行為等同既有的 `readClipboardAndGenerate`
- **此狀態下不顯示原本的「讀取對話」按鈕列**（避免重複）

**實作建議**：
- 在 `renderReplies()` 內判斷 `currentMessage.isEmpty`
- 若 empty：把 `replyStack` 換成 `makeEmptyStateCard()`
- 若 有內容：照原本流程渲染 3 張 reply

**驗收**：
- [ ] 首次開鍵盤、未讀任何訊息時，看到大型空狀態卡片
- [ ] 點卡片內主按鈕能正常讀剪貼簿
- [ ] 讀取成功後，空狀態消失、3 張卡片出現

---

### TASK 8 — App 內試用區（Onboarding Page 8）

**檔案**：新增 `lib/views/onboarding/onboarding_try_view.dart`

**規格**：

```dart
class OnboardingTryView extends StatefulWidget {
  // ...
}

class _OnboardingTryViewState extends State<OnboardingTryView> {
  String currentMessage = "我今天真的有點累";  // 預設例句
  String currentStyle = "曖昧";  // 預設語氣
  List<String> currentReplies = [];  // 由本地規則生成

  // 提供 4-6 個 demo 例句讓使用者換
  final demoMessages = [
    "我今天真的有點累",
    "你假日都做什麼？",
    "隨便啦你決定",
    "晚上要吃什麼",
    "我覺得我們不太適合",
  ];

  void _generateReplies() {
    // 呼叫和 KeyboardViewController 一樣的邏輯
    // 因為這是 Flutter 端，需要把規則模板複製過來
    // 或之後接 API 後直接用 API
  }

  // UI:
  // 上方：「試玩一下我們的 AI」標題
  // 中段：例句卡片 + 「換例句」按鈕
  // 下段：3 張 AI 回覆卡片（樣式同鍵盤）
  // 下下段：4 個語氣 chip
  // 底部：「試完了，去訂閱」CTA
}
```

**注意**：
- 此頁不需要切到外部 App 即可體驗完整流程
- 樣式與鍵盤一致（奶油白、forest 強調）
- 換例句、切語氣都即時更新 3 句回覆

**驗收**：
- [ ] Onboarding Page 8 出現此頁
- [ ] 可以點「換例句」chip 切換預設訊息
- [ ] 可以切換 4 種語氣
- [ ] 3 句回覆會依切換重新生成
- [ ] 視覺與鍵盤一致

---

### TASK 9 — 更新 `keyboard_guide_view.dart` 預覽動畫

**檔案**：`lib/views/keyboard/keyboard_guide_view.dart`

**改動**：把 `_KeyboardPreview` 內的 mock 按鈕文案改成「我已複製，產生 3 句」（對齊新主按鈕文案）。

**位置**：L222 附近：

```dart
child: const Text(
  '讀取剪貼簿對話',  // ← 改成
  // '我已複製，產生 3 句'
),
```

**驗收**：
- [ ] 教學頁的鍵盤預覽顯示新文案
- [ ] 與實際鍵盤主按鈕一致

---

## 🔄 P1 — 下一版（v1.0.6+，~1 週內）

### TASK 10 — 語氣切換零延遲三層架構

**檔案**：`ios/LoveKeyboard/KeyboardViewController.swift`

**架構**：

```
讀取成功時：
  1. 立即用本地規則生成 4 種語氣 × 3 句 = 12 句（藏在記憶體）
  2. 顯示當前選中語氣的 3 句
  3. 背景觸發 API 請求 4 種語氣（透過 App Group）
  4. API 回來後，若使用者仍在此訊息，淡入替換

切換語氣時：
  - 立刻顯示快取裡的對應語氣（0 ms）
  - 若 API 已回來該語氣，顯示精緻版

切換訊息時（重讀）：
  - 清空快取
  - 重新走「讀取成功時」流程
```

**驗收**：
- [ ] 切換語氣時無 loading
- [ ] 切換時 200ms 淡入動畫
- [ ] 不會「按一下要等一下」的卡頓感

---

### TASK 11 — 未開完整取用偵測 + 狀態 4.4

**檔案**：`ios/LoveKeyboard/KeyboardViewController.swift`

**改動**：
- `readClipboardAndGenerate()` 增加判斷：若 `UIPasteboard.general.string == nil` 且 `UIPasteboard.general.hasStrings == false`，視為未開權限
- 顯示狀態 4.4（紅色 banner + 「打開 iPhone 設定」）

**驗收**：
- [ ] 未開完整取用時，看到清楚的引導 banner
- [ ] 點按鈕能跳到 host App 或彈 toast 指引

---

### TASK 12 — 「找不到鍵盤」獨立頁面

**檔案**：新增 `lib/views/keyboard/keyboard_troubleshoot_view.dart`

**規格**：照規格第 7 節做，包含 3 個 checklist + 切換動畫 + 客服聯絡入口。

---

### TASK 13 — 「如何複製對方訊息」獨立頁面

**檔案**：新增 `lib/views/keyboard/copy_message_guide_view.dart`

**規格**：照規格第 8 節做，3 個 App 卡片（LINE / IG / Tinder）+ 通用方法動畫。

---

### TASK 14 — 重新生成按鈕「↻ 第 N 組」

**檔案**：`ios/LoveKeyboard/KeyboardViewController.swift`

**改動**：在標題列右側加一個 tap target，點下後 `generationCount += 1` 並重新呼叫生成邏輯。

---

### TASK 15 — 已填入狀態的替換邏輯

**檔案**：`ios/LoveKeyboard/KeyboardViewController.swift`

**改動**：`replyTapped()` 函式內，若已經有填入過的句子，先 `deleteBackward()` × N 次再 `insertText()` 新句。

**追蹤上次填入字數**：用 `private var lastInsertedLength: Int = 0`。

---

## 🚀 買量前必須做（接 AI API、變現相關）

### TASK 16 — 接 AI API（透過 host App 代打）

**架構**：
- Flutter 端建立 `AIReplyService`
- iOS extension 透過 App Group + Darwin Notification 觸發 host
- host 收到觸發後呼叫 API（Claude 或 OpenAI）
- 結果存回 App Group 共享空間
- extension 讀取結果並顯示

### TASK 17 — Streaming 流式回覆 UI

**規格**：規格第 9.3 節

### TASK 18 — 額度管理 UI

**位置**：標題列右側顯示「今日剩 N 次」，≤ 3 時加 [升級] 按鈕

### TASK 19 — 失敗 fallback 完整矩陣

**5 種錯誤**：網路逾時 / 沒網路 / API 失敗 / 額度用完 / 內容違規

---

## ⚙️ 全域驗收條件

每個 P0 task 完成後，需通過以下測試：

- [ ] iPhone SE / 13 mini / 14 Pro / 15 Pro Max 都不溢出
- [ ] 鍵盤高度仍 ≥ 304pt
- [ ] 中文字無截斷
- [ ] 點擊熱區 ≥ 44×44 pt
- [ ] 切換語氣後狀態文字正確更新
- [ ] 工具列（刪除/空白/換行/切鍵盤）永遠可用

---

## 📋 交接給 GPT/Codex 的 prompt 樣板

當你要把任一 task 交給 GPT/Codex 時，建議用以下格式：

```
你是 iOS Swift 工程師。請完成 TASK X：
[貼 task 內容]

限制：
- 只改指定檔案
- 不要重寫整個 class
- 不要新增不必要的依賴
- 改完後給我完整 git diff

驗收條件：
[貼驗收清單]
```

---

## 📊 P0 完成預估

| Task | 預估時間 | 難度 |
|---|---|---|
| 1 主按鈕語意 | 5 分鐘 | 低 |
| 2 3 句異質規則 | 1-2 小時 | 中（要重寫多個 case） |
| 3 主推薦卡視覺 | 20 分鐘 | 低 |
| 4 語氣 chip ✓ | 10 分鐘 | 低 |
| 5 狀態文字 | 30 分鐘 | 低 |
| 6 完整取用說明區塊 | 30 分鐘 | 低 |
| 7 空狀態大卡 | 1 小時 | 中 |
| 8 試用區頁 | 2-3 小時 | 中 |
| 9 預覽動畫文案 | 5 分鐘 | 低 |

**P0 總計**：5-8 小時（單人專注）
