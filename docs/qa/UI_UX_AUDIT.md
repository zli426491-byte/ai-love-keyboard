# LoveKey UI／UX 檢查報告

## 已執行覆蓋

- iPhone SE 尺寸首頁與底部導覽。
- onboarding 鍵盤選項與大字體。
- 鍵盤新版「每次生成一則」教學文案。
- Paywall 在小高度裝置的捲動。
- 帳號頁狀態。
- 設定頁所有操作項目。
- 首次啟動隱私權提示。
- Codemagic iOS 26.4.1 Simulator 正常 App 截圖。

UI／Widget 專項結果：11/11 通過。

## 已重現並修復

1. 320px 寬度底部導覽右側 overflow：改用 Expanded 分配。
2. onboarding 大字體選項 overflow：文字使用 Expanded、單行與 ellipsis。
3. 小高度 Paywall 內容無法完整存取：改為可捲動。
4. 會員卡垂直 overflow：調整約束與內容排版。
5. 個人頁選單橫向 overflow：調整可用寬度。
6. 首次隱私權提示在小裝置 overflow：增加可捲動與安全間距。
7. 設定頁互動卡片缺少 Material ancestor：加入 Material 並補回歸測試。

## 設計邊界

本輪只修正客觀的 overflow、clipping、捲動、可點擊性與狀態顯示，不改品牌、主導覽、定價或主觀視覺方向。

## 狀態檢查

- Paywall 在非商店／測試環境有明確「產品尚未載入」狀態。
- 帳號頁能顯示已設定或不可用狀態。
- 鍵盤教學已描述「複製、切鍵盤、選模式／語氣、生成一則、填入」流程。
- 隱私權提示可在小畫面閱讀與同意。

## 尚未驗證

- 實體 iPhone 上的第三方鍵盤高度、閃爍與 host app 遮擋。
- LINE、Instagram、iMessage 的真實填入體驗。
- VoiceOver 原生順序與標籤。
- Dynamic Type 極大字級。
- 真正深色主題；目前系統深色下仍使用淺色設計。
- iPad 各方向與分割畫面。
