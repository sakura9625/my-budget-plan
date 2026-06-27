import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/life_settings.dart';
import 'models/project.dart';
import 'models/funding_entry.dart';
import 'models/monthly_review.dart';
import 'router.dart';
import 'theme.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(LifeSettingsAdapter());
  Hive.registerAdapter(ProjectStatusAdapter());
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(FundingEntryAdapter());
  Hive.registerAdapter(MonthlyReviewAdapter());

  await Hive.openBox<LifeSettings>('settings');
  await Hive.openBox<Project>('projects');
  await Hive.openBox<FundingEntry>('funding_entries');
  await Hive.openBox<MonthlyReview>('monthly_reviews');

  await NotificationService.init();
  await NotificationService.scheduleMonthlyReviewReminder();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'My Budget Plan',
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
