import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:ai_love_keyboard/models/ai_reply.dart';
import 'package:ai_love_keyboard/models/chat_analysis.dart';
import 'package:ai_love_keyboard/models/reply_style.dart';
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

  Future<Map<String, dynamic>> _callClaude(
      String systemPrompt, String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.claudeApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': AppConstants.claudeApiKey,
          'anthropic-version': AppConstants.claudeApiVersion,
        },
        body: jsonEncode({
          'model': AppConstants.claudeModel,
          'max_tokens': 1024,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['error']?['message'] ?? '伺服器錯誤 (${response.statusCode})',
        );
      }

      final body = jsonDecode(response.body);
      final content = body['content'][0]['text'] as String;

      // Extract JSON from the response (handle possible markdown wrapping)
      String jsonStr = content.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'^```\w*\n?'), '');
        jsonStr = jsonStr.replaceAll(RegExp(r'\n?```$'), '');
      }

      return jsonDecode(jsonStr.trim()) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('AI 回覆格式錯誤，請重試');
    } on http.ClientException {
      throw Exception('網路連線失敗，請檢查網路狀態');
    }
  }

  // ── Generate Replies ──────────────────────────────────────────────────
  Future<List<AiReply>> generateReplies(
      String message, ReplyStyle style) async {
    _setLoading(true);
    _setError(null);

    try {
      final systemPrompt =
          PromptTemplates.replyGeneration(style.label);
      final result = await _callClaude(systemPrompt, '對方的訊息：「$message」');

      final repliesList = result['replies'] as List<dynamic>;
      _replies = repliesList
          .map((r) => AiReply.fromJson(r as Map<String, dynamic>, style))
          .toList();

      _setLoading(false);
      return _replies;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return [];
    }
  }

  // ── Analyze Chat ──────────────────────────────────────────────────────
  Future<ChatAnalysis?> analyzeChat(String chatLog) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _callClaude(
          PromptTemplates.chatAnalysis, '以下是聊天紀錄：\n$chatLog');

      _chatAnalysis = ChatAnalysis.fromJson(result);
      _setLoading(false);
      return _chatAnalysis;
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

      final result = await _callClaude(
          PromptTemplates.openerGeneration, userMsg);

      final openersList = result['openers'] as List<dynamic>;
      _openers = openersList
          .map((o) => (o as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v.toString())))
          .toList();

      _setLoading(false);
      return _openers;
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
      final response = await http.post(
        Uri.parse(AppConstants.claudeApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': AppConstants.claudeApiKey,
          'anthropic-version': AppConstants.claudeApiVersion,
        },
        body: jsonEncode({
          'model': AppConstants.claudeModel,
          'max_tokens': 1024,
          'system': PromptTemplates.messageInterpreter,
          'messages': [
            {'role': 'user', 'content': '對方傳的訊息：「$message」'},
          ],
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['error']?['message'] ?? '伺服器錯誤 (${response.statusCode})',
        );
      }

      final body = jsonDecode(response.body);
      final content = body['content'][0]['text'] as String;

      _setLoading(false);
      return content.trim();
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
      final result = await _callClaude(
          PromptTemplates.topicSuggestions, '最近的聊天內容：\n$recentChat');

      final topicsList = result['topics'] as List<dynamic>;
      _topics = topicsList
          .map((t) => (t as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v.toString())))
          .toList();

      _setLoading(false);
      return _topics;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return [];
    }
  }
}
