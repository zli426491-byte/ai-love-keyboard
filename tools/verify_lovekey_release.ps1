param(
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

function Step($message) {
  Write-Host ""
  Write-Host "==> $message" -ForegroundColor Cyan
}

function Require-File($path, $name) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "$name not found: $path"
  }
}

$repo = Split-Path -Parent $PSScriptRoot
$flutter = "C:\Users\AsusGaming\flutter-sdk\bin\flutter.bat"
$npx = "C:\Program Files\nodejs\npx.cmd"

Set-Location $repo
Require-File $flutter "Flutter"

Step "Flutter analyze"
& $flutter analyze

Step "Flutter test"
& $flutter test

if (-not $SkipBuild) {
  Step "Flutter web release build"
  & $flutter build web --release
}

Step "Sensitive key scan"
$secretPattern = "sk-[A-Za-z0-9_-]{20,}|cfat_[A-Za-z0-9_-]{20,}|OPENAI_API_KEY\s*=\s*['""]|appl_[A-Za-z0-9]{20,}|YOUR_FACEBOOK|YOUR_ADJUST|YOUR_TIKTOK"
$scanFiles = & rg --files `
  -g "!cloudflare-worker/README.md" `
  -g "!cloudflare-worker/.dev.vars" `
  -g "!cloudflare-worker/.wrangler/**" `
  -- `
  "lib" `
  "ios" `
  "android" `
  "cloudflare-worker" `
  ".github"

$secretMatches = @()
foreach ($file in $scanFiles) {
  $matches = Select-String -LiteralPath $file -Pattern $secretPattern -AllMatches
  if ($matches) {
    $secretMatches += $matches
  }
}
if ($secretMatches.Count -gt 0) {
  $secretMatches | ForEach-Object { Write-Host "$($_.Path):$($_.LineNumber):$($_.Line)" }
  throw "Potential secret or placeholder found. Fix before release."
}
Write-Host "No obvious client-side API secrets or tracking placeholders found." -ForegroundColor Green

Step "iOS subscription and App Group wiring"
$runnerEntitlements = Join-Path $repo "ios\Runner\Runner.entitlements"
$keyboardEntitlements = Join-Path $repo "ios\LoveKeyboard\LoveKeyboard.entitlements"
$keyboardSource = Join-Path $repo "ios\LoveKeyboard\KeyboardViewController.swift"
$projectFile = Join-Path $repo "ios\Runner.xcodeproj\project.pbxproj"
$releaseWorkflow = Join-Path $repo ".github\workflows\ios-release.yml"

Require-File $runnerEntitlements "Runner entitlements"
Require-File $keyboardEntitlements "LoveKeyboard entitlements"
Require-File $keyboardSource "LoveKeyboard source"
Require-File $projectFile "Xcode project"
Require-File $releaseWorkflow "iOS release workflow"

$appGroup = "group.com.ailovekeyboard.app"
foreach ($path in @($runnerEntitlements, $keyboardEntitlements)) {
  if (-not (Select-String -LiteralPath $path -SimpleMatch $appGroup -Quiet)) {
    throw "Missing LoveKey App Group in $path"
  }
}
if (Select-String -LiteralPath $keyboardSource -SimpleMatch '"is_pro": true' -Quiet) {
  throw "LoveKeyboard must not hard-code paid entitlement."
}
if (-not (Select-String -LiteralPath $keyboardSource -SimpleMatch '"is_pro": SharedConfig.isPro' -Quiet)) {
  throw "LoveKeyboard paid entitlement is not sourced from the shared App Group."
}
$entitlementWiring = @(Select-String -LiteralPath $projectFile -SimpleMatch "CODE_SIGN_ENTITLEMENTS")
if ($entitlementWiring.Count -lt 6) {
  throw "Runner and LoveKeyboard build configurations are missing entitlement wiring."
}
if (-not (Select-String -LiteralPath $releaseWorkflow -SimpleMatch 'secrets.REVENUECAT_IOS_PUBLIC_KEY' -Quiet)) {
  throw "iOS release workflow does not inject the LoveKey RevenueCat key."
}
Write-Host "Subscription state and App Group wiring are release-gated." -ForegroundColor Green

Step "Backend and Android release gates"
$workerSource = Join-Path $repo "cloudflare-worker\src\index.js"
$androidGradle = Join-Path $repo "android\app\build.gradle.kts"
$androidWorkflow = Join-Path $repo ".github\workflows\android-release.yml"
Require-File $workerSource "Cloudflare Worker source"
Require-File $androidGradle "Android Gradle config"
Require-File $androidWorkflow "Android release workflow"
if (Select-String -LiteralPath $workerSource -SimpleMatch 'isPro = body.is_pro !== false' -Quiet) {
  throw "Worker must not default chat requests to Pro."
}
if (Select-String -LiteralPath $workerSource -SimpleMatch 'Access-Control-Allow-Origin": "*"' -Quiet) {
  throw "Worker CORS policy must not be wildcard."
}
if (-not (Select-String -LiteralPath $workerSource -SimpleMatch 'REVENUECAT_SECRET_API_KEY' -Quiet)) {
  throw "Worker is missing server-side RevenueCat entitlement verification."
}
if (Select-String -LiteralPath $androidGradle -SimpleMatch 'signingConfig = signingConfigs.getByName("debug")' -Quiet) {
  throw "Android release must not use debug signing."
}
foreach ($secret in @('ANDROID_KEYSTORE_BASE64', 'ANDROID_KEYSTORE_PASSWORD', 'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD')) {
  if (-not (Select-String -LiteralPath $androidWorkflow -SimpleMatch "secrets.$secret" -Quiet)) {
    throw "Android release workflow is missing $secret."
  }
}
Write-Host "Worker entitlement, CORS, and Android signing gates passed." -ForegroundColor Green

if (Test-Path -LiteralPath $npx) {
  Step "Cloudflare Worker dry-run"
  Push-Location (Join-Path $repo "cloudflare-worker")
  try {
    & $npx wrangler deploy --dry-run
  } finally {
    Pop-Location
  }
} else {
  Write-Host "Skipping Worker dry-run: npx.cmd not found." -ForegroundColor Yellow
}

Step "Manual checks still required"
Write-Host "- GitHub Secrets: AI_PROXY_URL, REVENUECAT_IOS_PUBLIC_KEY, APP_STORE_CONNECT_API_KEY, APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, CERTIFICATE_PRIVATE_KEY"
Write-Host "- Cloudflare secret: REVENUECAT_SECRET_API_KEY (server-side entitlement verification)"
Write-Host "- Android secrets: ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD"
Write-Host "- Optional ad secrets: FACEBOOK_APP_ID, ADJUST_APP_TOKEN, ADJUST_ENVIRONMENT=production, TIKTOK_PIXEL_ID"
Write-Host "- TestFlight real-device QA: keyboard paste, generate, send, paywall purchase, restore purchase"
Write-Host "- RevenueCat dashboard: default offering has matching weekly/yearly/lifetime products and pro entitlement"

Write-Host ""
Write-Host "LoveKey release verification completed." -ForegroundColor Green
