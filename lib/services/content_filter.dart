import 'package:ai_love_keyboard/data/blocked_keywords.dart';

/// The result of running content through the safety filter.
class ContentFilterResult {
  /// Whether the content is allowed to pass through.
  final bool isAllowed;

  /// Human-readable reason if blocked (null when allowed).
  final String? reason;

  /// The filtered/cleaned content (same as input when allowed,
  /// or a safe replacement when blocked).
  final String? filteredContent;

  /// Category that triggered the filter (null when allowed).
  final ContentCategory? blockedCategory;

  /// True if content contains suicide/self-harm indicators
  /// (content may still be allowed, but a warning should be shown).
  final bool containsSelfHarmIndicator;

  const ContentFilterResult({
    required this.isAllowed,
    this.reason,
    this.filteredContent,
    this.blockedCategory,
    this.containsSelfHarmIndicator = false,
  });

  factory ContentFilterResult.allowed(String content) =>
      ContentFilterResult(isAllowed: true, filteredContent: content);

  factory ContentFilterResult.blocked({
    required String reason,
    required ContentCategory category,
    String? safeReplacement,
    bool containsSelfHarmIndicator = false,
  }) =>
      ContentFilterResult(
        isAllowed: false,
        reason: reason,
        filteredContent: safeReplacement,
        blockedCategory: category,
        containsSelfHarmIndicator: containsSelfHarmIndicator,
      );

  factory ContentFilterResult.selfHarmWarning(String content) =>
      ContentFilterResult(
        isAllowed: false,
        reason: '偵測到可能的自殺/自殘相關內容',
        filteredContent: content,
        blockedCategory: ContentCategory.selfHarm,
        containsSelfHarmIndicator: true,
      );
}

/// Categories of blocked content.
enum ContentCategory {
  sexuallyExplicit,
  violenceHarassment,
  illegalActivity,
  minorRelated,
  manipulativeTactics,
  selfHarm,
  personalInfo,
}

/// Content filter level.
enum ContentFilterLevel {
  standard,
  strict,
}

/// Content safety filter service.
///
/// Checks user input and AI output for unsafe content using
/// local keyword matching (no API calls needed).
class ContentFilter {
  ContentFilter._();
  static final ContentFilter instance = ContentFilter._();

  ContentFilterLevel _level = ContentFilterLevel.standard;

  ContentFilterLevel get level => _level;

  void setLevel(ContentFilterLevel level) {
    _level = level;
  }

  // ── Public API ──────────────────────────────────────────────────────

  /// Check user INPUT before sending to AI.
  ContentFilterResult checkInput(String text) {
    if (text.trim().isEmpty) {
      return ContentFilterResult.allowed(text);
    }

    final lower = text.toLowerCase();

    // 1. Minors — strongest filter, check first
    if (_containsKeyword(lower, BlockedKeywords.minorRelated)) {
      return ContentFilterResult.blocked(
        reason: '偵測到涉及未成年人的內容，此類請求已被拒絕。',
        category: ContentCategory.minorRelated,
        safeReplacement: '抱歉，我無法處理涉及未成年人的請求。',
      );
    }

    // 2. Suicide / self-harm — warn, don't just block
    if (_containsKeyword(lower, BlockedKeywords.suicideSelfHarm)) {
      return ContentFilterResult.selfHarmWarning(text);
    }

    // 3. Sexually explicit
    if (_containsKeyword(lower, BlockedKeywords.sexuallyExplicit)) {
      return ContentFilterResult.blocked(
        reason: '偵測到色情或露骨的性相關內容。',
        category: ContentCategory.sexuallyExplicit,
        safeReplacement: '抱歉，我無法生成色情或露骨的內容。讓我們用更尊重的方式表達吧！',
      );
    }

    // 4. Violence / harassment
    if (_containsKeyword(lower, BlockedKeywords.violenceHarassment)) {
      return ContentFilterResult.blocked(
        reason: '偵測到暴力或騷擾相關內容。',
        category: ContentCategory.violenceHarassment,
        safeReplacement: '抱歉，我無法生成涉及暴力或騷擾的內容。健康的關係建立在尊重之上。',
      );
    }

    // 5. Illegal activity
    if (_containsKeyword(lower, BlockedKeywords.illegalActivity)) {
      return ContentFilterResult.blocked(
        reason: '偵測到涉及違法活動的內容。',
        category: ContentCategory.illegalActivity,
        safeReplacement: '抱歉，我無法協助任何違法活動。',
      );
    }

    // 6. Manipulative tactics (strict mode only blocks; standard warns)
    if (_containsKeyword(lower, BlockedKeywords.manipulativeTactics)) {
      if (_level == ContentFilterLevel.strict) {
        return ContentFilterResult.blocked(
          reason: '偵測到可能的操控或情感虐待技巧。',
          category: ContentCategory.manipulativeTactics,
          safeReplacement: '抱歉，我無法提供操控或傷害他人的建議。讓我幫你用健康的方式溝通吧！',
        );
      }
      // In standard mode, still block obviously harmful manipulation
      return ContentFilterResult.blocked(
        reason: '偵測到可能的操控或情感虐待技巧。',
        category: ContentCategory.manipulativeTactics,
        safeReplacement: '抱歉，我無法提供操控或傷害他人的建議。讓我幫你用健康的方式溝通吧！',
      );
    }

    // 7. Personal info (phone, email, etc.) in input — warn
    if (_containsPersonalInfo(text)) {
      return ContentFilterResult.blocked(
        reason: '偵測到個人資訊（電話、信箱等），為保護隱私已移除。',
        category: ContentCategory.personalInfo,
        safeReplacement: _stripPersonalInfo(text),
      );
    }

    return ContentFilterResult.allowed(text);
  }

  /// Check AI OUTPUT before showing to user.
  ContentFilterResult checkOutput(String text) {
    if (text.trim().isEmpty) {
      return ContentFilterResult.allowed(text);
    }

    final lower = text.toLowerCase();

    // 1. Minors — absolute block
    if (_containsKeyword(lower, BlockedKeywords.minorRelated)) {
      return ContentFilterResult.blocked(
        reason: 'AI 回覆包含不當內容，已被過濾。',
        category: ContentCategory.minorRelated,
        safeReplacement: '抱歉，此回覆內容不適當，請重新嘗試。',
      );
    }

    // 2. Sexually explicit
    if (_containsKeyword(lower, BlockedKeywords.sexuallyExplicit)) {
      return ContentFilterResult.blocked(
        reason: 'AI 回覆包含色情內容，已被過濾。',
        category: ContentCategory.sexuallyExplicit,
        safeReplacement: '抱歉，此回覆內容不適當，請重新嘗試。',
      );
    }

    // 3. Violence / harassment suggestions
    if (_containsKeyword(lower, BlockedKeywords.violenceHarassment)) {
      return ContentFilterResult.blocked(
        reason: 'AI 回覆包含暴力/騷擾建議，已被過濾。',
        category: ContentCategory.violenceHarassment,
        safeReplacement: '抱歉，此回覆內容不適當，請重新嘗試。',
      );
    }

    // 4. Manipulative tactics in output — always block
    if (_containsKeyword(lower, BlockedKeywords.manipulativeTactics)) {
      return ContentFilterResult.blocked(
        reason: 'AI 回覆包含操控技巧，已被過濾。',
        category: ContentCategory.manipulativeTactics,
        safeReplacement: '抱歉，此回覆內容不適當。健康的關係不需要操控技巧。',
      );
    }

    return ContentFilterResult.allowed(text);
  }

  // ── Private helpers ─────────────────────────────────────────────────

  bool _containsKeyword(String lowerText, List<String> keywords) {
    for (final keyword in keywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  // ── PII Detection Patterns ──────────────────────────────────────────

  /// Regex patterns for common personal info.
  static final List<RegExp> _piiPatterns = [
    // Phone numbers (international formats)
    RegExp(r'(?:\+?(?:886|852|81|82|1|44|86)[\s-]?)?\(?\d{2,4}\)?[\s.-]?\d{3,4}[\s.-]?\d{3,4}'),
    // Email addresses
    RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
    // Taiwan ID number
    RegExp(r'[A-Z][12]\d{8}'),
    // Credit card numbers (basic)
    RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'),
  ];

  bool _containsPersonalInfo(String text) {
    for (final pattern in _piiPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  String _stripPersonalInfo(String text) {
    var result = text;
    for (final pattern in _piiPatterns) {
      result = result.replaceAll(pattern, '[已隱藏]');
    }
    return result;
  }
}
