# LoveKey QA 走查報告

日期：2026-07-11（Asia/Taipei）
範圍：`C:\Users\AsusGaming\ai_love_keyboard`
依據：`CODEX_FULL_QA_TASK.md`
原則：本次只檢查、只記錄，不修改 App 程式碼。

## 1. 結論

目前不建議把這一版當作買量或正式收費上線版。自動化檢查全部通過，但仍有 3 個 P0 需要先修：

1. 緊急教練在 AI 回傳 `null` 時仍可能扣 15 金幣並顯示成功結果（B1）。
2. 購買完成與 paywall 關閉同時發生時，Pro 狀態可能沒有寫入本機（B2）。
3. 金幣商店的「免費獲得金幣」可重複領取，沒有一次性或每日限制（B3）。本次 Web 實測餘額由 586 變 606。

此外，P1 尚有 API timeout、跨日額度、初始化錯誤吞掉、推薦/功能入口未接回、空白輸入仍可消耗額度、設定頁 `app-settings:` 無 fallback、重模型額度只存在記憶體、UI 未本地化等問題。

### 發布判定

| 項目 | 結果 |
|---|---|
| Flutter analyze | 通過：`No issues found!` |
| Flutter test | 通過：3 個測試、`All tests passed!` |
| Flutter web release build | 通過：`Built build\\web`；wasm dry-run 僅有建議性 warning |
| Client 內 `sk-` / `cfat_` 真實密鑰掃描 | 未發現值 |
| Web 主要畫面走查 | 完成，截圖在 `qa_screenshots\\` |
| iOS TestFlight 真機鍵盤／LINE／IG／iMessage／Sandbox 付款／刪除重裝恢復購買 | 本次未能由 Web 預覽驗證，必須另做真機 gate |
| 最終放量 | **Blocked：先修 B1–B3，再重新產出 TestFlight/Android build** |

## 2. 執行證據

### 自動化命令

```text
C:\Users\AsusGaming\flutter-sdk\bin\flutter.bat analyze
C:\Users\AsusGaming\flutter-sdk\bin\flutter.bat test
C:\Users\AsusGaming\flutter-sdk\bin\flutter.bat build web --release
```

### Web 預覽

已在 `http://localhost:8765/` 走查 Home、盲盒、訊息、我的、付費牆、金幣商店、鍵盤教學、設定、AI 回覆結果，並測試 320px viewport。Console 僅記錄一個字型 warning：找不到足夠的 Noto 字型顯示所有字元；`pubspec.yaml` 沒有實際啟用字型 asset。

## 3. B1–B19 逐條結果

| ID | 判定 | 等級 | 證據／重現 | 建議 |
|---|---|---:|---|---|
| B1 | 確認 | P0 | `lib/views/emergency/emergency_coach_view.dart:53-61` 先呼叫 `analyzeEmergency`、再扣金幣；`lib/services/ai_service.dart:615-623` 失敗會回 `null`，畫面仍把 `null` 當結果成功顯示。 | 只有非空且通過內容檢查的結果才扣款；失敗不扣款並顯示可重試狀態。 |
| B2 | 確認（競態） | P0 | `lib/views/paywall/paywall_view.dart:42-55` 先等待 purchase，`!mounted` 時直接 return，故 paywall 被關閉後可能不執行 `usage.setSubscribed(true)`。 | 購買成功後先以服務層/RevenueCat customer info 寫入狀態，再決定是否 pop；加入重啟後重新同步驗證。 |
| B3 | 確認，Web 重現 | P0 | `lib/views/coins/coin_store_view.dart:81-98` 每次按鈕都直接 `addCoins`，沒有 claimed key、日期或交易驗證。本次 `12_coin_before_claim.png` 為 586，連按兩次後 `14_coin_after_claim_2.png` 為 606。 | 免費贈送改成一次性/每日 claim，服務層做 idempotency，不讓 UI 單獨決定餘額。 |
| B4 | 確認 | P1 | `lib/services/api_proxy_service.dart:175-179` `http.post` 沒有 timeout；網路中斷時請求可長時間卡住。 | 加 connect/send/receive timeout，回傳可辨識的 timeout 錯誤。 |
| B5 | 已緩解，介面仍誤導 | P1 | Client `api_proxy_service.dart:118,168` 仍可送 `is_pro`；但 Worker `cloudflare-worker/src/index.js:122-123,276-318` 明確忽略 client flag、改以 RevenueCat entitlement 驗證。 | 移除或改名 client flag，保留 Worker server-side entitlement 作唯一權威；補測未訂閱偽造 `is_pro=true`。 |
| B6 | 確認 | P1 | `lib/services/usage_service.dart:23-28` 只在 init 呼叫 `checkAndReset()`；App 從背景跨午夜回前景沒有 lifecycle refresh。 | 監聽 `AppLifecycleState.resumed`，回前景重新檢查日期與同步額度。 |
| B7 | 誤報／低風險 | P2 | `UsageService` 傳 `isSubscribed`，`RevenueCatService` 傳同欄位加 app user id；iOS bridge 可處理兩種 payload，沒有證據顯示互相清空。 | 保留，但統一 payload schema 並加整合測試，避免未來回歸。 |
| B8 | 確認 | P1 | `lib/main.dart:66-134` 有多個 `catch (_) {}`；服務初始化失敗會被吞掉，使用者只看到不完整功能。 | 至少記錄結構化錯誤與服務名稱；對付款、鍵盤、代理服務顯示可行動提示。 |
| B9 | 確認 | P1 | `lib/services/referral_service.dart:107` 有 `recordReferral()`，未找到任何實際呼叫點；Referral route 也沒有 Home/Profile 入口。 | 若要買量，先接回邀請流程與歸因事件；否則移出 UI 並標成 deferred。 |
| B10 | 確認 | P1 | `lib/views/home/home_view.dart:142-159` 扣 10 金幣後開啟 `_BlindMatchSheet`；內容是固定字串，不是後端/隨機結果。 | 以可驗證資料或明確 demo 標籤取代固定假結果；扣款與結果寫入同一個可重試交易。 |
| B11 | 確認 | P1 | `lib/views/home/home_view.dart:63-65` 空白輸入會自動填入預設句子，之後照常生成並可能消耗每日額度。 | 空白直接提示輸入，不應偷偷代填或消耗 quota。 |
| B12 | 確認 | P1 | `lib/views/keyboard/keyboard_guide_view.dart` 以 `app-settings:` 開設定，沒有不可用時的 fallback/snackbar；Web 點擊無反應屬可預期但沒有解釋。 | iOS 用 `canLaunchUrl` 失敗時顯示手動路徑；Web/Android 顯示平台對應教學。 |
| B13 | 確認 | P1 | `lib/services/ai_service.dart:77-96` 重模型用量只存在 `_heavyModelUsesToday` 記憶體，請求前就遞增；重啟可重置，失敗也可能消耗。 | 後端按 user/device 做每日原子計數；成功後才扣重模型額度。 |
| B14 | 確認 | P1 | `UserLocale` 有多地區選項，但 UI 沒有 `AppLocalizations`；畫面文字仍固定繁中，語系只影響 prompt culture。 | 付款牆、鍵盤教學、錯誤提示先建立最小 i18n，至少覆蓋英/繁中。 |
| B15 | 確認 | P2 | `lib/services/ai_service.dart:256,338,362...` 多處直接把 `e.toString()` 放入錯誤狀態，可能把技術訊息暴露給使用者。 | 對外使用固定錯誤碼/友善文案；詳細例外只進遙測。 |
| B16 | 確認 | P2 | `lib/services/ai_service.dart:223` 直接用 `IntimacyLevel.levels[intimacyLevel - 1]`，沒有範圍保護。 | clamp/enum 驗證，非法值回預設等級並記錄。 |
| B17 | 誤報（目前 Web build 通過） | P2 | `locale_service.dart:1` 使用 `dart:io Platform`，但本次 `flutter build web --release` 成功，且 init 有 fallback。 | 仍建議以 `defaultTargetPlatform`/`PlatformDispatcher` 取代不必要的 dart:io 依賴，降低平台風險。 |
| B18 | 確認 | P2 | `lib/services/coin_service.dart:60-64` 對歷史 JSON 沒有局部復原；`93,110` 以毫秒 timestamp 作交易 ID，快速連續交易可能碰撞。 | 使用 UUID/隨機 nonce；壞紀錄逐筆跳過並保留餘額修復流程。 |
| B19 | 確認 | P2 | `lib/services/revenuecat_service.dart:140-143` 等 catch 只留下通用錯誤，無足夠診斷上下文。 | 以事件/錯誤碼記錄原始原因（不含付款敏感資料），畫面只顯示友善文案。 |

## 4. UI 走查與專業度調整

| 畫面 | 證據 | 觀察 | 優先調整 |
|---|---|---|---|
| Home | `01_home.png`, `10_home_320.png` | 心理測驗/戀愛鍵盤/盲盒三種心智模型同時出現，主 CTA 不夠聚焦；320px 未見水平溢出，但底部卡片被導覽列截斷感明顯。 | P1：只留一個主任務（複製訊息→生成回覆），其餘功能降為次入口；調整 safe-area 與卡片高度。 |
| 盲盒 | `02_blind_box.png` | 粉紫插畫與金幣、抽盒 CTA 很像獨立遊戲，和 AI 鍵盤品牌不一致；`10 金幣／次` 浮標容易讓人誤以為立即扣款。 | P1：明示成本、結果來源、每日上限與取消/重試；視產品決策保留或移至次級 tab。 |
| 訊息 | `03_messages.png` | 只有兩張通知卡，下方大面積空白，像未完成頁。 | P1：加入空狀態、最近活動、下一步 CTA；限制內容寬度避免空白失焦。 |
| 我的 | `04_profile.png` | 非會員卡片文案為「無限鍵盤回覆」，和免費每日額度邏輯衝突；帳號、會員、設定層級清楚度不足。 | P0/P1：改成真實剩餘額度/升級價值；把會員狀態與恢復購買放在同一清楚區塊。 |
| Paywall | `05_paywall.png`, `11_paywall_320.png` | 付費牆本身在 320px 可讀，但 Web 顯示「TestFlight 實機測試購買」disabled；未解釋為何不可在 Web 買。深色 paywall 與全 App 淺粉色視覺跳轉大。 | P1：Web 顯示明確 platform message；統一品牌色階與付款狀態 loading/error/restore。 |
| 金幣商店 | `06_coin_store.png`, `12_coin_before_claim.png`, `14_coin_after_claim_2.png` | 每個卡片都顯示「領取」，外觀像可重複領取的商店；實測兩次即增加 20。 | P0：一次性/每日 claim 狀態、disabled 樣式、服務層去重。 |
| 鍵盤教學 | `07_keyboard_guide.png` | 目前最清楚：三步驟、示意對話、實機流程都有。 | P1：平台分流，`app-settings:` 失敗時提供手動導覽；補 Android 版本。 |
| 設定 | `08_settings.png` | 語言 chips、鍵盤步驟、隱私、刪除資料全部塞在長頁；切換語言後 UI 仍固定中文。 | P1：分成「鍵盤」「語言」「隱私與資料」「關於」四組；加 sticky section heading 與確認對話框。 |
| AI 回覆結果 | `09_ai_reply.png` | 回覆卡只有一張，上下空白非常大，重新生成固定在底部；結果可信度與下一步不明顯。 | P1：加入複製成功 feedback、回覆風格標籤、重新生成原因/剩餘額度；空結果與錯誤要有明確狀態。 |

### 視覺系統共通問題

- 漸層、陰影、圓角與插畫密度過高，Home/盲盒/Paywall 像三個不同產品。
- `AppTheme.lightTheme` 目前直接回傳 `darkTheme`（`lib/utils/app_theme.dart:121-128`），命名與 brightness 設定不一致，未來切換系統深色模式容易出現反差。
- Console 的 Noto 字型 warning 表示字型 fallback 不完整；中文、emoji、特殊符號需補 asset 或明確 fallback font family。

## 5. 孤兒路由與畫面

### 已可達、非孤兒

- `/coin-store`：Home 金幣 capsule、緊急教練缺金幣流程可達。
- `/keyboard-guide`：Home/Profile/Settings 可達。

### 路由已註冊但沒有產品入口

| Route | 建議 |
|---|---|
| `/character-market` | 接到「我的／個人化」；若本季不做 persona，先隱藏 route。 |
| `/create-persona` | 從角色市場接回，否則暫緩，不要留死入口。 |
| `/package-store` | 接到情境包/付費牆，明確說明是內容包還是訂閱。 |
| `/achievements` | 接到個人頁，只有有完整進度與獎勵時才曝光。 |
| `/seasonal-packages` | 只有有可購買活動時才曝光，平時移除入口。 |
| `/referral` | 買量前應接回，並連結 `recordReferral()` 與分享成功頁；否則先 deferred。 |
| `/emergency` | 從 Home 的「情感老師」或情境入口接回，並先修 B1。 |

### 只有 class、沒有 import/導航呼叫的畫面

`OpenerView`、`ChatAnalysisView`、`DateInvitationView`、`ArgumentResolveView`、`GreetingsView`、`TranslateReplyView`、`TopicSuggestionsView`、`TimingCoachView`、`CultureTipsView`、`ShareSuccessView`、`OnboardingTryView`、`EmojiSuggesterView`、`ReplyScorerView`。

建議優先接回：`OpenerView`、`ChatAnalysisView`、`TranslateReplyView`、`ArgumentResolveView`、`GreetingsView`、`DateInvitationView`、`ReplyScorerView`、`TimingCoachView`、`EmojiSuggesterView`。這些直接支援「貼訊息→得到可用回覆」的核心付費價值。`TopicSuggestionsView`、`CultureTipsView` 可等國際化後再接；`OnboardingTryView` 應在 onboarding 決策後接；`ShareSuccessView` 應由分享流程接回，不應單獨曝光。

### Deep link 潛在錯誤

`lib/services/deep_link_service.dart:65-74` 會導向 `/opener`、`/paywall`、`/analysis`，但 `main.dart:228-237` 沒有這三個 named routes。現在 `DeepLinkService.init()` 仍是 TODO、`routeIfPending` 未在啟動流程呼叫，所以尚未在本次預覽中觸發；一旦接上 deep link，未知 route 會造成導航錯誤。應改成直接 push widget 或註冊 route 後再開 attribution。

## 6. 真機驗收未完成項

Web 預覽不能證明以下項目，不能用 Web pass 代替：

1. iOS 鍵盤 extension 是否安裝、啟用「完整取用」、在 LINE/Instagram/iMessage 讀取剪貼簿並生成回覆。
2. 週／年／永久三個 Sandbox 商品的實際付款、取消、付款失敗與 loading 狀態。
3. 同一 Apple ID 刪除重裝後，未按恢復購買是否不應自動解鎖；按「恢復購買」後是否正確解鎖。
4. Android keystore signing、Android 鍵盤權限與付款替代方案。
5. 購買成功後立刻關閉 paywall 的競態（B2）與鍵盤 extension 收到 subscription bridge 的狀態。

## 7. 修復順序與重新驗收 gate

### Gate 0（未通過即停止放量）

1. B1：AI 失敗不扣金幣。
2. B2：購買狀態由服務層原子同步，關閉 paywall 不丟失 entitlement。
3. B3：免費金幣 claim 去重與後端/本機持久化限制。

### Gate 1（P1，修完再上 TestFlight）

B4 timeout、B6 lifecycle 額度、B8 初始化遙測、B9 入口/推薦、B10 固定盲盒結果、B11 空白輸入、B12 平台 fallback、B13 後端重模型 quota、B14 最小 i18n；同時修正 Profile 文案與金幣商店 UI。

### Gate 2（P2 與品質）

B15–B19、字型 asset、theme 命名/brightness、320px/大字體/深色模式與 console clean-up。

### 最終重新驗收順序

1. `flutter analyze`、`flutter test`、`flutter build web --release`。
2. 重新產出 iOS TestFlight build 與 Android signed build（不要沿用 Build 52 作為修正後版本）。
3. TestFlight 實機：鍵盤完整取用 → LINE/IG/iMessage → 三種商品 → 取消/失敗 → 刪除重裝 → 恢復購買。
4. 以新 build number、RevenueCat customer info、Worker usage log 三方核對 entitlement 與 API quota。
5. 通過後才批准買量；任何付款或 entitlement mismatch 都停止放量。

## 8. 本次產物

截圖位於 `C:\Users\AsusGaming\ai_love_keyboard\qa_screenshots\`：

`01_home.png`、`02_blind_box.png`、`03_messages.png`、`04_profile.png`、`05_paywall.png`、`06_coin_store.png`、`07_keyboard_guide.png`、`08_settings.png`、`09_ai_reply.png`、`10_home_320.png`、`11_paywall_320.png`、`12_coin_before_claim.png`、`13_coin_after_claim_1.png`、`14_coin_after_claim_2.png`。

本報告前半段記錄的是修正前基線；後續已在同一工作階段另開修正輪次。修正輪次變更了 `lib/`、Worker 與 Android keyboard request headers，故本報告的 P0 結論需以以下補充為準。

## 9. 2026-07-11 修正輪次補充

- B1：`EmergencyCoachView` 現在只在非空 AI 結果後扣金幣，失敗顯示「未扣金幣」，並加入分析中的重複點擊 guard。
- B2：購買／恢復購買先持久化 `UsageService` entitlement，再檢查 paywall 是否仍 mounted，修正關閉 paywall 的競態。
- B3：免費金幣包加入本機持久化的一次性 claim 與 in-flight guard；這能阻止重複點擊，但刪除重裝後仍需帳號／後端 claim ledger 才能完全防刷。
- Worker：不再使用 body `user_id` 作為免費 quota 身份；新增免費 IP 每日 60 次、Pro IP 每日 1,000 次、請求 timestamp/nonce/signature freshness 與 KV replay guard；新增 `REQUIRE_ACTIVE_PRO` 開關，預設 `false` 以保留每日 3 次免費額度。
- Android keyboard：開始送出同一組 request metadata，為日後啟用 `REQUIRE_REQUEST_METADATA` 做準備。
- 新增 `test/coin_service_test.dart`，驗證免費金幣包並行點擊只有一次成功，且重載後仍保留 claim 狀態。

修正後驗證：`flutter analyze` 通過、`flutter test` 通過（4 tests）、Worker `node --check` 通過、Wrangler dry-run 通過、Web release build 通過。Android APK 尚未能在本機編譯，原因是環境沒有 Android SDK；仍需在具備 SDK 的 CI/工作站驗證。

目前仍未完成：登入帳號、Apple App Attest、Android Play Integrity、跨平台 RevenueCat identity，以及將 `REQUIRE_ACTIVE_PRO` 切換為 `true`。因此仍不能宣稱「只有購買者」已在正式環境生效；目前是「Pro server-side 驗證＋受限免費額度＋可切換付費限定」。
