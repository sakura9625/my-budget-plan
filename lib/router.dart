import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/life_settings.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/project_detail_screen.dart';
import 'screens/monthly_review_screen.dart';
import 'screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final settingsBox = Hive.box<LifeSettings>('settings');
  final hasSettings = settingsBox.isNotEmpty;

  return GoRouter(
    initialLocation: hasSettings ? '/home' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/project/:id',
        builder: (context, state) =>
            ProjectDetailScreen(projectId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/monthly-review',
        builder: (context, state) => const MonthlyReviewScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
