import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/analytics_service.dart';
import 'package:ai_love_keyboard/services/coin_service.dart';
import 'package:ai_love_keyboard/services/attribution_service.dart';
import 'package:ai_love_keyboard/services/achievement_service.dart';
import 'package:ai_love_keyboard/services/content_filter.dart';
import 'package:ai_love_keyboard/services/deep_link_service.dart';
import 'package:ai_love_keyboard/services/emergency_service.dart';
import 'package:ai_love_keyboard/services/locale_service.dart';
import 'package:ai_love_keyboard/services/privacy_manager.dart';
import 'package:ai_love_keyboard/services/prompt_templates.dart';
import 'package:ai_love_keyboard/services/package_manager.dart';
import 'package:ai_love_keyboard/services/referral_service.dart';
import 'package:ai_love_keyboard/services/seasonal_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/achievements/achievements_view.dart';
import 'package:ai_love_keyboard/views/characters/character_market_view.dart';
import 'package:ai_love_keyboard/views/characters/create_persona_view.dart';
import 'package:ai_love_keyboard/views/emergency/emergency_coach_view.dart';
import 'package:ai_love_keyboard/views/packages/package_store_view.dart';
import 'package:ai_love_keyboard/views/packages/seasonal_packages_view.dart';
import 'package:ai_love_keyboard/views/components/privacy_notice_dialog.dart';
import 'package:ai_love_keyboard/views/home/home_view.dart';
import 'package:ai_love_keyboard/views/onboarding/onboarding_view.dart';
import 'package:ai_love_keyboard/views/onboarding/gender_selection_view.dart';
import 'package:ai_love_keyboard/views/coins/coin_store_view.dart';
import 'package:ai_love_keyboard/views/social/referral_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize all services with error protection
  final usageService = UsageService();
  final localeService = LocaleService();
  final packageManager = PackageManager();
  final seasonalService = SeasonalService();
  final achievementService = AchievementService();
  final emergencyService = EmergencyService();
  final referralService = ReferralService();
  final coinService = CoinService();
  final privacyManager = PrivacyManager.instance;

  try { await AnalyticsService.instance.init(); } catch (_) {}
  try { await AttributionService.instance.init(); } catch (_) {}
  try { await DeepLinkService.instance.init(); } catch (_) {}
  try { await usageService.init(); } catch (_) {}
  try { await localeService.init(); } catch (_) {}
  try { await packageManager.init(); } catch (_) {}
  try { await seasonalService.init(); } catch (_) {}
  try { await achievementService.init(); } catch (_) {}
  try { await emergencyService.init(); } catch (_) {}
  try { await referralService.init(); } catch (_) {}
  try { await coinService.init(); } catch (_) {}
  try { await privacyManager.init(); } catch (_) {}

  try {
    ContentFilter.instance.setLevel(
      privacyManager.filterLevel == 'strict'
          ? ContentFilterLevel.strict
          : ContentFilterLevel.standard,
    );
  } catch (_) {}

  try {
    PromptTemplates.cultureContext = localeService.currentLocale.culturePrompt;
    localeService.addListener(() {
      PromptTemplates.cultureContext =
          localeService.currentLocale.culturePrompt;
    });
  } catch (_) {}

  // Check onboarding and gender status
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete =
      prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;
  final genderSelected =
      prefs.getString(AppConstants.prefUserGender) != null;
  final privacyAccepted = privacyManager.privacyAccepted;

  try { AnalyticsService.instance.trackAppOpen(); } catch (_) {}

  runApp(AiLoveKeyboardApp(
    usageService: usageService,
    localeService: localeService,
    privacyManager: privacyManager,
    packageManager: packageManager,
    seasonalService: seasonalService,
    achievementService: achievementService,
    emergencyService: emergencyService,
    referralService: referralService,
    coinService: coinService,
    onboardingComplete: onboardingComplete,
    genderSelected: genderSelected,
    privacyAccepted: privacyAccepted,
  ));
}

class AiLoveKeyboardApp extends StatelessWidget {
  final UsageService usageService;
  final LocaleService localeService;
  final PrivacyManager privacyManager;
  final PackageManager packageManager;
  final SeasonalService seasonalService;
  final AchievementService achievementService;
  final EmergencyService emergencyService;
  final ReferralService referralService;
  final CoinService coinService;
  final bool onboardingComplete;
  final bool genderSelected;
  final bool privacyAccepted;

  const AiLoveKeyboardApp({
    super.key,
    required this.usageService,
    required this.localeService,
    required this.privacyManager,
    required this.packageManager,
    required this.seasonalService,
    required this.achievementService,
    required this.emergencyService,
    required this.referralService,
    required this.coinService,
    required this.onboardingComplete,
    required this.genderSelected,
    required this.privacyAccepted,
  });

  Widget _getInitialScreen() {
    // Privacy notice must be accepted before anything else
    if (!privacyAccepted) {
      return _PrivacyGate(
        privacyManager: privacyManager,
        child: _getPostPrivacyScreen(),
      );
    }
    return _getPostPrivacyScreen();
  }

  Widget _getPostPrivacyScreen() {
    if (!genderSelected) {
      return const GenderSelectionView();
    }
    if (!onboardingComplete) {
      return const OnboardingView();
    }
    return const HomeView();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AiService()),
        ChangeNotifierProvider.value(value: usageService),
        ChangeNotifierProvider.value(value: localeService),
        ChangeNotifierProvider.value(value: privacyManager),
        ChangeNotifierProvider.value(value: packageManager),
        ChangeNotifierProvider.value(value: seasonalService),
        ChangeNotifierProvider.value(value: achievementService),
        ChangeNotifierProvider.value(value: emergencyService),
        ChangeNotifierProvider.value(value: referralService),
        ChangeNotifierProvider.value(value: coinService),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: _getInitialScreen(),
        routes: {
          '/character-market': (context) =>
              const CharacterMarketView(),
          '/create-persona': (context) =>
              const CreatePersonaView(),
          '/package-store': (context) =>
              const PackageStoreView(),
          '/achievements': (context) =>
              const AchievementsView(),
          '/seasonal-packages': (context) =>
              const SeasonalPackagesView(),
          '/referral': (context) =>
              const ReferralView(),
          '/emergency': (context) =>
              const EmergencyCoachView(),
          '/coin-store': (context) =>
              const CoinStoreView(),
        },
      ),
    );
  }
}

/// A gate widget that shows the privacy notice dialog on first launch.
class _PrivacyGate extends StatefulWidget {
  final PrivacyManager privacyManager;
  final Widget child;

  const _PrivacyGate({
    required this.privacyManager,
    required this.child,
  });

  @override
  State<_PrivacyGate> createState() => _PrivacyGateState();
}

class _PrivacyGateState extends State<_PrivacyGate> {
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    // Show dialog after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.privacyManager.privacyAccepted) {
        PrivacyNoticeDialog.show(
          context,
          onAccept: () async {
            await widget.privacyManager.acceptPrivacyPolicy();
            if (mounted) {
              setState(() => _accepted = true);
            }
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_accepted || widget.privacyManager.privacyAccepted) {
      return widget.child;
    }
    // Show a blank scaffold while waiting for privacy acceptance
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

