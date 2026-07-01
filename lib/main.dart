import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/goal.dart';
import 'models/budget.dart';
import 'models/manual_entry.dart';
import 'models/budget_entry.dart';
import 'models/app_settings.dart';
import 'models/review.dart';

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

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('準備中')),
      ),
    );
  }
}
