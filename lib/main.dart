import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/home/home_view.dart';
import 'package:ai_love_keyboard/views/onboarding/onboarding_view.dart';

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

  // Initialize usage service
  final usageService = UsageService();
  await usageService.init();

  // Check onboarding status
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete =
      prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;

  runApp(AiLoveKeyboardApp(
    usageService: usageService,
    onboardingComplete: onboardingComplete,
  ));
}

class AiLoveKeyboardApp extends StatelessWidget {
  final UsageService usageService;
  final bool onboardingComplete;

  const AiLoveKeyboardApp({
    super.key,
    required this.usageService,
    required this.onboardingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AiService()),
        ChangeNotifierProvider.value(value: usageService),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: onboardingComplete
            ? const HomeView()
            : const OnboardingView(),
      ),
    );
  }
}
