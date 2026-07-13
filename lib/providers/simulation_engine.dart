import '../models/app_settings.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/simulation.dart';

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
