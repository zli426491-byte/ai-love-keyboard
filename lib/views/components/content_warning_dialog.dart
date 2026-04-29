import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ai_love_keyboard/data/blocked_keywords.dart';
import 'package:ai_love_keyboard/services/content_filter.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

/// Dialog shown when the content filter blocks user input or AI output.
class ContentWarningDialog extends StatelessWidget {
  final ContentFilterResult filterResult;

  const ContentWarningDialog({super.key, required this.filterResult});

  /// Show the warning dialog.
  static Future<void> show(
      BuildContext context, ContentFilterResult result) {
    return showDialog(
      context: context,
      builder: (_) => ContentWarningDialog(filterResult: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelfHarm = filterResult.containsSelfHarmIndicator;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      title: Row(
        children: [
          Icon(
            isSelfHarm
                ? Icons.favorite_rounded
                : Icons.warning_amber_rounded,
            color: isSelfHarm ? Colors.red.shade300 : AppTheme.warning,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSelfHarm ? '我們很關心你' : '內容已被過濾',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reason
            Text(
              filterResult.reason ?? '此內容不符合社群準則。',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Self-harm: show hotline info
            if (isSelfHarm) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                      color: Colors.red.shade300.withValues(alpha: 0.3)),
                ),
                child: Text(
                  BlockedKeywords.mentalHealthHotlineInfo,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.red.shade100,
                  ),
                ),
              ),
            ] else ...[
              // Suggestion for non-self-harm blocks
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 建議',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getSuggestionText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Community guidelines link
        TextButton(
          onPressed: () async {
            final uri =
                Uri.parse('https://ailovekeyboard.com/guidelines');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: const Text(
            '社群準則',
            style: TextStyle(fontSize: 13),
          ),
        ),
        // Dismiss
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('我了解'),
        ),
      ],
    );
  }

  String _getSuggestionText() {
    switch (filterResult.blockedCategory) {
      case ContentCategory.sexuallyExplicit:
        return '試著用更含蓄、尊重的方式表達你的感受。健康的溝通不需要露骨的內容。';
      case ContentCategory.violenceHarassment:
        return '嘗試用和平、尊重的方式表達。如果你遇到困難，可以試著描述你的感受而非訴諸暴力。';
      case ContentCategory.illegalActivity:
        return '此類內容涉及違法行為，我們無法提供協助。';
      case ContentCategory.minorRelated:
        return '涉及未成年人的不當請求已被嚴格禁止。';
      case ContentCategory.manipulativeTactics:
        return '試著用真誠、坦率的方式溝通。操控技巧可能短期有效，但會損害長期關係。';
      case ContentCategory.personalInfo:
        return '為保護你的隱私，個人資訊已被移除。你可以在設定中調整隱私選項。';
      case ContentCategory.selfHarm:
      case null:
        return '請嘗試用不同的方式表達你的需求。';
    }
  }
}
