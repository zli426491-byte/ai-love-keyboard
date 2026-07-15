# CODEX 任務：LoveKey 全功能 QA 走查（逐畫面、逐功能）

> 日期：2026-07-11
> 專案：`C:\Users\AsusGaming\ai_love_keyboard`
> 模式：**先檢查、先報告，不要邊測邊改程式。** 報告完成後等人類批准再修。
> 本文件由 Claude 事先掃過全部 33 個 view 檔與服務層後編寫，畫面清單與嫌疑 bug 都對應真實程式碼。

---

## 0. 環境準備

```powershell
# 1. 重 build（改過 lib/ 之後都要）
cd "C:\Users\AsusGaming\ai_love_keyboard"
C:\Users\AsusGaming\flutter-sdk\bin\flutter.bat build web --release

# 2. serve 並打開
cd "C:\Users\AsusGaming\ai_love_keyboard\build\web"
python -m http.server 8765
# 開 http://localhost:8765
```

- 開發迭代可改用 `flutter.bat run -d chrome`（hot reload）。
- **重置成全新用戶**：SharedPreferences 在 web 上存在 localStorage（key 前綴 `flutter.`）。DevTools → Application → Local Storage → 全部清掉再重整，就會重走 隱私同意 → 性別選擇 → Onboarding。pref key 名稱見 `lib/utils/constants.dart`。
- **模擬 iPhone 尺寸**：DevTools device toolbar。必測三種寬度：390（標準）、375、**320（SE 級，最容易爆版）**。

### Web 上「屬於正常」的差異（不要當 bug 報）

1. RevenueCat 在非 iOS 直接跳過（`revenuecat_service.dart` init 早退），Paywall 顯示「訂閱方案載入中」/「TestFlight 實機測試購買」屬預期。
2. iOS 鍵盤 extension（`ios\LoveKeyboard\`）網頁看不到，不在本次範圍。
3. `app-settings:` 連結（鍵盤教學、Onboarding STEP 2）在網頁無反應屬預期，但**畫面不能因此 crash 或無提示卡死**——沒反應時是否給提示，這個要檢查。
4. AI 回覆在 web 可能走 `kIsWeb` 預覽模式（見 `ai_service.dart`），回覆內容品質不列入本次評分，但 loading/error/複製流程要測。

---

## 1. 實際可達的畫面流（必須逐一走過）

啟動判斷順序（`main.dart _getInitialScreen`）：隱私同意 → 性別選擇 → Onboarding → HomeView。

對**每一個畫面**都要做兩件事：(a) 功能走查（下面列的狀態全部觸發一遍）；(b) UI 細看（間距、對齊、字級層次、色彩對比、文案語氣、爆版、暗色模式）。

| # | 畫面 | 進入方式 | 必測狀態 |
|---|------|---------|---------|
| 1 | PrivacyNoticeDialog 隱私同意 | 清空 localStorage 後首啟 | 不可點背景關閉；「查看完整隱私權政策」外連是否有效；同意後正確進下一關 |
| 2 | GenderSelectionView 性別選擇 | 首啟流程 | 未選時「繼續」半透明不可按；選中動畫；確認後不可返回（pushAndRemoveUntil） |
| 3 | OnboardingView 三步驟教學 | 首啟流程 | 3 頁滑動與圓點；「跳過」；第 3 頁按鈕變「開始使用」；STEP 2 的設定連結在 web 無反應時的體驗 |
| 4 | HomeView-首頁分頁 | 主畫面 | 輸入→選 9 個語氣格子任一→生成；**空輸入按生成的行為（見嫌疑 bug B11）**；生成中轉圈；免費額度 3 次用完後是否正確彈 Paywall；「情感老師」「文案改寫」卡片 |
| 5 | HomeView-盲盒分頁 | 底部導覽 | 「放盲盒」sheet（預填文字、送出後只有 snackbar？）；「抽盲盒」扣 10 金幣；金幣不足 AlertDialog 可跳金幣商店；**連抽兩次內容是否一樣（見 B10）** |
| 6 | HomeView-消息分頁 | 底部導覽 | 兩張靜態卡；點擊行為 |
| 7 | HomeView-我的分頁 | 底部導覽 | 會員卡免費/Pro 兩態；關於（版本號）；mailto 反饋失敗的 fallback；評分連結；複製商務信箱 |
| 8 | PaywallView 付費牆 | 皇冠圖示/會員卡/額度用盡 | 三方案卡與預設選中第 2 個；web 上的鎖定文案；關閉按鈕；**購買中下滑關閉 sheet 的行為（見 B2）**；文案有無「保證成功」類高風險字眼 |
| 9 | ReplyCardsView 回覆結果 | 首頁生成成功後 | loading 態；語氣徽章配色；複製 snackbar；「重新生成」在額度用盡時的行為（只 snackbar 不彈牆，一致性？） |
| 10 | SettingsView 設定 | 我的分頁/盲盒齒輪 | **訂閱卡標題永遠寫「免費版」的文案 bug**；14 地區 ChoiceChip 切換；隱私兩個 Switch；「刪除所有資料」紅色確認框並驗證真的清掉；內容過濾 SegmentedButton |
| 11 | KeyboardGuideView 鍵盤教學 | 首頁鍵盤管理/設定頁 | 步驟圖文正確性（要對應「複製→切鍵盤→選語氣→填入」新流程，不能殘留舊版三句回覆流程）；按鈕無反應時的提示 |
| 12 | CoinStoreView 金幣商店 | 盲盒分頁金幣膠囊 | 餘額即時更新;「免費獲得金幣」**可否無限領（見 B3）**；交易紀錄空/有兩態；「觀看廣告即將推出」 |

另外把每一頁的 **暗色模式**（themeMode 跟隨系統，DevTools 可模擬 prefers-color-scheme: dark）和 **320px 寬**各過一遍，特別注意 HomeView 9 宮格、Paywall 三方案卡、成就進度條這類橫向排列。

## 2. 死路由與孤兒畫面（程式碼層檢查 + 給產品決策建議）

以下 7 條路由**已註冊但整個 App 沒有任何入口**：`/character-market`、`/create-persona`、`/package-store`、`/achievements`、`/seasonal-packages`、`/referral`、`/emergency`。

以下 11+ 頁**完全孤兒**（無路由也無 import）：OpenerView、ChatAnalysisView、DateInvitationView、ArgumentResolveView、GreetingsView、TranslateReplyView、TopicSuggestionsView、TimingCoachView、CultureTipsView、ShareSuccessView、OnboardingTryView，及 components 裡實為完整頁的 EmojiSuggesterView、ReplyScorerView。

要求：
1. 可以在**不 commit** 的前提下臨時加 debug 入口逐一目視這些頁（測完還原），或至少做程式碼層 UI 審查。
2. 在報告中給出分類建議：哪些該接回入口（做了 UI 卻沒曝光 = 白做）、哪些該刪（死碼增加維護成本與審核風險）。
3. DeepLinkService 會推 `/opener`、`/paywall`、`/analysis` 三條**未註冊**路由——確認並記錄（未來接 deep link 會直接 crash）。

## 3. 已知嫌疑 bug 清單（逐條驗證真偽，附證據）

Claude 靜態掃碼找到的，**每一條都要實際驗證後在報告標記「確認/誤報」**：

**P0（擋錢/擋上架）**
- B1 `emergency_coach_view.dart:52-62`：AI 失敗（回 null）照樣扣 15 金幣，且不顯錯。
- B2 `paywall_view.dart:43-45`：`if (!mounted) return;` 在 `setSubscribed(true)` 之前——購買期間 sheet 被關掉，付了錢但 Pro 不解鎖（重啟才恢復）。
- B3 `coin_store_view.dart:74-98`：金幣包無限免費領、無旗標控制，金幣經濟形同虛設。

**P1（壞體驗/壞轉換）**
- B4 `api_proxy_service.dart:175`：http.post 無 timeout，後端掛掉全 App 轉圈永不結束。
- B5 `api_proxy_service.dart:118,167`：isPro 永遠 false 傳給後端，付費用戶可能被當免費限流。
- B6 `usage_service.dart`：每日額度只在冷啟動重置，跨日從背景喚回仍被擋。
- B7 `usage_service.dart` vs `revenuecat_service.dart`：兩處用不同 payload 打同一個 MethodChannel `setSubscriptionStatus`，可能互踩。
- B8 `main.dart:66-134`：16 個 `catch (_) {}` 全靜默，金流初始化失敗無跡可查。
- B9 `referral_service.dart:107`：recordReferral 無人呼叫、IG 分享獎勵沒真的發放——邀請頁承諾全是虛假的。
- B10 `home_view.dart:2919`：抽盲盒扣 10 金幣但內容永遠是同一句寫死文案。
- B11 `home_view.dart:63-65`：空輸入自動塞「我今天真的有點累」還真扣免費額度。
- B12 `keyboard_guide_view.dart:26-29`：設定打不開時靜默無反應（產品最關鍵的引導步驟）。
- B13 `ai_service.dart:77-96`：重模型每日 20 次限額只存記憶體，重啟歸零；失敗也消耗配額。
- B14 i18n：支援 14 個市場但 UI 全部寫死繁中，海外買量進來看到全中文。

**P2（打磨）**
- B15 `ai_service.dart`：錯誤直接 e.toString() 給用戶看（會出現英文技術字串）。
- B16 `ai_service.dart:223`：`IntimacyLevel.levels[intimacyLevel - 1]` 無範圍檢查。
- B17 `locale_service.dart:1`：疑似無條件 import dart:io（但 web build 有過，請查證是否條件式匯入，屬「待查證」）。
- B18 `coin_service.dart`：交易 id 用毫秒時間戳，同毫秒會碰撞；歷史 jsonDecode 損毀被靜默吞掉。
- B19 `revenuecat_service.dart`：金流錯誤只給籠統訊息不記原始 error。

## 4. 跨畫面通用測項（每一頁都要跑）

1. **連點兩下**：所有扣費/扣額度按鈕（生成、抽盲盒 10 幣、緊急分析 15 幣、購買）async 期間是否 debounce，會不會雙重扣。
2. **loading 中按返回**：pop 之後回傳結果打在已 dispose 的頁面？AiService 共用的 isLoading 會不會卡住，導致下次進頁永遠轉圈。
3. **額度用盡的一致性**：各功能入口在 canUse=false 時，「彈 Paywall」vs「只出 snackbar」的行為要一致（已知 ReplyCardsView 重新生成只給 snackbar）。
4. **狀態同步**：扣幣後 AppBar 金幣膠囊 vs 金幣商店餘額；（模擬）訂閱後我的分頁會員卡、各功能擋點是否即時解鎖。
5. **文字縮放**：DevTools 模擬字體放大（或 MediaQuery textScaleFactor 1.3），檢查按鈕文字截斷。
6. **Console 零容忍**：走查全程開著 DevTools Console，任何紅字例外都記進報告。

## 5. 自動化檢查（跑完附輸出）

```powershell
cd "C:\Users\AsusGaming\ai_love_keyboard"
C:\Users\AsusGaming\flutter-sdk\bin\flutter.bat analyze
C:\Users\AsusGaming\flutter-sdk\bin\flutter.bat test
C:\Users\AsusGaming\flutter-sdk\bin\flutter.bat build web --release
```

另外 grep 確認 client 端沒有 `sk-` / `cfat_` 私鑰字串。

## 6. 報告格式（唯一產出）

寫到 `C:\Users\AsusGaming\ai_love_keyboard\LOVEKEY_QA_REPORT_2026-07-11.md`，截圖放 `qa_screenshots\`：

1. **總結**：一句話 + P0/P1/P2 數量統計。
2. **Bug 表**：每條含「編號｜嚴重度｜畫面｜重現步驟｜預期｜實際｜檔案:行號｜建議修法（一句話）」。上面 B1-B19 逐條標「確認/誤報/無法在 web 驗證」。
3. **UI 調整建議表**：每條含「畫面｜問題（附截圖檔名）｜建議改法｜影響範圍」。只提具體可執行的（例如「Paywall 三方案卡在 320px 擠壓，改 Wrap」），不要泛泛而談。
4. **死碼/孤兒頁處置建議**：接回 or 刪除，逐頁一行理由。
5. **修復優先順序**：你建議的動工順序（P0 全修 → 哪些 P1 值得在 TestFlight 前修）。

**規則重申**：本任務只檢查 + 報告。除了臨時 debug 入口（測完還原、不 commit）以外，不改任何程式碼；報告交出後等批准再開修。
