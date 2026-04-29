import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final usage = context.watch<UsageService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // ── Subscription Status ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              gradient: usage.isSubscribed
                  ? AppTheme.primaryGradient
                  : null,
              color: usage.isSubscribed ? null : Colors.grey.shade50,
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              children: [
                Icon(
                  usage.isSubscribed
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                  color: usage.isSubscribed
                      ? Colors.white
                      : AppTheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usage.isSubscribed ? 'PRO 會員' : '免費版',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: usage.isSubscribed
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        usage.isSubscribed
                            ? '享受無限 AI 功能'
                            : '每日 ${AppConstants.freeDailyLimit} 次免費使用',
                        style: TextStyle(
                          fontSize: 13,
                          color: usage.isSubscribed
                              ? Colors.white70
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!usage.isSubscribed)
                  ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const PaywallView(),
                    ),
                    child: const Text('升級'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // ── General ─────────────────────────────────────────────
          _SectionHeader(title: '一般'),
          _SettingsTile(
            icon: Icons.restore_rounded,
            title: '恢復購買',
            onTap: () {
              // TODO: Implement restore purchases
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('正在恢復購買...')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.star_rounded,
            title: '為 App 評分',
            onTap: () {
              // TODO: Open app store review
            },
          ),
          _SettingsTile(
            icon: Icons.share_rounded,
            title: '分享給朋友',
            onTap: () {
              // TODO: Implement share
            },
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // ── Legal ───────────────────────────────────────────────
          _SectionHeader(title: '法律'),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: '隱私權政策',
            onTap: () => _launchUrl('https://ailovekeyboard.com/privacy'),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: '服務條款',
            onTap: () => _launchUrl('https://ailovekeyboard.com/terms'),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // ── Version ─────────────────────────────────────────────
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData
                  ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                  : AppConstants.appVersion;
              return Center(
                child: Text(
                  '${AppConstants.appName} v$version',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 4, bottom: AppTheme.spacingSm, top: AppTheme.spacingSm),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(title),
      trailing:
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    );
  }
}
