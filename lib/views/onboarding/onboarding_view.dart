import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/home/home_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      gradient: AppTheme.onboardingGradient1,
      icon: Icons.auto_awesome_rounded,
      title: 'AI 智慧回覆',
      subtitle: '不知道怎麼回？\nAI 幫你生成完美回覆',
      description: '4 種風格任你選：幽默、浪漫、撩人、高冷',
    ),
    _OnboardingPage(
      gradient: AppTheme.onboardingGradient2,
      icon: Icons.analytics_rounded,
      title: '聊天分析',
      subtitle: '她到底對你有沒有意思？',
      description: 'AI 分析對方的興趣程度，給你具體建議',
    ),
    _OnboardingPage(
      gradient: AppTheme.onboardingGradient3,
      icon: Icons.chat_bubble_rounded,
      title: '破冰開場白',
      subtitle: '配對後不知道說什麼？',
      description: '根據對方資料生成有創意的開場白，告別冷場',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingComplete, true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Pages ───────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) => _pages[index],
          ),

          // ── Bottom Controls ─────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                        dotColor: Colors.white.withValues(alpha: 0.3),
                        activeDotColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Row(
                      children: [
                        if (_currentPage < _pages.length - 1)
                          TextButton(
                            onPressed: _completeOnboarding,
                            child: const Text(
                              '跳過',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 60),
                        const Spacer(),
                        GestureDetector(
                          onTap: _nextPage,
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _currentPage < _pages.length - 1
                                    ? '下一步'
                                    : '開始使用',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  const _OnboardingPage({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Icon(icon, size: 48, color: Colors.white),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 600))
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: AppTheme.spacingXl),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 500),
                  ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.5,
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 500),
                  ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 600),
                    duration: const Duration(milliseconds: 500),
                  ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
