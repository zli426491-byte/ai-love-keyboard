import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:ai_love_keyboard/models/user_locale.dart';
import 'package:ai_love_keyboard/services/content_filter.dart';
import 'package:ai_love_keyboard/services/locale_service.dart';
import 'package:ai_love_keyboard/services/privacy_manager.dart';
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

          // ── Language & Region ──────────────────────────────────
          _SectionHeader(title: '語言與地區'),
          Consumer<LocaleService>(
            builder: (context, localeService, _) {
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.language_rounded,
                            color: AppTheme.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '目前地區',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                localeService.currentLocale.displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: UserLocale.values.map((locale) {
                        final isSelected =
                            locale == localeService.currentLocale;
                        return ChoiceChip(
                          label: Text(
                            locale.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isSelected ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.primary,
                          onSelected: (_) =>
                              localeService.setLocale(locale),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // ── Keyboard Setup ─────────────────────────────────────
          _SectionHeader(title: '鍵盤設定'),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.keyboard_rounded,
                        color: AppTheme.accent, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        '啟用 AI 戀愛鍵盤',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '啟用後可在任何聊天 App 中直接使用 AI 回覆功能，不需切換 App！',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SetupStep(
                        number: '1',
                        text: '打開 iPhone「設定」',
                      ),
                      SizedBox(height: 8),
                      _SetupStep(
                        number: '2',
                        text: '前往「一般」→「鍵盤」',
                      ),
                      SizedBox(height: 8),
                      _SetupStep(
                        number: '3',
                        text: '點選「新增鍵盤...」',
                      ),
                      SizedBox(height: 8),
                      _SetupStep(
                        number: '4',
                        text: '選擇「AI 戀愛鍵盤」',
                      ),
                      SizedBox(height: 8),
                      _SetupStep(
                        number: '5',
                        text: '開啟「允許完整取用」（必要，用於 AI 連線）',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                          'app-settings:com.ailovekeyboard.app');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded,
                        size: 18),
                    label: const Text('前往設定'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // ── Privacy Settings ──────────────────────────────────
          _SectionHeader(title: '隱私設定'),
          Consumer<PrivacyManager>(
            builder: (context, privacy, _) {
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('自動移除個人資訊',
                          style: TextStyle(fontSize: 14)),
                      subtitle: Text(
                        '傳送前自動移除電話、信箱等個資',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                      value: privacy.autoStripPii,
                      onChanged: (v) => privacy.setAutoStripPii(v),
                      activeTrackColor: AppTheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('24 小時自動刪除紀錄',
                          style: TextStyle(fontSize: 14)),
                      subtitle: Text(
                        '已傳送的資料紀錄 24 小時後自動清除',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                      value: privacy.autoDeleteHistory,
                      onChanged: (v) => privacy.setAutoDeleteHistory(v),
                      activeTrackColor: AppTheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.history_rounded,
                          color: AppTheme.primary, size: 22),
                      title: const Text('查看已傳送資料',
                          style: TextStyle(fontSize: 14)),
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade400),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _showDataSentHistory(context, privacy),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded,
                          color: AppTheme.error, size: 22),
                      title: const Text('刪除所有資料',
                          style: TextStyle(
                              fontSize: 14, color: AppTheme.error)),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _confirmDeleteAllData(context, privacy),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined,
                          color: AppTheme.primary, size: 22),
                      title: const Text('隱私權政策',
                          style: TextStyle(fontSize: 14)),
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade400),
                      contentPadding: EdgeInsets.zero,
                      onTap: () =>
                          _launchUrl('https://ailovekeyboard.com/privacy'),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // ── Content Safety ─────────────────────────────────────
          _SectionHeader(title: '內容安全'),
          Consumer<PrivacyManager>(
            builder: (context, privacy, _) {
              final isStrict = privacy.filterLevel == 'strict';
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.shield_outlined,
                          color: AppTheme.primary, size: 22),
                      title: const Text('內容過濾等級',
                          style: TextStyle(fontSize: 14)),
                      trailing: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: 'standard', label: Text('標準')),
                          ButtonSegment(
                              value: 'strict', label: Text('嚴格')),
                        ],
                        selected: {privacy.filterLevel},
                        onSelectionChanged: (v) {
                          privacy.setFilterLevel(v.first);
                          ContentFilter.instance.setLevel(
                            v.first == 'strict'
                                ? ContentFilterLevel.strict
                                : ContentFilterLevel.standard,
                          );
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          textStyle: WidgetStateProperty.all(
                              const TextStyle(fontSize: 12)),
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (isStrict)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '嚴格模式：加強過濾可能具爭議的內容',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ),
                    const Divider(height: 16),
                    ListTile(
                      leading: const Icon(Icons.gavel_rounded,
                          color: AppTheme.primary, size: 22),
                      title: const Text('社群準則',
                          style: TextStyle(fontSize: 14)),
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade400),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _launchUrl(
                          'https://ailovekeyboard.com/guidelines'),
                    ),
                  ],
                ),
              );
            },
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

  static void _showDataSentHistory(
      BuildContext context, PrivacyManager privacy) {
    final history = privacy.dataSentHistory;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '已傳送資料紀錄',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '共 ${history.length} 筆紀錄',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Expanded(
                  child: history.isEmpty
                      ? const Center(child: Text('尚無傳送紀錄'))
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: history.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final record =
                                history[history.length - 1 - i];
                            final dateStr = DateFormat('MM/dd HH:mm')
                                .format(record.timestamp);
                            return ListTile(
                              dense: true,
                              title: Text(
                                record.feature,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                '$dateStr - ${record.characterCount} 字元',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              leading: const Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: AppTheme.primary,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void _confirmDeleteAllData(
      BuildContext context, PrivacyManager privacy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除所有資料？'),
        content: const Text('此操作將清除所有已傳送的資料紀錄，無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await privacy.deleteAllLocalData();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('所有資料已刪除')),
                );
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('確定刪除'),
          ),
        ],
      ),
    );
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

class _SetupStep extends StatelessWidget {
  final String number;
  final String text;
  const _SetupStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
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
