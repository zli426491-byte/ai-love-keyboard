import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/models/user_gender.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/components/particle_background.dart';
import 'package:ai_love_keyboard/views/onboarding/onboarding_view.dart';

class GenderSelectionView extends StatefulWidget {
  const GenderSelectionView({super.key});

  @override
  State<GenderSelectionView> createState() => _GenderSelectionViewState();
}

class _GenderSelectionViewState extends State<GenderSelectionView> {
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
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // ── Background gradient glow ────────────────────────────
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    Color(0x40AB47BC),
                    Color(0x20FF80AB),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Floating particles ──────────────────────────────────
          const ParticleBackground(particleCount: 20),

          // ── Main content ────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Title
                  const Text(
                    '你的身份是？',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
                  const SizedBox(height: 12),
                  Text(
                    'AI 會根據你的身份調整回覆風格',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                  const Spacer(flex: 2),
                  // Gender cards
                  Row(
                    children: UserGender.values.map((gender) {
                      final isSelected = _selected == gender;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selected = gender),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 8),
                            padding:
                                const EdgeInsets.symmetric(vertical: 32),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.white.withValues(
                                  alpha: isSelected ? 0.1 : 0.05),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accent
                                        .withValues(alpha: 0.6)
                                    : Colors.white
                                        .withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.accent
                                            .withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.2),
                                        blurRadius: 30,
                                        spreadRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 10, sigmaY: 10),
                                child: Column(
                                  children: [
                                    // Checkmark for selected
                                    if (isSelected)
                                      Container(
                                        width: 28,
                                        height: 28,
                                        margin: const EdgeInsets.only(
                                            bottom: 8),
                                        decoration: BoxDecoration(
                                          gradient:
                                              AppTheme.romanticGradient,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      )
                                          .animate()
                                          .scale(
                                              begin:
                                                  const Offset(0, 0))
                                          .fadeIn()
                                    else
                                      const SizedBox(height: 36),
                                    Text(
                                      gender.emoji,
                                      style:
                                          const TextStyle(fontSize: 64),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      gender.label,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      gender.description,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected
                                            ? Colors.white
                                                .withValues(alpha: 0.8)
                                            : Colors.white
                                                .withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(
                              delay: Duration(
                                  milliseconds:
                                      gender == UserGender.male
                                          ? 400
                                          : 600),
                              duration: 500.ms,
                            ).slideY(begin: 0.3),
                      );
                    }).toList(),
                  ),
                  const Spacer(flex: 2),
                  // Confirm button
                  AnimatedOpacity(
                    opacity: _selected != null ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: _selected != null ? _confirm : null,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _selected != null
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFEC4899),
                                    Color(0xFFAB47BC),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          color: _selected == null
                              ? Colors.white.withValues(alpha: 0.1)
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _selected != null
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFEC4899)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: const Center(
                          child: Text(
                            '繼續',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
