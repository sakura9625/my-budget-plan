import '../models/app_settings.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/simulation.dart';
import 'budget_provider.dart';
import 'goal_provider.dart';
import 'settings_provider.dart';

// 未来シミュレーション用に、本丸のAppSettingsへ登録済み条件を適用した複製を作る。
// calculatePlan自体は変更せず、渡すデータだけを差し替えるための土台。
// 対応：固定費変更（changeFixedCost）・大きな買い物（reduceBalance）。
AppSettings buildSimulatedSettings(
  AppSettings settings,
  List<SimulationCondition> conditions,
) {
  // 固定費変更は選択肢としては1件の想定だが、複数登録された場合は最後の登録を採用する。
  final fixedCostConditions =
      conditions.whereType<ChangeFixedCostCondition>().toList();
  final simulatedFixedCost = fixedCostConditions.isEmpty
      ? settings.annualFixedCost
      : fixedCostConditions.last.newAnnualFixedCost;

  // 複数の残高減額条件があれば合算して引く。
  final totalReduction = conditions
      .whereType<ReduceBalanceCondition>()
      .fold(0.0, (sum, c) => sum + c.amount);
  // マイナス残高にはしない（下限0）。
  final simulatedBalance =
      (settings.totalBalance - totalReduction).clamp(0.0, double.infinity);

  return AppSettings(
    annualIncome: settings.annualIncome,
    annualFixedCost: simulatedFixedCost,
    reviewDay: settings.reviewDay,
    notificationEnabled: settings.notificationEnabled,
    notificationHour: settings.notificationHour,
    notificationMinute: settings.notificationMinute,
    initialSetupCompleted: settings.initialSetupCompleted,
    totalBalance: simulatedBalance,
  );
}

// 未来シミュレーション用に、本丸のgoalsへ登録済み条件を適用した複製を作る。
// 適用順序：既存プロジェクト変更 → 断念 → 新規プロジェクト追加。
// （固定費・予算月額はgoalsに関係しないためここでは扱わない）
// 対象IDが重複しないよう、選択画面側で「既に変更/断念登録済みのPJT」を除外している前提。
List<Goal> buildSimulatedGoals(
  List<Goal> goals,
  List<SimulationCondition> conditions,
) {
  final result = [...goals];

  for (final c in conditions.whereType<EditGoalCondition>()) {
    final index = result.indexWhere((g) => g.id == c.goalId);
    if (index == -1) continue;
    if (c.isDelete) {
      // 削除はプロジェクト自体を無かったことにする（断念とは別物、配列から除外）。
      result.removeAt(index);
      continue;
    }
    final original = result[index];
    result[index] = Goal(
      id: original.id,
      type: original.type, // 種別は変更対象外。元の値を引き継ぐ。
      name: c.name,
      targetAmount: c.targetAmount,
      startYear: c.startYear,
      startMonth: c.startMonth,
      endYear: c.endYear,
      endMonth: c.endMonth,
      manualAmount: original.manualAmount, // 確保済み金額は現在値を引き継ぐ
      status: original.status,
      emoji: c.emoji ?? original.emoji,
      memo: c.memo ?? original.memo,
      createdAt: original.createdAt,
    );
  }

  for (final c in conditions.whereType<ChangeGoalStatusCondition>()) {
    final index = result.indexWhere((g) => g.id == c.goalId);
    if (index == -1) continue;
    final original = result[index];
    result[index] = Goal(
      id: original.id,
      type: original.type,
      name: original.name,
      targetAmount: original.targetAmount,
      startYear: original.startYear,
      startMonth: original.startMonth,
      endYear: original.endYear,
      endMonth: original.endMonth,
      manualAmount: original.manualAmount,
      status: c.newStatus,
      emoji: original.emoji,
      memo: original.memo,
      createdAt: original.createdAt,
    );
  }

  for (final c in conditions.whereType<AddGoalCondition>()) {
    result.add(Goal(
      id: c.id,
      type: c.goalType,
      name: c.name,
      targetAmount: c.targetAmount,
      startYear: c.startYear,
      startMonth: c.startMonth,
      endYear: c.endYear,
      endMonth: c.endMonth,
      manualAmount: 0,
      status: GoalStatus.active,
      emoji: c.emoji ?? (c.goalType == GoalType.saving ? '💰' : '🎯'),
      memo: c.memo,
      createdAt: DateTime.now(),
    ));
  }

  return result;
}

// 未来シミュレーション用に、本丸のbudgetsへ登録済み条件（editBudget）を適用した複製を作る。
// 対象IDが重複しないよう、選択画面側で「既に変更登録済みの予算」を除外している前提。
List<Budget> buildSimulatedBudgets(
  List<Budget> budgets,
  List<SimulationCondition> conditions,
) {
  final result = [...budgets];

  for (final c in conditions.whereType<EditBudgetCondition>()) {
    final index = result.indexWhere((b) => b.id == c.budgetId);
    if (index == -1) continue;
    if (c.isDelete) {
      result.removeAt(index);
      continue;
    }
    final original = result[index];
    result[index] = Budget(
      id: original.id,
      name: c.name,
      monthlyAmount: c.monthlyAmount,
      startYear: c.startYear,
      startMonth: c.startMonth,
      endYear: c.endYear,
      endMonth: c.endMonth,
      usedAmount: original.usedAmount, // 利用済み金額は現在値を引き継ぐ
      emoji: original.emoji,
      memo: original.memo,
      createdAt: original.createdAt,
    );
  }

  return result;
}

// 「現在の計画へ反映」で、登録済みのシミュレーション条件を本丸データ
// （settings/goals/budgets）へ直接書き込む。プレビュー用のbuildSimulatedX系は
// 複製に対する計算専用のため使い回さず、ここでは各Hiveプロバイダのadd/update/delete
// を条件タイプごとに呼び分ける。
// WidgetRefではなく各StateNotifierと現在値のスナップショットを直接受け取る形に
// しているのは、Riverpodのウィジェット文脈に依存せずテストしやすくするため。
// StateNotifier.stateは保護メンバーのためここでは読まず、渡されたスナップショットを
// ローカルにコピーして、各条件を適用するたびに手動で追随させる
// （後続ループが前のループの変更を正しく参照できるようにするため）。
// 残高減額（reduceBalance）は反映対象外：実際の残高は購入後の次回レビューで
// 反映してもらう運用のため、ここでは何もしない（呼び出し側で案内を出す）。
Future<void> applySimulationToRealData(
  List<SimulationCondition> conditions, {
  required AppSettings? currentSettings,
  required List<Goal> currentGoals,
  required List<Budget> currentBudgets,
  required SettingsNotifier settingsNotifier,
  required GoalNotifier goalNotifier,
  required BudgetNotifier budgetNotifier,
}) async {
  // 固定費変更：複数登録されていれば最後の登録を採用する（プレビューと同じ扱い）。
  final fixedCostConditions =
      conditions.whereType<ChangeFixedCostCondition>().toList();
  if (fixedCostConditions.isNotEmpty && currentSettings != null) {
    await settingsNotifier.save(AppSettings(
      annualIncome: currentSettings.annualIncome,
      annualFixedCost: fixedCostConditions.last.newAnnualFixedCost,
      reviewDay: currentSettings.reviewDay,
      notificationEnabled: currentSettings.notificationEnabled,
      notificationHour: currentSettings.notificationHour,
      notificationMinute: currentSettings.notificationMinute,
      initialSetupCompleted: currentSettings.initialSetupCompleted,
      totalBalance: currentSettings.totalBalance,
    ));
  }

  final goals = [...currentGoals];

  // 既存プロジェクトを変更、もしくは削除
  for (final c in conditions.whereType<EditGoalCondition>()) {
    if (c.isDelete) {
      await goalNotifier.delete(c.goalId);
      goals.removeWhere((g) => g.id == c.goalId);
      continue;
    }
    final index = goals.indexWhere((g) => g.id == c.goalId);
    if (index == -1) continue;
    final original = goals[index];
    final updated = Goal(
      id: original.id,
      type: original.type, // 種別は変更対象外。元の値を引き継ぐ。
      name: c.name,
      targetAmount: c.targetAmount,
      startYear: c.startYear,
      startMonth: c.startMonth,
      endYear: c.endYear,
      endMonth: c.endMonth,
      manualAmount: original.manualAmount,
      status: original.status,
      emoji: c.emoji ?? original.emoji,
      memo: c.memo ?? original.memo,
      createdAt: original.createdAt,
    );
    await goalNotifier.update(updated);
    goals[index] = updated;
  }

  // プロジェクトを断念
  for (final c in conditions.whereType<ChangeGoalStatusCondition>()) {
    final index = goals.indexWhere((g) => g.id == c.goalId);
    if (index == -1) continue;
    final original = goals[index];
    final updated = Goal(
      id: original.id,
      type: original.type,
      name: original.name,
      targetAmount: original.targetAmount,
      startYear: original.startYear,
      startMonth: original.startMonth,
      endYear: original.endYear,
      endMonth: original.endMonth,
      manualAmount: original.manualAmount,
      status: c.newStatus,
      emoji: original.emoji,
      memo: original.memo,
      createdAt: original.createdAt,
    );
    await goalNotifier.update(updated);
    goals[index] = updated;
  }

  // 新しいプロジェクトを追加
  for (final c in conditions.whereType<AddGoalCondition>()) {
    final newGoal = Goal(
      id: c.id,
      type: c.goalType,
      name: c.name,
      targetAmount: c.targetAmount,
      startYear: c.startYear,
      startMonth: c.startMonth,
      endYear: c.endYear,
      endMonth: c.endMonth,
      manualAmount: 0,
      status: GoalStatus.active,
      emoji: c.emoji ?? (c.goalType == GoalType.saving ? '💰' : '🎯'),
      memo: c.memo,
      createdAt: DateTime.now(),
    );
    await goalNotifier.add(newGoal);
    goals.add(newGoal);
  }

  final budgets = [...currentBudgets];

  // 予算月額を変更、もしくは削除
  for (final c in conditions.whereType<EditBudgetCondition>()) {
    if (c.isDelete) {
      await budgetNotifier.delete(c.budgetId);
      budgets.removeWhere((b) => b.id == c.budgetId);
      continue;
    }
    final index = budgets.indexWhere((b) => b.id == c.budgetId);
    if (index == -1) continue;
    final original = budgets[index];
    final updated = Budget(
      id: original.id,
      name: c.name,
      monthlyAmount: c.monthlyAmount,
      startYear: c.startYear,
      startMonth: c.startMonth,
      endYear: c.endYear,
      endMonth: c.endMonth,
      usedAmount: original.usedAmount,
      emoji: original.emoji,
      memo: original.memo,
      createdAt: original.createdAt,
    );
    await budgetNotifier.update(updated);
    budgets[index] = updated;
  }

  // 残高減額（大きな買い物）は反映対象外。実データの残高は変更しない。
}
