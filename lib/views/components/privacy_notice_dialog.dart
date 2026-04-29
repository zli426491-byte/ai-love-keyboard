import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ai_love_keyboard/utils/app_theme.dart';

/// Dialog shown on first app open to explain privacy policy
/// and obtain user consent before using the app.
class PrivacyNoticeDialog extends StatelessWidget {
  final VoidCallback onAccept;

  const PrivacyNoticeDialog({super.key, required this.onAccept});

  /// Shows the dialog as a non-dismissible modal.
  static Future<void> show(BuildContext context,
      {required VoidCallback onAccept}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PrivacyNoticeDialog(onAccept: onAccept),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppTheme.primary, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '隱私權與使用條款',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Explanation
              const Text(
                '歡迎使用 AI 戀愛鍵盤！在開始之前，請了解以下重要資訊：',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Data collection info
              _InfoSection(
                icon: Icons.cloud_upload_outlined,
                title: '訊息處理',
                description: '你輸入的訊息會傳送至 AI 服務（OpenAI）進行處理，以生成回覆建議。',
              ),

              const SizedBox(height: AppTheme.spacingSm),

              _InfoSection(
                icon: Icons.check_circle_outline,
                title: '我們收集的資料',
                description: '使用次數統計、裝置語言設定、訂閱狀態。',
              ),

              const SizedBox(height: AppTheme.spacingSm),

              _InfoSection(
                icon: Icons.block_outlined,
                title: '我們不收集的資料',
                description: '聊天內容不會儲存在我們的伺服器上、不收集通訊錄、不追蹤你的位置。',
              ),

              const SizedBox(height: AppTheme.spacingSm),

              _InfoSection(
                icon: Icons.security_outlined,
                title: '隱私保護',
                description: '個人資訊（電話、信箱等）會在傳送前自動移除。你可以在設定中管理隱私選項。',
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Privacy policy link
              Center(
                child: TextButton(
                  onPressed: () async {
                    final uri =
                        Uri.parse('https://ailovekeyboard.com/privacy');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: const Text(
                    '查看完整隱私權政策',
                    style: TextStyle(
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Accept button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAccept();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    '我同意',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
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
    );
  }
}
