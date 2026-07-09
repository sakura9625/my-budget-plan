import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/goal.dart';
import 'models/budget.dart';
import 'models/manual_entry.dart';
import 'models/budget_entry.dart';
import 'models/app_settings.dart';
import 'models/review.dart';
import 'router.dart';
import 'theme.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(GoalTypeAdapter());
  Hive.registerAdapter(GoalStatusAdapter());
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(ManualEntryAdapter());
  Hive.registerAdapter(BudgetEntryAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(ReviewAdapter());

  await Hive.openBox<Goal>('goals');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<ManualEntry>('manual_entries');
  await Hive.openBox<BudgetEntry>('budget_entries');
  await Hive.openBox<AppSettings>('settings');
  await Hive.openBox<Review>('reviews');

  try {
    await NotificationService.init();
    final settingsBox = Hive.box<AppSettings>('settings');
    if (settingsBox.isNotEmpty) {
      final settings = settingsBox.getAt(0)!;
      if (settings.notificationEnabled) {
        await NotificationService.scheduleMonthlyReviewReminder(
            settings.reviewDay);
      }
    }
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

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
