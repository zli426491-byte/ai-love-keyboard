class ChatAnalysis {
  final int interestLevel;
  final String attitude;
  final List<String> suggestions;
  final String summary;

  ChatAnalysis({
    required this.interestLevel,
    required this.attitude,
    required this.suggestions,
    required this.summary,
  });

  factory ChatAnalysis.fromJson(Map<String, dynamic> json) {
    return ChatAnalysis(
      interestLevel: (json['interest_level'] as num).clamp(1, 10).toInt(),
      attitude: json['attitude'] as String,
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      summary: json['summary'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interest_level': interestLevel,
      'attitude': attitude,
      'suggestions': suggestions,
      'summary': summary,
    };
  }
}
