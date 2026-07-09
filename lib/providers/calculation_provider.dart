import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/app_settings.dart';
import '../models/review.dart';
import 'goal_provider.dart';
import 'budget_provider.dart';
import 'settings_provider.dart';
import 'review_provider.dart';

// 判定ランク
enum PlanStatus {
  comfortable,  // 余裕 150%以上
  onTrack,      // 順調 120-149%
  safe,         // 安全 80-119%
  danger,       // 危険 60-79%
  needsReview,  // 見直し要請 40-59%
  difficult,    // 達成困難 39%以下
}

// 予算判定
enum BudgetStatus {
  comfortable,  // 余裕 0-79%
  safe,         // 安全 80-99%
  danger,       // 危険 100-119%
  overBudget,   // 自粛要請 120%以上
}

// 原資の健全性判定（口座残高で予算・プロジェクトの今月分＋バッファをまかなえるか）
enum AffordStatus {
  comfortable, // 余裕
  ok,          // 確保OK
  tight,       // 控えめに
  critical,    // 要自粛
}

// Goal計算結果
class GoalCalculation {
  final Goal goal;
  final double virtualAmount;
  final double displayAmount;
  final double overallProgress;
  final double planProgress;
  final double plannedProgress;
  final PlanStatus planStatus;
  final double requiredMonthlyAmount;
  final int remainingMonths;

  GoalCalculation({
    required this.goal,
    required this.virtualAmount,
    required this.displayAmount,
    required this.overallProgress,
    required this.planProgress,
    required this.plannedProgress,
    required this.planStatus,
    required this.requiredMonthlyAmount,
    required this.remainingMonths,
  });
}

// Budget計算結果
class BudgetCalculation {
  final Budget budget;
  final double usageRate;
  final BudgetStatus status;
  final double remainingAmount;

  BudgetCalculation({
    required this.budget,
    required this.usageRate,
    required this.status,
    required this.remainingAmount,
  });
}

// 全体計算結果
class CalculationResult {
  final double annualFreeMoney;
  final double monthlyFreeMoney;
  final double annualFreeAmount;
  final double monthlyFreeAmount;
  final double allocatableAmount;
  final List<GoalCalculation> goalCalculations;
  final List<BudgetCalculation> budgetCalculations;
  final double totalOverallProgress;
  final double totalPlanProgress;
  final PlanStatus? overallPlanStatus;
  final String headline;
  final bool hasCurrentMonthReview;
  final double affordBudget;
  final double affordProject;
  final AffordStatus? affordabilityStatus;
  final double totalBalance;

  CalculationResult({
    required this.annualFreeMoney,
    required this.monthlyFreeMoney,
    required this.annualFreeAmount,
    required this.monthlyFreeAmount,
    required this.allocatableAmount,
    required this.goalCalculations,
    required this.budgetCalculations,
    required this.totalOverallProgress,
    required this.totalPlanProgress,
    required this.overallPlanStatus,
    required this.headline,
    required this.hasCurrentMonthReview,
    required this.affordBudget,
    required this.affordProject,
    required this.affordabilityStatus,
    required this.totalBalance,
  });
}

final calculationProvider = Provider<CalculationResult?>((ref) {
  final settings = ref.watch(settingsProvider);
  final goals = ref.watch(goalProvider);
  final budgets = ref.watch(budgetProvider);
  final reviews = ref.watch(reviewProvider);

  if (settings == null) return null;

  return _calculate(settings, goals, budgets, reviews);
});

CalculationResult _calculate(
  AppSettings settings,
  List<Goal> goals,
  List<Budget> budgets,
  List<Review> reviews,
) {
  final now = DateTime.now();

  // 年間自由資金
  final annualFreeMoney = settings.annualFreeMoney;
  final monthlyFreeMoney = settings.monthlyFreeMoney;

  // 今年対象のGoal合計・Budget合計を計算
  final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList();

  double totalGoalAnnual = 0;
  for (final g in activeGoals) {
    final totalM = _totalMonths(g.startYear, g.startMonth, g.endYear, g.endMonth);
    if (totalM <= 0) continue;
    final months = _targetMonthsInYear(g.startYear, g.startMonth, g.endYear, g.endMonth, now.year);
    final monthly = g.targetAmount / totalM;
    totalGoalAnnual += monthly * months;
  }

  double totalBudgetAnnual = 0;
  for (final b in budgets) {
    final months = _targetMonthsInYear(b.startYear, b.startMonth, b.endYear, b.endMonth, now.year);
    totalBudgetAnnual += b.monthlyAmount * months;
  }

  // 年間自由枠は最低0（マイナスは警告表示用に保持）
  final annualFreeAmount = annualFreeMoney - totalGoalAnnual - totalBudgetAnnual;
  // 月間自由枠は年間自由枠を対象月数で割る（12固定ではなく残月数で割る）
  final now2 = DateTime.now();
  final remainingMonthsInYear = 13 - now2.month; // 今月含む残り月数
  final monthlyFreeAmount = annualFreeAmount / remainingMonthsInYear;

  // 現在の総残高（アプリ全体で1つ。設定・レビューで共通利用）
  final effectiveBalance = settings.totalBalance;

  // 目標配分可能額（マイナス許容）
  final allocatableAmount = effectiveBalance - monthlyFreeAmount;

  // Goal残額合計
  final totalGoalRemaining = activeGoals.fold(0.0, (sum, g) => sum + g.remainingAmount);

  // Goal計算
  final goalCalculations = activeGoals.map((goal) {
    final ratio = totalGoalRemaining > 0 ? goal.remainingAmount / totalGoalRemaining : 0.0;
    final virtualAmount = allocatableAmount * ratio;
    // 全体進捗は「現在の積立額 ÷ 目標額」。積立額は負にはならない（マイナスは0に床上げ）。
    final displayAmount = (goal.manualAmount + virtualAmount).clamp(0.0, double.infinity);
    final overallProgress = goal.targetAmount > 0 ? displayAmount / goal.targetAmount : 0.0;

    // 残月数
    final endMonthTotal = goal.endYear * 12 + goal.endMonth;
    final nowMonthTotal = now.year * 12 + now.month;
    final remainingMonths = (endMonthTotal - nowMonthTotal + 1).clamp(1, 9999);

    // 必要月額
    final remainingNeeded = (goal.targetAmount - displayAmount).clamp(0, double.infinity);
    final requiredMonthlyAmount = remainingNeeded / remainingMonths;

    // 計画進捗 = 実際の進捗 ÷ 本来あるべき進捗（経過期間 ÷ 全期間、開始月を1ヶ月目として数える）
    final totalMonths = _totalMonths(goal.startYear, goal.startMonth, goal.endYear, goal.endMonth);
    final elapsedMonths = (nowMonthTotal - (goal.startYear * 12 + goal.startMonth) + 1).clamp(1, totalMonths);
    final plannedProgress = totalMonths > 0 ? elapsedMonths / totalMonths : 0.0;
    // 開始直後（本来あるべき進捗が極小）は比率が発散するため、表示・判定上は200%で上限を設ける。
    final rawPlanProgress = plannedProgress > 0 ? overallProgress / plannedProgress : 0.0;
    final planProgress = rawPlanProgress.clamp(0.0, 2.0);

    debugPrint(
      '[calculation_provider] goal="${goal.name}" totalMonths=$totalMonths '
      'elapsedMonths=$elapsedMonths plannedProgress=$plannedProgress '
      'overallProgress=$overallProgress rawPlanProgress=$rawPlanProgress '
      'planProgress(clamped)=$planProgress',
    );

    final planStatus = _toPlanStatus(planProgress);

    return GoalCalculation(
      goal: goal,
      virtualAmount: virtualAmount,
      displayAmount: displayAmount,
      overallProgress: overallProgress,
      planProgress: planProgress,
      plannedProgress: plannedProgress,
      planStatus: planStatus,
      requiredMonthlyAmount: requiredMonthlyAmount,
      remainingMonths: remainingMonths,
    );
  }).toList();

  // Budget計算
  final budgetCalculations = budgets.map((budget) {
    final usageRate = budget.usageRate;
    final status = _toBudgetStatus(usageRate);
    final remainingAmount = budget.plannedAmount - budget.usedAmount;
    return BudgetCalculation(
      budget: budget,
      usageRate: usageRate,
      status: status,
      remainingAmount: remainingAmount,
    );
  }).toList();

  // 全体進捗
  final totalTarget = activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
  final totalDisplay = goalCalculations.fold(0.0, (sum, gc) => sum + gc.displayAmount);
  final totalOverallProgress = totalTarget > 0 ? totalDisplay / totalTarget : 0.0;

  // 全体計画進捗
  final totalPlanProgress = goalCalculations.isNotEmpty
      ? goalCalculations.fold(0.0, (sum, gc) => sum + gc.planProgress) / goalCalculations.length
      : 0.0;

  final hasNoGoals = activeGoals.isEmpty;

  final overallPlanStatus = hasNoGoals ? null : _toPlanStatus(totalPlanProgress);

  // 原資の健全性判定（口座残高で予算・プロジェクトの今月分をまかなえるか）
  final affordBudget = budgets.fold(0.0, (sum, b) => sum + b.monthlyAmount);
  final nowMonthTotalForAfford = now.year * 12 + now.month;
  double affordProject = 0;
  for (final gc in goalCalculations) {
    final rawRemaining =
        (gc.goal.endYear * 12 + gc.goal.endMonth) - nowMonthTotalForAfford + 1;
    if (rawRemaining <= 0) continue; // 期間終了済みのプロジェクトはゼロ割・過剰加算を避けるため除外
    affordProject += gc.requiredMonthlyAmount;
  }
  final buffer = settings.buffer;
  final affordabilityStatus = _toAffordabilityStatus(
      effectiveBalance, affordBudget, affordProject, buffer);

  debugPrint(
    '[calculation_provider] affordability balance=$effectiveBalance '
    'affordBudget=$affordBudget affordProject=$affordProject buffer=$buffer '
    'status=$affordabilityStatus',
  );

  // 今日のひと言
  final hasCurrentMonthReview = reviews.isNotEmpty &&
      reviews.first.year == now.year &&
      reviews.first.month == now.month;

  final headline = _buildHeadline(
    hasCurrentMonthReview,
    goalCalculations,
    budgetCalculations,
    overallPlanStatus,
    hasNoGoals,
  );

  debugPrint(
    '[calculation_provider] annualFreeMoney=$annualFreeMoney '
    'totalGoalAnnual=$totalGoalAnnual totalBudgetAnnual=$totalBudgetAnnual '
    'annualFreeAmount=$annualFreeAmount monthlyFreeAmount=$monthlyFreeAmount '
    'effectiveBalance=$effectiveBalance allocatableAmount=$allocatableAmount '
    'totalOverallProgress=$totalOverallProgress totalPlanProgress=$totalPlanProgress '
    'overallPlanStatus=$overallPlanStatus',
  );
  for (final gc in goalCalculations) {
    debugPrint(
      '[calculation_provider] goal="${gc.goal.name}" manualAmount=${gc.goal.manualAmount} '
      'virtualAmount=${gc.virtualAmount} displayAmount=${gc.displayAmount} '
      'overallProgress=${gc.overallProgress} planProgress=${gc.planProgress} '
      'planStatus=${gc.planStatus}',
    );
  }

  return CalculationResult(
    annualFreeMoney: annualFreeMoney,
    monthlyFreeMoney: monthlyFreeMoney,
    annualFreeAmount: annualFreeAmount,
    monthlyFreeAmount: monthlyFreeAmount,
    allocatableAmount: allocatableAmount,
    goalCalculations: goalCalculations,
    budgetCalculations: budgetCalculations,
    totalOverallProgress: totalOverallProgress,
    totalPlanProgress: totalPlanProgress,
    overallPlanStatus: overallPlanStatus,
    headline: headline,
    hasCurrentMonthReview: hasCurrentMonthReview,
    affordBudget: affordBudget,
    affordProject: affordProject,
    affordabilityStatus: affordabilityStatus,
    totalBalance: effectiveBalance,
  );
}

PlanStatus _toPlanStatus(double planProgress) {
  if (planProgress >= 1.5) return PlanStatus.comfortable;
  if (planProgress >= 1.2) return PlanStatus.onTrack;
  if (planProgress >= 0.8) return PlanStatus.safe;
  if (planProgress >= 0.6) return PlanStatus.danger;
  if (planProgress >= 0.4) return PlanStatus.needsReview;
  return PlanStatus.difficult;
}

// 原資の健全性判定：口座残高が「予算＋プロジェクトの今月分必要額」を
// まかなえているかを見る、残高ベースの独立した判定（予算バッジの利用率判定とは無関係）。
AffordStatus? _toAffordabilityStatus(double balance, double affordBudget,
    double affordProject, double buffer) {
  if (affordBudget <= 0 && affordProject <= 0) return null; // 予算・プロジェクトが0件
  final total = affordBudget + affordProject;
  if (balance >= total + buffer) return AffordStatus.comfortable;
  if (balance >= total) return AffordStatus.ok;
  if (balance >= affordBudget) return AffordStatus.tight;
  return AffordStatus.critical;
}

BudgetStatus _toBudgetStatus(double usageRate) {
  if (usageRate < 0.8) return BudgetStatus.comfortable;
  if (usageRate < 1.0) return BudgetStatus.safe;
  if (usageRate < 1.2) return BudgetStatus.danger;
  return BudgetStatus.overBudget;
}

String _buildHeadline(
  bool hasReview,
  List<GoalCalculation> goals,
  List<BudgetCalculation> budgets,
  PlanStatus? overallStatus,
  bool hasNoGoals,
) {
  if (!hasReview) return '今月のレビューがまだ完了していません。';
  if (hasNoGoals) return '貯蓄・プロジェクトを追加して計画を始めましょう。';
  if (goals.any((g) => g.planStatus == PlanStatus.difficult)) return '達成困難なプロジェクトがあります。';
  if (goals.any((g) => g.planStatus == PlanStatus.needsReview)) return '計画の見直しが必要なプロジェクトがあります。';
  if (budgets.any((b) => b.status == BudgetStatus.overBudget)) return '予算を超えているテーマがあります。自粛してください。';
  if (goals.any((g) => g.planStatus == PlanStatus.danger)) return '気をつけないと危ないプロジェクトがあります。';
  if (overallStatus == PlanStatus.comfortable) return '余裕があります。新しいプロジェクトを追加できるかもしれません。';
  if (overallStatus == PlanStatus.onTrack) return '順調です。このペースなら計画を前倒しできそうです。';
  return '計画は安全圏です。このペースを維持しましょう。';
}

int _totalMonths(int startYear, int startMonth, int endYear, int endMonth) {
  return (endYear * 12 + endMonth) - (startYear * 12 + startMonth) + 1;
}

int _targetMonthsInYear(int startYear, int startMonth, int endYear, int endMonth, int targetYear) {
  final yearStart = targetYear * 12 + 1;
  final yearEnd = targetYear * 12 + 12;
  final goalStart = startYear * 12 + startMonth;
  final goalEnd = endYear * 12 + endMonth;
  final overlapStart = goalStart < yearStart ? yearStart : goalStart;
  final overlapEnd = goalEnd > yearEnd ? yearEnd : goalEnd;
  return (overlapEnd - overlapStart + 1).clamp(0, 12);
}
