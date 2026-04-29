import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:ai_love_keyboard/models/ai_reply.dart';
import 'package:ai_love_keyboard/models/chat_analysis.dart';
import 'package:ai_love_keyboard/models/chat_persona.dart';
import 'package:ai_love_keyboard/models/reply_style.dart';
import 'package:ai_love_keyboard/services/content_filter.dart';
import 'package:ai_love_keyboard/services/privacy_manager.dart';
import 'package:ai_love_keyboard/services/prompt_templates.dart';
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
  int _heavyModelUsesToday = 0;
  String _heavyModelLastDate = '';

  /// Returns the appropriate model based on feature tier.
  /// Heavy features (deep analysis) use deepseek-reasoner with daily limit.
  /// Light features (replies, greetings) use deepseek-chat.
  String _getModel(bool useHeavy) {
    if (!useHeavy) return AppConstants.deepSeekModelLight;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_heavyModelLastDate != today) {
      _heavyModelUsesToday = 0;
      _heavyModelLastDate = today;
    }

    if (_heavyModelUsesToday >= AppConstants.heavyModelDailyLimit) {
      // Fallback to light model when heavy limit reached
      return AppConstants.deepSeekModelLight;
    }

    _heavyModelUsesToday++;
    return AppConstants.deepSeekModelHeavy;
  }

  /// Calls DeepSeek API and returns the parsed JSON response.
  Future<Map<String, dynamic>> _callGpt(
      String systemPrompt, String userMessage,
      {bool useHeavyModel = false}) async {
    try {
      // Prepend safety prefix to system prompt
      final safeSystemPrompt = PromptTemplates.withSafety(systemPrompt);

      // Sanitize user input
      final sanitizedMessage = _sanitizeInput(userMessage);

      // Record data sent
      _privacyManager.recordDataSent(
        feature: 'deepseek_json',
        characterCount: sanitizedMessage.length,
      );

      final response = await http.post(
        Uri.parse(AppConstants.deepSeekApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.deepSeekApiKey}',
        },
        body: jsonEncode({
          'model': _getModel(useHeavyModel),
          'messages': [
            {'role': 'system', 'content': safeSystemPrompt},
            {'role': 'user', 'content': sanitizedMessage},
          ],
          'max_tokens': 1024,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['error']?['message'] ?? '伺服器錯誤 (${response.statusCode})',
        );
      }

      final body = jsonDecode(response.body);
      final content =
          body['choices'][0]['message']['content'] as String;

      // Filter AI output
      final safeContent = _sanitizeOutput(content);

      // Extract JSON from the response (handle possible markdown wrapping)
      String jsonStr = safeContent.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'^```\w*\n?'), '');
        jsonStr = jsonStr.replaceAll(RegExp(r'\n?```$'), '');
      }

      return jsonDecode(jsonStr.trim()) as Map<String, dynamic>;
    } on ContentBlockedException {
      rethrow;
    } on FormatException {
      throw Exception('AI 回覆格式錯誤，請重試');
    } on http.ClientException {
      throw Exception('網路連線失敗，請檢查網路狀態');
    }
  }

  /// Calls DeepSeek API and returns the raw text response (no JSON parsing).
  Future<String> _callGptText(
      String systemPrompt, String userMessage,
      {bool useHeavyModel = false, int maxTokens = 1024}) async {
    try {
      // Prepend safety prefix to system prompt
      final safeSystemPrompt = PromptTemplates.withSafety(systemPrompt);

      // Sanitize user input
      final sanitizedMessage = _sanitizeInput(userMessage);

      // Record data sent
      _privacyManager.recordDataSent(
        feature: 'deepseek_text',
        characterCount: sanitizedMessage.length,
      );

      final response = await http.post(
        Uri.parse(AppConstants.deepSeekApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.deepSeekApiKey}',
        },
        body: jsonEncode({
          'model': _getModel(useHeavyModel),
          'messages': [
            {'role': 'system', 'content': safeSystemPrompt},
            {'role': 'user', 'content': sanitizedMessage},
          ],
          'max_tokens': maxTokens,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['error']?['message'] ?? '伺服器錯誤 (${response.statusCode})',
        );
      }

      final body = jsonDecode(response.body);
      final content =
          body['choices'][0]['message']['content'] as String;

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
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final String? personaPrompt = persona?.toPromptString();
      final String? intimacyPrompt = intimacyLevel != null
          ? IntimacyLevel.levels[intimacyLevel - 1].promptHint
          : null;

      final systemPrompt = PromptTemplates.replyGeneration(
        style.label,
        personaPrompt: personaPrompt,
        intimacyPrompt: intimacyPrompt,
        genderPrompt: genderPrompt,
      );
      final result = await _callGpt(systemPrompt, '對方的訊息：「$message」');

      final repliesList = result['replies'] as List<dynamic>;
      _replies = repliesList
          .map((r) => AiReply.fromJson(r as Map<String, dynamic>, style))
          .toList();

      _setLoading(false);
      return _replies;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return [];
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return [];
    }
  }

  // ── Preview Persona Reply ──────────────────────────────────────────────
  Future<String?> previewPersonaReply({
    required ChatPersona persona,
    required String sampleMessage,
  }) async {
    try {
      final systemPrompt =
          PromptTemplates.personaPreview(persona.toPromptString());
      final content =
          await _callGptText(systemPrompt, '對方的訊息：「$sampleMessage」');
      return content;
    } on ContentBlockedException catch (e) {
      throw Exception(e.filterResult.reason ?? '內容已被安全過濾器攔截');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Analyze Chat ──────────────────────────────────────────────────────
  Future<ChatAnalysis?> analyzeChat(String chatLog) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _callGpt(
          PromptTemplates.chatAnalysis, '以下是聊天紀錄：\n$chatLog',
          useHeavyModel: true);

      _chatAnalysis = ChatAnalysis.fromJson(result);
      _setLoading(false);
      return _chatAnalysis;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return null;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return null;
    }
  }

  // ── Generate Openers ──────────────────────────────────────────────────
  Future<List<Map<String, String>>> generateOpeners(String context) async {
    _setLoading(true);
    _setError(null);

    try {
      final userMsg = context.isEmpty
          ? '請生成通用的破冰開場白'
          : '對方的資訊：$context';

      final result = await _callGpt(
          PromptTemplates.openerGeneration, userMsg);

      final openersList = result['openers'] as List<dynamic>;
      _openers = openersList
          .map((o) => (o as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v.toString())))
          .toList();

      _setLoading(false);
      return _openers;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return [];
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
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
          PromptTemplates.messageInterpreter, '對方傳的訊息：「$message」');

      _setLoading(false);
      return content;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return null;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return null;
    }
  }

  // ── Translate and Reply ───────────────────────────────────────────────
  Future<Map<String, String>?> translateAndReply(
      String message, String style) async {
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
      _setError(e.toString().replaceFirst('Exception: ', ''));
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
      _setError(e.toString().replaceFirst('Exception: ', ''));
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
          .map((e) => (e as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v.toString())))
          .toList();

      _setLoading(false);
      return suggestions;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return [];
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return [];
    }
  }

  // ── Generate Date Invitation ────────────────────────────────────────
  Future<List<Map<String, String>>> generateDateInvitation(
      String context, String style) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _callGpt(
        PromptTemplates.dateInvitation(style),
        '對方的資訊：$context',
      );

      final invitationList = result['invitations'] as List<dynamic>;
      final invitations = invitationList
          .map((e) => (e as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v.toString())))
          .toList();

      _setLoading(false);
      return invitations;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return [];
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
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
      _setError(e.toString().replaceFirst('Exception: ', ''));
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
      final greetings =
          greetingsList.map((g) => g.toString()).toList();

      _setLoading(false);
      return greetings;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return [];
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
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
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return null;
    }
  }

  // ── Score Reply ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> scoreReply(
      String theirMessage, String yourReply) async {
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
      _setError(e.toString().replaceFirst('Exception: ', ''));
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
          PromptTemplates.topicSuggestions, '最近的聊天內容：\n$recentChat');

      final topicsList = result['topics'] as List<dynamic>;
      _topics = topicsList
          .map((t) => (t as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v.toString())))
          .toList();

      _setLoading(false);
      return _topics;
    } on ContentBlockedException catch (e) {
      _setError(e.filterResult.reason ?? '內容已被安全過濾器攔截');
      _setLoading(false);
      return [];
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
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
