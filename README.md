# ai_love_keyboard

LoveKey（AI 戀愛鍵盤）— Flutter 主 App + iOS 原生鍵盤 extension。

## 在 Windows 直接看 App 畫面

Windows 沒有 iOS 模擬器，但主 App 的 UI 可以用 Flutter web 在瀏覽器看（畫面與 iOS 版一致）：

- 一鍵：雙擊 `打開LoveKey畫面.bat`（serve `build\web` 到 http://localhost:8765 並自動開瀏覽器）。
- 改過 `lib/` 之後先重 build：`C:\Users\AsusGaming\flutter-sdk\bin\flutter.bat build web --release`（約 35 秒）。
- 開發迭代：`flutter.bat run -d chrome`（hot reload）。
- 限制：iOS 鍵盤本體（`ios\LoveKeyboard\`）是原生 Swift，網頁看不到，只能 TestFlight 實機測；RevenueCat 在非 iOS 平台會自動跳過，網頁版 paywall 不載入真商品屬正常。

完整說明：`C:\Users\AsusGaming\Documents\New project\docs\LOVEKEY_APP_PREVIEW_HOWTO.md`

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
