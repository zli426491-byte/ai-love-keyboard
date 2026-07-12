import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/services/account_service.dart';
import 'package:ai_love_keyboard/services/revenuecat_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/services/privacy_manager.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final account = context.read<AccountService>();
    final success = _isRegister
        ? await account.signUp(
            email: _emailController.text,
            password: _passwordController.text,
          )
        : await account.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
    if (!mounted) return;

    if (!success) {
      final message = account.errorMessage ?? '帳號操作失敗';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final token = account.accessToken;
    final userId = account.userId;
    if (token != null && userId != null) {
      final usage = context.read<UsageService>();
      await RevenueCatService.instance.bindAccount(userId, token);
      await usage.setSubscribed(RevenueCatService.instance.isSubscribed);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _signOut() async {
    final account = context.read<AccountService>();
    final usage = context.read<UsageService>();
    await RevenueCatService.instance.unbindAccount();
    await account.signOut();
    await usage.setSubscribed(false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('刪除 LoveKey 帳號？'),
        content: const Text('這會永久刪除登入帳號。此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('永久刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final account = context.read<AccountService>();
    final usage = context.read<UsageService>();
    final privacy = PrivacyManager.instance;
    await RevenueCatService.instance.unbindAccount();
    final deleted = await account.deleteAccount();
    if (deleted) {
      await usage.setSubscribed(false);
      await privacy.deleteAllLocalData();
      // Remove local usage, coin, referral, and onboarding records after the
      // server has permanently deleted the account.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) Navigator.pop(context);
    } else if (mounted && account.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(account.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountService>();
    final signedIn = account.isSignedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LoveKey 帳號'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          Icon(
            signedIn
                ? Icons.verified_user_rounded
                : Icons.account_circle_rounded,
            size: 64,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            signedIn ? '帳號已綁定' : '登入後同步你的會員資格',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            signedIn
                ? (account.email ?? '')
                : '同一個帳號可在 iOS 與 Android 使用相同會員身份。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 28),
          if (!account.isConfigured)
            _InfoCard(
              icon: Icons.settings_rounded,
              text: '帳號服務尚未設定。請使用 SUPABASE_URL 與 SUPABASE_ANON_KEY 建置 App。',
            )
          else if (signedIn)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: account.isLoading ? null : _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('登出此帳號'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: account.isLoading ? null : _deleteAccount,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('永久刪除帳號'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                ),
              ],
            )
          else ...[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '密碼（至少 8 個字元）',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: account.isLoading ? null : _submit,
              child: Text(
                account.isLoading ? '處理中…' : (_isRegister ? '建立帳號' : '登入'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: account.isLoading
                  ? null
                  : () => setState(() => _isRegister = !_isRegister),
              child: Text(_isRegister ? '已有帳號？登入' : '還沒有帳號？註冊'),
            ),
          ],
          const SizedBox(height: 24),
          _InfoCard(
            icon: Icons.shield_outlined,
            text: '登入 Token 只用於驗證 API 權限；後台不保存原始聊天內容。',
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFF0DDE7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }
}
