// applySimulationToRealData()が実データ（Hive）を正しく更新するかを検証する。
// UIを介さず、実際のHiveボックス相手に書き込み・読み出しを行い、
// 「断念の反映が計画タブに出ない」「固定費変更が設定タブに出ない」という
// 報告されたバグが、書き込み処理自体の不具合なのか、UI側の表示不具合なのかを切り分ける。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:my_budget_plan/models/app_settings.dart';
import 'package:my_budget_plan/models/goal.dart';
import 'package:my_budget_plan/models/budget.dart';
import 'package:my_budget_plan/models/simulation.dart';
import 'package:my_budget_plan/providers/budget_provider.dart';
import 'package:my_budget_plan/providers/goal_provider.dart';
import 'package:my_budget_plan/providers/settings_provider.dart';
import 'package:my_budget_plan/providers/simulation_engine.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    Hive.registerAdapter(GoalTypeAdapter());
    Hive.registerAdapter(GoalStatusAdapter());
    Hive.registerAdapter(GoalAdapter());
    Hive.registerAdapter(BudgetAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test');
    Hive.init(tempDir.path);
    await Hive.openBox<Goal>('goals');
    await Hive.openBox<Budget>('budgets');
    await Hive.openBox<AppSettings>('settings');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    tempDir.deleteSync(recursive: true);
  });

  test('固定費変更を反映するとsettingsの実データが更新される', () async {
    final settingsNotifier = SettingsNotifier();
    final goalNotifier = GoalNotifier();
    final budgetNotifier = BudgetNotifier();

    await settingsNotifier.save(AppSettings(
      annualIncome: 500,
      annualFixedCost: 200,
    ));

    final condition = ChangeFixedCostCondition(
      id: const Uuid().v4(),
      newAnnualFixedCost: 250,
    );

    await applySimulationToRealData(
      [condition],
      currentSettings: settingsNotifier.state,
      currentGoals: goalNotifier.state,
      currentBudgets: budgetNotifier.state,
      settingsNotifier: settingsNotifier,
      goalNotifier: goalNotifier,
      budgetNotifier: budgetNotifier,
    );

    expect(settingsNotifier.state?.annualFixedCost, 250);

    // Hiveボックスに直接書かれているかも確認（notifierのstateだけでなく実データ自体）。
    final boxValue = Hive.box<AppSettings>('settings').getAt(0);
    expect(boxValue?.annualFixedCost, 250);
  });

  test('断念を反映するとgoalの実データがabandonedになる', () async {
    final settingsNotifier = SettingsNotifier();
    final goalNotifier = GoalNotifier();
    final budgetNotifier = BudgetNotifier();

    final goal = Goal(
      id: 'goal-1',
      type: GoalType.project,
      name: '旅行',
      targetAmount: 100,
      startYear: 2026,
      startMonth: 1,
      endYear: 2026,
      endMonth: 12,
      createdAt: DateTime(2026, 1, 1),
    );
    await goalNotifier.add(goal);

    final condition = ChangeGoalStatusCondition(
      id: const Uuid().v4(),
      goalId: 'goal-1',
      goalName: '旅行',
      newStatus: GoalStatus.abandoned,
    );

    await applySimulationToRealData(
      [condition],
      currentSettings: settingsNotifier.state,
      currentGoals: goalNotifier.state,
      currentBudgets: budgetNotifier.state,
      settingsNotifier: settingsNotifier,
      goalNotifier: goalNotifier,
      budgetNotifier: budgetNotifier,
    );

    final updatedGoal = goalNotifier.state.firstWhere((g) => g.id == 'goal-1');
    expect(updatedGoal.status, GoalStatus.abandoned);

    // Hiveボックスに直接書かれているかも確認。
    final boxValue = Hive.box<Goal>('goals').get('goal-1');
    expect(boxValue?.status, GoalStatus.abandoned);
  });
}
