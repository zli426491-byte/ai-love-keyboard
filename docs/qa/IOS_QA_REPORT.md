# LoveKey iOS QA 歷史報告（2026-07-15 Windows 階段）

> 本檔保存第一輪 Windows QA 歷史。最新 Simulator 與實機抽查結果請看 IOS_QA_REPORT_2026-07-16.md。

## 摘要

| 項目 | 當時結果 |
| --- | --- |
| QA 日期 | 2026-07-15 |
| 分支 | qa/ios-autonomous-qa |
| Host | Windows 11 |
| Flutter／Dart | Flutter 3.41.7／Dart 3.11.5 |
| flutter analyze | 通過，0 問題 |
| Flutter tests | 修正後 25/25 通過 |
| 對話測試 | 14/14 通過，mock／靜態模式 |
| UI／Widget | 修正後 9/9 通過 |
| 當時 iOS Simulator | 未執行 |
| 當時發現 | P0：0、P1：0、P2：8、P3：0 |
| 修正 | 8 項均已修復並新增回歸測試 |

## 當時實際執行

- flutter pub get：通過。
- flutter analyze --no-pub：通過。
- flutter test --no-pub：修正後通過。
- scripts/dialogue_eval.sh：14/14。
- scripts/ui_audit.sh：修正後 9/9。
- flutter build web --release --no-pub：通過。
- Windows integration test：因 Visual Studio 缺少 ATL/MFC header atlstr.h，未啟動。
- Chrome integration test：Flutter 不支援以該命令在 Web device 執行。
- Windows 主機沒有 Xcode，因此當時未執行 iOS Simulator。

## 八項 P2 修正

### QA-AI-001：AI 回應防禦性解析

- 問題：直接索引 choices[0]，外部格式異常時可能產生不一致 runtime error。
- 修正：逐層驗證 choices、message、content，並支援 structured text block。
- 測試：ai_response_quality_test.dart。
- 狀態：已修復。

### QA-AI-002：阻擋模型／模板痕跡

- 問題：非空且長度合格的 placeholder、JSON、code fence 或模型說明可能被當成可發送回覆。
- 修正：新增集中式 ReplyQualityValidator。
- 測試：ai_response_quality_test.dart。
- 狀態：已修復。

### QA-UI-001：320px 首頁底部導覽 overflow

- 修正：導覽項目改用 Expanded 平均分配。
- 測試：iPhone SE viewport。
- 狀態：已修復。

### QA-UI-002：onboarding 大字體 overflow

- 修正：文字使用 Expanded、單行及 ellipsis。
- 測試：320x568、text scale 1.3。
- 狀態：已修復。

### QA-UI-003：小高度 Paywall 內容不可存取

- 修正：Paywall 改為可捲動並保留安全區。
- 狀態：已修復。

### QA-UI-004：會員卡垂直 overflow

- 修正：調整卡片約束與內容排版。
- 狀態：已修復。

### QA-UI-005：個人頁選單橫向 overflow

- 修正：調整可用寬度與文字約束。
- 狀態：已修復。

### QA-UI-006：首次隱私權提示 overflow

- 修正：內容可捲動，按鈕保持可見。
- 狀態：已修復。

## 後續更新

2026-07-16 已在 Codemagic 真正執行 iOS 26.4.1 Simulator：

- Flutter 27/27。
- 對話 14/14。
- UI／Widget 11/11。
- iOS Integration 1/1。
- Simulator build、install、launch 成功。
- LoveKeyboard Extension 版本繼承問題已修復。

因此本檔中「未執行 iOS Simulator」只代表 2026-07-15 的 Windows 階段，不代表目前狀態。
