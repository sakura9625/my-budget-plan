import 'goal.dart';

// 未来シミュレーションの条件タイプ。
enum SimulationType {
  addGoal,        // 新しいプロジェクトを追加
  editGoal,       // 既存プロジェクトを変更
  editBudget,     // 予算月額を変更
  reduceBalance,  // 大きな買い物をする（残高を減らす）
  changeGoalStatus, // プロジェクトを断念（凍結は無し）
  changeFixedCost,  // 固定費を変更
}

// シミュレーション条件。本丸データ（settings/goals/budgets）に対して
// 「何を変えるか」だけを表す差分データ。実際の再計算・一時データ構築は次のステップで行う。
sealed class SimulationCondition {
  final String id;
  const SimulationCondition({required this.id});

  SimulationType get type;
}

// 新しいプロジェクトを追加
class AddGoalCondition extends SimulationCondition {
  final String name;
  final GoalType goalType;
  final double targetAmount;
  final int startYear;
  final int startMonth;
  final int endYear;
  final int endMonth;
  final String? emoji;
  final String? memo;

  const AddGoalCondition({
    required super.id,
    required this.name,
    required this.goalType,
    required this.targetAmount,
    required this.startYear,
    required this.startMonth,
    required this.endYear,
    required this.endMonth,
    this.emoji,
    this.memo,
  });

  @override
  SimulationType get type => SimulationType.addGoal;
}

// 既存プロジェクトを変更、もしくは削除。種別(GoalType)は変更対象外なので持たない：
// 適用時は対象Goalの元の種別をそのまま引き継ぐ。それ以外のフィールドは編集後の値を
// そのまま持つ（フォームは常に現在値をプリフィルして丸ごと編集する方式のため、
// 差分ではなく新しい値）。isDeleteがtrueの場合、他フィールドは無視され、
// 適用時はgoals配列から対象を除外する（断念とは別物：断念は年間計算に残すが、
// 削除はプロジェクト自体を無かったことにする）。
class EditGoalCondition extends SimulationCondition {
  final String goalId;
  final String name;
  final double targetAmount;
  final int startYear;
  final int startMonth;
  final int endYear;
  final int endMonth;
  final String? emoji;
  final String? memo;
  final bool isDelete;

  const EditGoalCondition({
    required super.id,
    required this.goalId,
    required this.name,
    required this.targetAmount,
    required this.startYear,
    required this.startMonth,
    required this.endYear,
    required this.endMonth,
    this.emoji,
    this.memo,
    this.isDelete = false,
  });

  @override
  SimulationType get type => SimulationType.editGoal;
}

// 予算月額を変更、もしくは削除。フォームは常に現在値をプリフィルして丸ごと編集する
// 方式のため、差分ではなく編集後の値をそのまま持つ（EditGoalConditionと同じ考え方）。
// isDeleteがtrueの場合、他フィールドは無視され、適用時はbudgets配列から対象を除外する。
class EditBudgetCondition extends SimulationCondition {
  final String budgetId;
  final String name;
  final double monthlyAmount;
  final int startYear;
  final int startMonth;
  final int endYear;
  final int endMonth;
  final bool isDelete;

  const EditBudgetCondition({
    required super.id,
    required this.budgetId,
    required this.name,
    required this.monthlyAmount,
    required this.startYear,
    required this.startMonth,
    required this.endYear,
    required this.endMonth,
    this.isDelete = false,
  });

  @override
  SimulationType get type => SimulationType.editBudget;
}

// 大きな買い物をする（残高を一時的に減らす）
class ReduceBalanceCondition extends SimulationCondition {
  final String purchaseName;
  final double amount;

  const ReduceBalanceCondition({
    required super.id,
    required this.purchaseName,
    required this.amount,
  });

  @override
  SimulationType get type => SimulationType.reduceBalance;
}

// プロジェクトを断念（凍結は選択肢に無い）
class ChangeGoalStatusCondition extends SimulationCondition {
  final String goalId;
  final String goalName;
  final GoalStatus newStatus;

  const ChangeGoalStatusCondition({
    required super.id,
    required this.goalId,
    required this.goalName,
    required this.newStatus,
  });

  @override
  SimulationType get type => SimulationType.changeGoalStatus;
}

// 固定費を変更
class ChangeFixedCostCondition extends SimulationCondition {
  final double newAnnualFixedCost;

  const ChangeFixedCostCondition({
    required super.id,
    required this.newAnnualFixedCost,
  });

  @override
  SimulationType get type => SimulationType.changeFixedCost;
}
