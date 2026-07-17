import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:ai_love_keyboard/models/ai_reply.dart';
import 'package:ai_love_keyboard/models/chat_analysis.dart';
import 'package:ai_love_keyboard/models/chat_persona.dart';
import 'package:ai_love_keyboard/models/reply_style.dart';
import 'package:ai_love_keyboard/services/api_proxy_service.dart';
import 'package:ai_love_keyboard/services/ai_response_parser.dart';
import 'package:ai_love_keyboard/services/content_filter.dart';
import 'package:ai_love_keyboard/services/privacy_manager.dart';
import 'package:ai_love_keyboard/services/prompt_templates.dart';
import 'package:ai_love_keyboard/services/reply_quality_validator.dart';
import 'package:ai_love_keyboard/utils/constants.dart';

class AiService extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<AiReply> _replies = [];
  ChatAnalysis? _chatAnalysis;
  List<Map<String, String>> _openers = [];
  List<Map<String, String>> _topics = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AiReply> get replies => _replies;
  ChatAnalysis? get chatAnalysis => _chatAnalysis;
  List<Map<String, String>> get openers => _openers;
  List<Map<String, String>> get topics => _topics;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  final ContentFilter _contentFilter = ContentFilter.instance;
  final PrivacyManager _privacyManager = PrivacyManager.instance;

  /// The last content filter result (exposed for UI to show warnings).
  ContentFilterResult? lastFilterResult;

  /// Runs content filter on input, strips PII, and returns sanitized text.
  /// Throws if content is blocked.
  String _sanitizeInput(String text) {
    // 1. Content filter check
    final filterResult = _contentFilter.checkInput(text);
    if (!filterResult.isAllowed) {
      lastFilterResult = filterResult;
      throw ContentBlockedException(filterResult);
    }
    // 2. Strip PII
    return _privacyManager.stripPii(text);
  }

  /// Runs content filter on AI output. Returns safe content or throws.
  String _sanitizeOutput(String text) {
    final filterResult = _contentFilter.checkOutput(text);
    if (!filterResult.isAllowed) {
      lastFilterResult = filterResult;
      // Return safe replacement instead of throwing for output
      return filterResult.filteredContent ?? '抱歉，此回覆內容不適當，請重新嘗試。';
    }
    return text;
  }

  // ── Model Tier Tracking ───────────────────────────────────────────────
  /// The Worker is the authority for heavy-model limits. A client-side
  /// counter can be reset by restarting or reinstalling the app and would
  /// therefore create a false sense of protection.
  bool _canUseHeavyModel(bool useHeavy) => useHeavy;

  /// Calls the backend AI proxy and returns the parsed JSON response.
  Future<Map<String, dynamic>> _callGpt(
    String systemPrompt,
    String userMessage, {
    bool useHeavyModel = false,
    double temperature = 0.8,
  }) async {
    try {
      // Prepend safety prefix to system prompt
      final safeSystemPrompt = PromptTemplates.withSafety(systemPrompt);

      // Sanitize user input
      final sanitizedMessage = _sanitizeInput(userMessage);

      // Record data sent
      _privacyManager.recordDataSent(
        feature: 'ai_proxy_json',
        characterCount: sanitizedMessage.length,
      );

      final response = await ApiProxyService.instance.chatCompletion(
        systemPrompt: safeSystemPrompt,
        userMessage: sanitizedMessage,
        maxTokens: 1024,
        temperature: temperature,
        useHeavyModel: _canUseHeavyModel(useHeavyModel),
        responseFormatJson: true,
      );

      if (response.statusCode != 200) {
        throw Exception(_proxyErrorMessage(response));
      }

      final content = AiResponseParser.extractContent(response.body);

      // Filter AI output
      final safeContent = _sanitizeOutput(content);

      return AiResponseParser.decodeJsonObject(safeContent);
    } on ContentBlockedException {
      rethrow;
    } on FormatException {
      throw Exception('AI 回覆格式錯誤，請重試');
    } on http.ClientException {
      throw Exception('網路連線失敗，請檢查網路狀態');
    }
  }

  /// Calls the backend AI proxy and returns the raw text response.
  Future<String> _callGptText(
    String systemPrompt,
    String userMessage, {
    bool useHeavyModel = false,
    int maxTokens = 1024,
  }) async {
    try {
      // Prepend safety prefix to system prompt
      final safeSystemPrompt = PromptTemplates.withSafety(systemPrompt);

      // Sanitize user input
      final sanitizedMessage = _sanitizeInput(userMessage);

      // Record data sent
      _privacyManager.recordDataSent(
        feature: 'ai_proxy_text',
        characterCount: sanitizedMessage.length,
      );

      final response = await ApiProxyService.instance.chatCompletion(
        systemPrompt: safeSystemPrompt,
        userMessage: sanitizedMessage,
        maxTokens: maxTokens,
        temperature: 0.8,
        useHeavyModel: _canUseHeavyModel(useHeavyModel),
      );

      if (response.statusCode != 200) {
        throw Exception(_proxyErrorMessage(response));
      }

      final content = AiResponseParser.extractContent(response.body);

      // Filter AI output
      return _sanitizeOutput(content.trim());
    } on ContentBlockedException {
      rethrow;
    } on http.ClientException {
      throw Exception('網路連線失敗，請檢查網路狀態');
    }
  }

  // ── Generate Replies ──────────────────────────────────────────────────
  Future<List<AiReply>> generateReplies(
    String message,
    ReplyStyle style, {
    ChatPersona? persona,
    int? intimacyLevel,
    String? genderPrompt,
    String? platform,
    String? goal,
    String? generationInstruction,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      if (kIsWeb && AppConstants.aiProxyBaseUrl.trim().isEmpty) {
        _replies = [
          AiReply(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            text: _webPreviewReplyFor(
              message,
              style,
              platform: platform,
              goal: goal,
            ),
            style: style,
          ),
        ];
        _setLoading(false);
        return _replies;
      }

      final String? personaPrompt = persona?.toPromptString();
      final safeIntimacyLevel = intimacyLevel == null
          ? null
          : (intimacyLevel - 1)
                .clamp(0, IntimacyLevel.levels.length - 1)
                .toInt();
      final String? intimacyPrompt = safeIntimacyLevel == null
          ? null
          : IntimacyLevel.levels[safeIntimacyLevel].promptHint;

      final systemPrompt = PromptTemplates.replyGeneration(
        style.label,
        platform: platform,
        goal: goal,
        personaPrompt: personaPrompt,
        intimacyPrompt: intimacyPrompt,
        genderPrompt: genderPrompt,
      );
      final instruction = generationInstruction?.trim();
      final userPrompt = instruction == null || instruction.isEmpty
          ? '對方的訊息：「$message」'
          : '對方的訊息：「$message」\n重新生成要求：$instruction';
      final result = await _callGpt(
        systemPrompt,
        userPrompt,
        temperature: 0.65,
      );

      final rawReplies = result['replies'] ?? result['reply'];
      final repliesList = rawReplies is List
          ? rawReplies
          : rawReplies is String
          ? <dynamic>[rawReplies]
          : const <dynamic>[];
      _replies = repliesList
          .map((raw) {
            if (raw is String) return raw.trim();
            if (raw is Map && raw['text'] is String) {
              return (raw['text'] as String).trim();
            }
            return '';
          })
          .where(ReplyQualityValidator.isUsable)
          .take(1)
          .map(
            (text) => AiReply(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              text: text,
              style: style,
            ),
          )
          .toList();

      _setLoading(false);
      return _replies;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return [];
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return [];
    }
  }

  String _proxyErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final error = body is Map<String, dynamic> ? body['error'] : null;
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
      if (error is String && error.trim().isNotEmpty) {
        return switch (error) {
          'server_not_configured' => 'AI 服務尚未設定，請稍後再試。',
          'quota_exceeded' => '今日 AI 使用額度已達上限，請明天再試。',
          'active_subscription_required' => '此功能需要有效會員，請先完成訂閱或恢復購買。',
          'auth_required' => '請先登入 LoveKey 帳號。',
          'auth_invalid' ||
          'invalid_auth' ||
          'invalid_token' => '登入狀態已失效，請重新登入。',
          'auth_not_configured' || 'auth_unavailable' => '帳號驗證服務暫時無法使用。',
          'identity_mismatch' => '帳號身份不一致，請重新登入。',
          'rate_limited' => '請求太頻繁，稍等一下再試。',
          'replayed_request' ||
          'stale_request' ||
          'invalid_request_metadata' => '請重新操作一次。',
          'missing_message' || 'missing_fields' => '請先貼上對方訊息。',
          'ai_failed' || 'empty_reply' => 'AI 回覆暫時失敗，請稍後再試。',
          _ => 'AI 服務暫時無法使用，請稍後再試。',
        };
      }
    } catch (_) {
      // Fall through to the generic status message.
    }
    return '伺服器錯誤 (${response.statusCode})';
  }

  String _friendlyError(Object error) {
    if (error is ContentBlockedException) {
      return error.filterResult.reason ?? '內容已被安全過濾器攔截';
    }
    if (error is FormatException) return 'AI 回覆格式暫時無法解析，請再試一次';
    if (error is http.ClientException) return '網路連線失敗，請檢查網路後再試一次';
    final message = error.toString();
    if (message.contains('逾時') || message.contains('timeout')) {
      return 'AI 請求逾時，請稍後再試一次';
    }
    if (message.contains('quota_exceeded') || message.contains('額度')) {
      return '今日 AI 使用額度已達上限，請明天再試';
    }
    if (message.contains('auth_required') || message.contains('登入')) {
      return '請先登入 LoveKey 帳號';
    }
    return 'AI 暫時無法回覆，請稍後再試一次';
  }

  String _webPreviewReplyFor(
    String message,
    ReplyStyle style, {
    String? platform,
    String? goal,
  }) {
    final lower = message.toLowerCase();
    final tired =
        message.contains('累') ||
        lower.contains('tired') ||
        lower.contains('busy');
    final casual =
        message.contains('隨便') ||
        message.contains('都可以') ||
        lower.contains('whatever');

    if (goal == '安慰') {
      return '聽起來你今天真的不容易，先不用急著回，休息一下再聊。';
    }
    if (goal == '道歉') {
      return '如果我剛剛讓你不舒服，先跟你說聲抱歉，我想聽你怎麼想。';
    }
    if (goal == '邀約') {
      return platform == 'IG' ? '這個可以改天一起去，你哪天比較方便？' : '那找個你方便的時間，一起吃個飯聊聊？';
    }

    if (tired) {
      return switch (style) {
        ReplyStyle.humorous => '那今天先省電模式，我陪你慢慢放鬆。',
        ReplyStyle.romantic || ReplyStyle.flirty => '辛苦了，先休息，晚點我再陪你聊。',
        ReplyStyle.cool => '先休息吧，晚點有精神再說。',
        _ => '辛苦了，先別硬撐，回家好好休息。',
      };
    }

    if (casual) {
      return switch (style) {
        ReplyStyle.humorous => '那我負責決定，你負責給我加分。',
        ReplyStyle.romantic || ReplyStyle.flirty => '那我安排一個你會喜歡的，別偷笑。',
        ReplyStyle.cool => '好，我來決定，你等著出現就好。',
        _ => '好，那我來安排一個輕鬆一點的。',
      };
    }

    return switch (style) {
      ReplyStyle.humorous => '這句我先接住，等等讓你笑一下。',
      ReplyStyle.romantic || ReplyStyle.flirty => '我想認真回你，因為這句我有放在心上。',
      ReplyStyle.cool => '收到，我想一下怎麼回比較剛好。',
      ReplyStyle.cute => '好，我先乖乖接住這句。',
      _ => '我懂你的意思，先讓我好好回你。',
    };
  }

  // ── Preview Persona Reply ──────────────────────────────────────────────
  Future<String?> previewPersonaReply({
    required ChatPersona persona,
    required String sampleMessage,
  }) async {
    try {
      final systemPrompt = PromptTemplates.personaPreview(
        persona.toPromptString(),
      );
      final content = await _callGptText(
        systemPrompt,
        '對方的訊息：「$sampleMessage」',
      );
      return content;
    } on ContentBlockedException catch (e) {
      throw Exception(e.filterResult.reason ?? '內容已被安全過濾器攔截');
    } catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  // ── Analyze Chat ──────────────────────────────────────────────────────
  Future<ChatAnalysis?> analyzeChat(String chatLog) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _callGpt(
        PromptTemplates.chatAnalysis,
        '以下是聊天紀錄：\n$chatLog',
        useHeavyModel: true,
      );

      _chatAnalysis = ChatAnalysis.fromJson(result);
      _setLoading(false);
      return _chatAnalysis;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return null;
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return null;
    }
  }

  // ── Generate Openers ──────────────────────────────────────────────────
  Future<List<Map<String, String>>> generateOpeners(String context) async {
    _setLoading(true);
    _setError(null);

    try {
      final userMsg = context.isEmpty ? '請生成通用的破冰開場白' : '對方的資訊：$context';

      final result = await _callGpt(PromptTemplates.openerGeneration, userMsg);

      final openersList = result['openers'] as List<dynamic>;
      _openers = openersList
          .map(
            (o) => (o as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v.toString()),
            ),
          )
          .toList();

      _setLoading(false);
      return _openers;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return [];
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return [];
    }
  }

  // ── Interpret Message ──────────────────────────────────────────────────
  Future<String?> interpretMessage(String message) async {
    _setLoading(true);
    _setError(null);

    try {
      final content = await _callGptText(
        PromptTemplates.messageInterpreter,
        '對方傳的訊息：「$message」',
      );

      _setLoading(false);
      return content;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return null;
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return null;
    }
  }

  // ── Translate and Reply ───────────────────────────────────────────────
  Future<Map<String, String>?> translateAndReply(
    String message,
    String style,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _callGpt(
        PromptTemplates.translateReply(style),
        '對方的外語訊息：「$message」',
      );

      _setLoading(false);
      return {
        'translation': (result['translation'] ?? '').toString(),
        'reply': (result['reply'] ?? '').toString(),
      };
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return null;
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return null;
    }
  }

  // ── Analyze Timing ──────────────────────────────────────────────────
  Future<String?> analyzeTiming(String chatLog) async {
    _setLoading(true);
    _setError(null);

    try {
      final content = await _callGptText(
        PromptTemplates.timingAnalysis,
        '以下是聊天紀錄：\n$chatLog',
        useHeavyModel: true,
      );

      _setLoading(false);
      return content;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return null;
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return null;
    }
  }

  // ── Suggest Emojis ──────────────────────────────────────────────────
  Future<List<Map<String, String>>> suggestEmojis(String message) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _callGpt(
        PromptTemplates.emojiSuggestion,
        '訊息內容：「$message」',
      );

      final emojiList = result['emojis'] as List<dynamic>;
      final suggestions = emojiList
          .map(
            (e) => (e as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v.toString()),
            ),
          )
          .toList();

      _setLoading(false);
      return suggestions;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return [];
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return [];
    }
  }

  // ── Generate Date Invitation ────────────────────────────────────────
  Future<List<Map<String, String>>> generateDateInvitation(
    String context,
    String style,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _callGpt(
        PromptTemplates.dateInvitation(style),
        '對方的資訊：$context',
      );

      final invitationList = result['invitations'] as List<dynamic>;
      final invitations = invitationList
          .map(
            (e) => (e as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v.toString()),
            ),
          )
          .toList();

      _setLoading(false);
      return invitations;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return [];
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return [];
    }
  }

  // ── Resolve Argument ────────────────────────────────────────────────
  Future<String?> resolveArgument(String chatLog, String tone) async {
    _setLoading(true);
    _setError(null);

    try {
      final content = await _callGptText(
        PromptTemplates.argumentResolution(tone),
        '以下是吵架紀錄：\n$chatLog',
        useHeavyModel: true,
      );

      _setLoading(false);
      return content;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return null;
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return null;
    }
  }

  // ── Generate Greetings ──────────────────────────────────────────────
  Future<List<String>> generateGreetings(String type, String style) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _callGpt(
        PromptTemplates.greetingsGeneration(type, style),
        '請生成 5 個$type問候語',
      );

      final greetingsList = result['greetings'] as List<dynamic>;
      final greetings = greetingsList.map((g) => g.toString()).toList();

      _setLoading(false);
      return greetings;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return [];
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return [];
    }
  }

  // ── Emergency Coach Analysis ─────────────────────────────────────────
  Future<String?> analyzeEmergency(String chatLog) async {
    _setLoading(true);
    _setError(null);

    try {
      final content = await _callGptText(
        PromptTemplates.emergencyCoach,
        '以下是完整的聊天紀錄，請深度分析：\n\n$chatLog',
        useHeavyModel: true,
        maxTokens: 2048,
      );

      _setLoading(false);
      return content;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return null;
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return null;
    }
  }

  // ── Score Reply ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> scoreReply(
    String theirMessage,
    String yourReply,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _callGpt(
        PromptTemplates.replyScoring,
        '對方的訊息：「$theirMessage」\n你的回覆：「$yourReply」',
        useHeavyModel: true,
      );

      _setLoading(false);
      return result;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return null;
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return null;
    }
  }

  // ── Suggest Topics ────────────────────────────────────────────────────
  Future<List<Map<String, String>>> suggestTopics(String recentChat) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _callGpt(
        PromptTemplates.topicSuggestions,
        '最近的聊天內容：\n$recentChat',
      );

      final topicsList = result['topics'] as List<dynamic>;
      _topics = topicsList
          .map(
            (t) => (t as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v.toString()),
            ),
          )
          .toList();

      _setLoading(false);
      return _topics;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return [];
    } catch (e) {
      _setError(_friendlyError(e));
      _setLoading(false);
      return [];
    }
  }
}

/// Exception thrown when the content filter blocks a request.
class ContentBlockedException implements Exception {
  final ContentFilterResult filterResult;
  const ContentBlockedException(this.filterResult);

  @override
  String toString() =>
      'ContentBlockedException: ${filterResult.reason ?? "Content blocked"}';
}
