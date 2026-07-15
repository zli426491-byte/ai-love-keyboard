package com.ailovekeyboard.ai_love_keyboard

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.inputmethodservice.InputMethodService
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.*
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.security.SecureRandom
import java.util.concurrent.Executors

class LoveKeyboardService : InputMethodService() {

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var selectedStyle = "幽默"
    private lateinit var inputField: EditText
    private lateinit var replyContainer: LinearLayout
    private lateinit var statusText: TextView
    private var styleButtons = mutableListOf<Button>()

    // Theme colors
    private val colorBgDark = Color.parseColor("#1A1128")
    private val colorPurple = Color.parseColor("#7C3AED")
    private val colorPurpleLight = Color.parseColor("#A78BFA")
    private val colorMint = Color.parseColor("#2DD4BF")
    private val colorSurface = Color.parseColor("#2D2040")
    private val colorTextPrimary = Color.parseColor("#F3E8FF")
    private val colorTextSecondary = Color.parseColor("#C4B5D0")

    override fun onCreateInputView(): View {
        val root = ScrollView(this).apply {
            setBackgroundColor(colorBgDark)
            isFillViewport = true
        }

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(12), dp(8), dp(12), dp(8))
        }
        root.addView(container)

        // -- Top bar: title + switch keyboard button --
        val topBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        topBar.addView(TextView(this@LoveKeyboardService).apply {
            text = "💕 AI 戀愛鍵盤"
            setTextColor(colorMint)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        })
        topBar.addView(makeSmallButton("切換鍵盤") {
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            imm.showInputMethodPicker()
        })
        container.addView(topBar)

        // -- Input field for pasting received message --
        inputField = EditText(this).apply {
            hint = "貼上對方的訊息..."
            setHintTextColor(colorTextSecondary)
            setTextColor(colorTextPrimary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            background = makeRoundRect(colorSurface, dp(8))
            setPadding(dp(10), dp(8), dp(10), dp(8))
            minLines = 2
            maxLines = 4
        }
        val inputParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = dp(6) }
        container.addView(inputField, inputParams)

        // -- Style buttons row --
        val styleRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        val styles = listOf("幽默", "浪漫", "撩人", "高冷")
        for (style in styles) {
            val btn = Button(this).apply {
                text = style
                setTextColor(if (style == selectedStyle) colorBgDark else colorTextPrimary)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                background = makeRoundRect(
                    if (style == selectedStyle) colorMint else colorSurface, dp(16)
                )
                setPadding(dp(14), dp(4), dp(14), dp(4))
                isAllCaps = false
                setOnClickListener {
                    selectedStyle = style
                    updateStyleButtons()
                }
            }
            val btnParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { marginStart = dp(4); marginEnd = dp(4) }
            styleRow.addView(btn, btnParams)
            styleButtons.add(btn)
        }
        val styleParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = dp(6) }
        container.addView(styleRow, styleParams)

        // -- Generate button --
        val genBtn = Button(this).apply {
            text = "✨ 生成回覆"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            background = makeRoundRect(colorPurple, dp(20))
            setPadding(dp(16), dp(8), dp(16), dp(8))
            isAllCaps = false
            setOnClickListener { generateReply() }
        }
        val genParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = dp(6) }
        container.addView(genBtn, genParams)

        // -- Status text --
        statusText = TextView(this).apply {
            setTextColor(colorTextSecondary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
        }
        val statusParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = dp(2) }
        container.addView(statusText, statusParams)

        // -- Reply cards container --
        replyContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }
        val replyParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = dp(4) }
        container.addView(replyContainer, replyParams)

        return root
    }

    private fun updateStyleButtons() {
        val styles = listOf("幽默", "浪漫", "撩人", "高冷")
        for (i in styleButtons.indices) {
            val btn = styleButtons[i]
            val isSelected = styles[i] == selectedStyle
            btn.setTextColor(if (isSelected) colorBgDark else colorTextPrimary)
            btn.background = makeRoundRect(
                if (isSelected) colorMint else colorSurface, dp(16)
            )
        }
    }

    private fun generateReply() {
        val message = inputField.text.toString().trim()
        if (message.isEmpty()) {
            statusText.text = "請先貼上對方的訊息"
            return
        }

        val proxyUrl = BuildConfig.AI_PROXY_URL.trim().trimEnd('/')
        if (proxyUrl.isEmpty()) {
            statusText.text = "AI Proxy 尚未設定"
            return
        }

        statusText.text = "生成中..."
        replyContainer.removeAllViews()

        executor.execute {
            try {
                val replies = callProxy(proxyUrl, message, selectedStyle)
                mainHandler.post {
                    statusText.text = "點擊回覆即可輸入"
                    showReplies(replies)
                }
            } catch (error: ProxyException) {
                mainHandler.post {
                    statusText.text = error.userMessage
                }
            } catch (_: Exception) {
                mainHandler.post {
                    statusText.text = "AI 暫時無法回覆，請稍後再試"
                }
            }
        }
    }

    private fun callProxy(proxyUrl: String, message: String, style: String): List<String> {
        val url = URL("$proxyUrl/v1/keyboard-reply")
        val conn = url.openConnection() as HttpURLConnection
        conn.requestMethod = "POST"
        conn.setRequestProperty("Content-Type", "application/json")
        val fingerprint = getDeviceFingerprint()
        val timestamp = System.currentTimeMillis().toString()
        val nonceBytes = ByteArray(16).also { SecureRandom().nextBytes(it) }
        val nonce = Base64.encodeToString(nonceBytes, Base64.URL_SAFE or Base64.NO_WRAP)
        val signaturePayload = "$timestamp:$nonce:$fingerprint"
        val signature = Base64.encodeToString(
            signaturePayload.toByteArray(Charsets.UTF_8),
            Base64.URL_SAFE or Base64.NO_WRAP,
        )
        conn.setRequestProperty("X-Device-Fingerprint", fingerprint)
        conn.setRequestProperty("X-Request-Timestamp", timestamp)
        conn.setRequestProperty("X-Request-Nonce", nonce)
        conn.setRequestProperty("X-Request-Signature", signature)
        val sharedPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val accessToken = sharedPrefs.getString("lovekey_account_access_token", null)
            ?.takeIf { it.isNotBlank() }
            ?: throw ProxyException("請先開啟 LoveKey 登入")
        conn.setRequestProperty("Authorization", "Bearer $accessToken")
        conn.doOutput = true
        conn.connectTimeout = 15000
        conn.readTimeout = 30000

        val body = JSONObject().apply {
            put("user_id", getDeviceFingerprint())
            put("message", message)
            put("tone", style)
            put("mode", "接話")
            sharedPrefs.getString("lovekey_revenuecat_app_user_id", null)
                ?.takeIf { it.isNotBlank() }
                ?.let { put("revenuecat_app_user_id", it) }
            // Paid access is verified by the Worker using RevenueCat. Never
            // send a client-controlled Pro flag from the keyboard.
        }

        val writer = OutputStreamWriter(conn.outputStream, "UTF-8")
        writer.write(body.toString())
        writer.flush()
        writer.close()

        val statusCode = conn.responseCode
        if (statusCode != 200) {
            val responseBody = conn.errorStream
                ?.bufferedReader(Charsets.UTF_8)
                ?.use { it.readText() }
                .orEmpty()
            val errorCode = runCatching {
                JSONObject(responseBody).optString("error", "")
            }.getOrDefault("")
            conn.disconnect()
            throw ProxyException(proxyErrorMessage(statusCode, errorCode))
        }

        val response = BufferedReader(InputStreamReader(conn.inputStream, "UTF-8")).readText()
        conn.disconnect()

        val json = JSONObject(response)
        val reply = json.optString("reply", "").trim()
        return if (reply.isNotEmpty()) listOf(reply) else emptyList()
    }

    private fun proxyErrorMessage(statusCode: Int, errorCode: String): String {
        return when (errorCode) {
            "auth_required", "invalid_auth", "invalid_token" ->
                "請先開啟 LoveKey 重新登入"
            "revenuecat_identity_mismatch" -> "請開啟 LoveKey 同步會員"
            "active_subscription_required", "quota_exceeded" ->
                "請先開啟 LoveKey 升級 Pro"
            "rate_limited" -> "請稍候再試"
            "server_not_configured" -> "AI 服務尚未設定"
            else -> when (statusCode) {
                401 -> "請先開啟 LoveKey 重新登入"
                403 -> "請先開啟 LoveKey 升級 Pro"
                429 -> "請稍候再試"
                else -> "AI 暫時不可用"
            }
        }
    }

    private class ProxyException(val userMessage: String) : Exception(userMessage)

    private fun showReplies(replies: List<String>) {
        replyContainer.removeAllViews()
        for (reply in replies) {
            val card = TextView(this).apply {
                text = reply
                setTextColor(colorTextPrimary)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                background = makeRoundRect(colorSurface, dp(10))
                setPadding(dp(12), dp(10), dp(12), dp(10))
                setOnClickListener {
                    currentInputConnection?.commitText(reply, 1)
                    statusText.text = "已輸入 ✓"
                }
            }
            val cardParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = dp(4) }
            replyContainer.addView(card, cardParams)
        }
    }

    private fun getDeviceFingerprint(): String {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val existing = prefs.getString("lovekey_keyboard_user_id", null)
        if (!existing.isNullOrEmpty()) {
            return existing
        }

        val created = java.util.UUID.randomUUID().toString()
        prefs.edit().putString("lovekey_keyboard_user_id", created).apply()
        return created
    }

    private fun makeSmallButton(label: String, onClick: () -> Unit): Button {
        return Button(this).apply {
            text = label
            setTextColor(colorPurpleLight)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            background = makeRoundRect(colorSurface, dp(12))
            setPadding(dp(10), dp(2), dp(10), dp(2))
            isAllCaps = false
            setOnClickListener { onClick() }
        }
    }

    private fun makeRoundRect(color: Int, radius: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = radius.toFloat()
            setColor(color)
        }
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), resources.displayMetrics
        ).toInt()
    }
}
