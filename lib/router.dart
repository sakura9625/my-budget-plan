import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/app_settings.dart';
import 'screens/onboarding_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/main_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final settingsBox = Hive.box<AppSettings>('settings');
  final settings = settingsBox.isNotEmpty ? settingsBox.getAt(0) : null;
  final isSetupDone = settings?.initialSetupCompleted ?? false;

  return GoRouter(
    initialLocation: isSetupDone ? '/main' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),
    ],
  );
});
