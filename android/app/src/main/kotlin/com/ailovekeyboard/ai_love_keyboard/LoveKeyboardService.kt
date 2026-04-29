package com.ailovekeyboard.ai_love_keyboard

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.inputmethodservice.InputMethodService
import android.os.Handler
import android.os.Looper
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
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

        val apiKey = getApiKey()
        if (apiKey.isNullOrEmpty()) {
            statusText.text = "請先在 App 中設定 API Key"
            return
        }

        statusText.text = "生成中..."
        replyContainer.removeAllViews()

        executor.execute {
            try {
                val replies = callOpenAI(apiKey, message, selectedStyle)
                mainHandler.post {
                    statusText.text = "點擊回覆即可輸入"
                    showReplies(replies)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    statusText.text = "錯誤: ${e.message}"
                }
            }
        }
    }

    private fun callOpenAI(apiKey: String, message: String, style: String): List<String> {
        val url = URL("https://api.openai.com/v1/chat/completions")
        val conn = url.openConnection() as HttpURLConnection
        conn.requestMethod = "POST"
        conn.setRequestProperty("Content-Type", "application/json")
        conn.setRequestProperty("Authorization", "Bearer $apiKey")
        conn.doOutput = true
        conn.connectTimeout = 15000
        conn.readTimeout = 30000

        val systemPrompt = """你是一位戀愛訊息助手。根據對方傳來的訊息，用「${style}」的風格生成3個不同的回覆建議。
每個回覆要自然、有趣，適合在聊天軟體中發送。
回覆格式：每個回覆用 ||| 分隔，不要加編號或多餘解釋。只輸出回覆內容。"""

        val body = JSONObject().apply {
            put("model", "gpt-4o")
            put("messages", JSONArray().apply {
                put(JSONObject().apply {
                    put("role", "system")
                    put("content", systemPrompt)
                })
                put(JSONObject().apply {
                    put("role", "user")
                    put("content", message)
                })
            })
            put("max_tokens", 500)
            put("temperature", 0.9)
        }

        val writer = OutputStreamWriter(conn.outputStream, "UTF-8")
        writer.write(body.toString())
        writer.flush()
        writer.close()

        if (conn.responseCode != 200) {
            val errorStream = conn.errorStream ?: conn.inputStream
            val error = BufferedReader(InputStreamReader(errorStream, "UTF-8")).readText()
            throw Exception("API ${conn.responseCode}: $error")
        }

        val response = BufferedReader(InputStreamReader(conn.inputStream, "UTF-8")).readText()
        conn.disconnect()

        val json = JSONObject(response)
        val content = json.getJSONArray("choices")
            .getJSONObject(0)
            .getJSONObject("message")
            .getString("content")
            .trim()

        return content.split("|||").map { it.trim() }.filter { it.isNotEmpty() }
    }

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

    private fun getApiKey(): String? {
        // Read from Flutter SharedPreferences (stored via shared_preferences plugin)
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        var key = prefs.getString("flutter.openai_api_key", null)
        if (key == null) {
            // Also try without flutter. prefix
            key = prefs.getString("openai_api_key", null)
        }
        return key
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
