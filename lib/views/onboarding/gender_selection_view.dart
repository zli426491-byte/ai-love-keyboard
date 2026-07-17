import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/models/user_gender.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/onboarding/onboarding_view.dart';

class GenderSelectionView extends StatefulWidget {
  const GenderSelectionView({super.key});

  @override
  State<GenderSelectionView> createState() => _GenderSelectionViewState();
}

class _GenderSelectionViewState extends State<GenderSelectionView> {
  static const _ink = Color(0xFF241827);
  static const _paper = Color(0xFFFFF9FB);
  static const _muted = Color(0xFFCDBBC5);
  static const _rose = Color(0xFFFF6F8F);

  UserGender? _selected;

  Future<void> _confirm() async {
    if (_selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefUserGender,
      _selected == UserGender.male ? 'male' : 'female',
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1D141B), Color(0xFF35202E), Color(0xFF241827)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _GenderBrand(),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: const Text(
                              '個人化你的 AI 回覆',
                              style: TextStyle(
                                color: _rose,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            '先告訴我們\n你想和誰聊天',
                            style: TextStyle(
                              color: _paper,
                              fontSize: 36,
                              height: 1.12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'LoveKey 只用這項選擇調整語氣，不會公開顯示。',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 15,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: UserGender.values.map((gender) {
                              final selected = _selected == gender;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: gender == UserGender.male ? 7 : 0,
                                    left: gender == UserGender.female ? 7 : 0,
                                  ),
                                  child: _GenderCard(
                                    gender: gender,
                                    selected: selected,
                                    onTap: () =>
                                        setState(() => _selected = gender),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const Spacer(),
                          AnimatedOpacity(
                            opacity: _selected == null ? 0.45 : 1,
                            duration: const Duration(milliseconds: 180),
                            child: SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: FilledButton(
                                onPressed: _selected == null ? null : _confirm,
                                style: FilledButton.styleFrom(
                                  disabledBackgroundColor: Colors.white,
                                  backgroundColor: _rose,
                                  foregroundColor: _ink,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  '繼續設定鍵盤',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GenderBrand extends StatelessWidget {
  const _GenderBrand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 38,
          height: 38,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _GenderSelectionViewState._rose,
              borderRadius: BorderRadius.all(Radius.circular(13)),
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: _GenderSelectionViewState._ink,
              size: 21,
            ),
          ),
        ),
        SizedBox(width: 10),
        Text(
          'LoveKey',
          style: TextStyle(
            color: _GenderSelectionViewState._paper,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _GenderCard extends StatelessWidget {
  final UserGender gender;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.gender,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = gender == UserGender.male
        ? Icons.male_rounded
        : Icons.female_rounded;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 214,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? _GenderSelectionViewState._paper
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? _GenderSelectionViewState._rose
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFE5EC)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    icon,
                    color: _GenderSelectionViewState._rose,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected
                      ? _GenderSelectionViewState._rose
                      : Colors.white.withValues(alpha: 0.30),
                  size: 23,
                ),
              ],
            ),
            const Spacer(),
            Text(
              gender.label,
              style: TextStyle(
                color: selected
                    ? _GenderSelectionViewState._ink
                    : _GenderSelectionViewState._paper,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              gender.description,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF786873)
                    : _GenderSelectionViewState._muted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08);
  }
}
