import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/account_service.dart';
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
import 'package:ai_love_keyboard/services/revenuecat_service.dart';
import 'package:ai_love_keyboard/services/seasonal_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/achievements/achievements_view.dart';
import 'package:ai_love_keyboard/views/auth/account_view.dart';
import 'package:ai_love_keyboard/views/characters/character_market_view.dart';
import 'package:ai_love_keyboard/views/characters/create_persona_view.dart';
import 'package:ai_love_keyboard/views/emergency/emergency_coach_view.dart';
import 'package:ai_love_keyboard/views/analysis/chat_analysis_view.dart';
import 'package:ai_love_keyboard/views/packages/package_store_view.dart';
import 'package:ai_love_keyboard/views/packages/seasonal_packages_view.dart';
import 'package:ai_love_keyboard/views/opener/opener_view.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';
import 'package:ai_love_keyboard/views/components/privacy_notice_dialog.dart';
import 'package:ai_love_keyboard/views/home/home_view.dart';
import 'package:ai_love_keyboard/views/keyboard/keyboard_guide_view.dart';
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
  final accountService = AccountService.instance;

  try {
    await accountService.init();
  } catch (error) {
    _logInitFailure('account', error);
  }

  try {
    await AnalyticsService.instance.init();
  } catch (error) {
    _logInitFailure('analytics', error);
  }
  try {
    await AttributionService.instance.init();
  } catch (error) {
    _logInitFailure('attribution', error);
  }
  try {
    await DeepLinkService.instance.init();
  } catch (error) {
    _logInitFailure('deep_link', error);
  }
  try {
    await usageService.init();
  } catch (error) {
    _logInitFailure('usage', error);
  }
  try {
    final subscribed = await RevenueCatService.instance.init();
    // Never trust a cached local Pro boolean when StoreKit/Play has not
    // successfully returned customer info. The backend remains authoritative,
    // but the UI and keyboard must fail closed too.
    final storePlatform =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    if (storePlatform) {
      await usageService.setSubscribed(
        accountService.isSignedIn &&
            RevenueCatService.instance.customerInfoSynced &&
            subscribed,
      );
    } else if (accountService.isSignedIn &&
        RevenueCatService.instance.customerInfoSynced) {
      await usageService.setSubscribed(subscribed);
    }
    if (accountService.isSignedIn && accountService.accessToken != null) {
      await RevenueCatService.instance.bindAccount(
        accountService.userId!,
        accountService.accessToken!,
      );
      await usageService.setSubscribed(RevenueCatService.instance.isSubscribed);
    }
  } catch (error) {
    _logInitFailure('revenuecat', error);
  }
  try {
    await localeService.init();
  } catch (error) {
    _logInitFailure('locale', error);
  }
  try {
    await packageManager.init();
  } catch (error) {
    _logInitFailure('package_manager', error);
  }
  try {
    await seasonalService.init();
  } catch (error) {
    _logInitFailure('seasonal', error);
  }
  try {
    await achievementService.init();
  } catch (error) {
    _logInitFailure('achievement', error);
  }
  try {
    await emergencyService.init();
  } catch (error) {
    _logInitFailure('emergency', error);
  }
  try {
    await referralService.init();
  } catch (error) {
    _logInitFailure('referral', error);
  }
  try {
    await coinService.init();
  } catch (error) {
    _logInitFailure('coins', error);
  }
  try {
    await privacyManager.init();
  } catch (error) {
    _logInitFailure('privacy', error);
  }

  try {
    ContentFilter.instance.setLevel(
      privacyManager.filterLevel == 'strict'
          ? ContentFilterLevel.strict
          : ContentFilterLevel.standard,
    );
  } catch (error) {
    _logInitFailure('content_filter', error);
  }

  try {
    PromptTemplates.cultureContext = localeService.currentLocale.culturePrompt;
    localeService.addListener(() {
      PromptTemplates.cultureContext =
          localeService.currentLocale.culturePrompt;
    });
  } catch (error) {
    _logInitFailure('prompt_templates', error);
  }

  // Check onboarding and gender status
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete =
      prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;
  final genderSelected = prefs.getString(AppConstants.prefUserGender) != null;
  final privacyAccepted = privacyManager.privacyAccepted;

  try {
    AnalyticsService.instance.trackAppOpen();
  } catch (error) {
    _logInitFailure('analytics_app_open', error);
  }

  runApp(
    AiLoveKeyboardApp(
      usageService: usageService,
      accountService: accountService,
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
    ),
  );
}

void _logInitFailure(String service, Object error) {
  // Keep user-facing screens usable while leaving enough context to diagnose
  // a broken release. Never log tokens, prompts, or raw backend responses.
  debugPrint('[LoveKey] $service initialization failed: ${error.runtimeType}');
}

class AiLoveKeyboardApp extends StatelessWidget {
  final UsageService usageService;
  final AccountService accountService;
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
    required this.accountService,
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
        ChangeNotifierProvider.value(value: accountService),
        ChangeNotifierProvider.value(value: usageService),
        ChangeNotifierProvider.value(value: RevenueCatService.instance),
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
          '/character-market': (context) => const CharacterMarketView(),
          '/create-persona': (context) => const CreatePersonaView(),
          '/package-store': (context) => const PackageStoreView(),
          '/achievements': (context) => const AchievementsView(),
          '/seasonal-packages': (context) => const SeasonalPackagesView(),
          '/referral': (context) => const ReferralView(),
          '/emergency': (context) => const EmergencyCoachView(),
          '/opener': (context) => const OpenerView(),
          '/paywall': (context) => const PaywallView(),
          '/analysis': (context) => const ChatAnalysisView(),
          '/coin-store': (context) => const CoinStoreView(),
          '/keyboard-guide': (context) => const KeyboardGuideView(),
          '/account': (context) => const AccountView(),
        },
      ),
    );
  }
}

/// A gate widget that shows the privacy notice dialog on first launch.
class _PrivacyGate extends StatefulWidget {
  final PrivacyManager privacyManager;
  final Widget child;

  const _PrivacyGate({required this.privacyManager, required this.child});

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
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
