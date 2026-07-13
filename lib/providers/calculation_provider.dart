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
  // 複数PJT按分比率（ratio）専用の内部値。(目標−確保済み)÷残月数。
  // 割振り分ベースにすると循環（割振り分→必要月額→ratio→割振り分）が発生するため、
  // 按分比率の算出以外（表示・原資判定）にはdisplayRequiredMonthlyAmountを使うこと。
  final double requiredMonthlyAmount;
  // カード表示用・原資健全性判定（affordProject）用の「PJT必要月額」。
  // (目標−PJT割振り分−確保済み)÷残月数。全体進捗の分子（割振り分+確保済み）と揃えてある。
  final double displayRequiredMonthlyAmount;
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
    required this.displayRequiredMonthlyAmount,
    required this.remainingMonths,
  });
}

// Budget計算結果
class BudgetCalculation {
  final Budget budget;
  final double usageRate;
  final BudgetStatus status;
  final double remainingAmount;
  final int remainingMonths;
  final double currentMonthlyAmount;
  // 表示用「今月の目安」＝currentMonthlyAmountのクランプなし版（マイナス許容）。
  // 予算超過を「▲◯万円」表示するためだけに使う。計算にはcurrentMonthlyAmountを使うこと。
  final double displayCurrentMonthlyAmount;

  BudgetCalculation({
    required this.budget,
    required this.usageRate,
    required this.status,
    required this.remainingAmount,
    required this.remainingMonths,
    required this.currentMonthlyAmount,
    required this.displayCurrentMonthlyAmount,
  });
}

// 年間の額を月額に均す共通関数（月間自由枠の算出で使用、12固定）
double monthlyFromAnnual(double annualAmount) => annualAmount / 12;

// 全体計算結果
class CalculationResult {
  final double annualFreeMoney;
  final double monthlyFreeMoney;
  final double annualFreeAmount;
  final double monthlyFreeAmount;
  final double allocatableAmount;
  final double movableFunds;
  final List<GoalCalculation> goalCalculations;
  final List<BudgetCalculation> budgetCalculations;
  final double totalOverallProgress;
  final double totalPlanProgress;
  final PlanStatus? overallPlanStatus;
  final String headline;
  final bool hasCurrentMonthReview;
  final double affordBudget;
  final double displayAffordBudget;
  final double affordProject;
  final AffordStatus? affordabilityStatus;
  final double totalBalance;

  CalculationResult({
    required this.annualFreeMoney,
    required this.monthlyFreeMoney,
    required this.annualFreeAmount,
    required this.monthlyFreeAmount,
    required this.allocatableAmount,
    required this.movableFunds,
    required this.goalCalculations,
    required this.budgetCalculations,
    required this.totalOverallProgress,
    required this.totalPlanProgress,
    required this.overallPlanStatus,
    required this.headline,
    required this.hasCurrentMonthReview,
    required this.affordBudget,
    required this.displayAffordBudget,
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
  final nowMonthTotal = now.year * 12 + now.month;

  // 年間自由資金
  final annualFreeMoney = settings.annualFreeMoney;
  final monthlyFreeMoney = settings.monthlyFreeMoney;

  // 今年対象のGoal合計・Budget合計を計算
  // 年間自由枠の計算対象（進行中＋達成済み）。達成した瞬間に目標額が④の計算から
  // 消えて自由に使えるお金が増えたように見えるのを防ぐため、達成済みも含める。
  // 凍結・断念は含めない（目標額を自由枠へ戻す）。
  final annualPlanGoals = goals
      .where((g) =>
          g.status == GoalStatus.active || g.status == GoalStatus.completed)
      .toList();
  // 自動配分の計算対象（進行中のみ）。余剰金の配分・あるべき進捗額・確保済み合計など
  // 配分に関わる計算はこちらを使う。達成済み・凍結・断念は配分対象外。
  final allocationGoals =
      annualPlanGoals.where((g) => g.status == GoalStatus.active).toList();

  double totalGoalAnnual = 0;
  for (final g in annualPlanGoals) {
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
  // ④月間自由枠（表示用）は年間自由枠を12で割る。マイナスのまま保持し、
  // ホーム表示・アラート判定・原資判定にはこちらを使う（計画の無理さを示すため）。
  final monthlyFreeAmount = monthlyFromAnnual(annualFreeAmount);
  // ④月間自由枠（計算用）＝表示用の下限0版。余剰金の計算にのみ使う。
  // 表示用がマイナスのまま余剰金の計算に使われると、残高から負を引く形になり
  // 余剰金が過大になってしまうため、ここでのみ0でクランプする。
  final calculationMonthlyFreeAmount =
      monthlyFreeAmount.clamp(0.0, double.infinity);

  // 現在の総残高（アプリ全体で1つ。設定・レビューで共通利用）
  final effectiveBalance = settings.totalBalance;

  // Budget計算（②予算月額＝残額を残月数で繰り越し配分した値）
  final budgetCalculations = budgets.map((budget) {
    final usageRate = budget.usageRate;
    final status = _toBudgetStatus(usageRate);
    final remainingAmount = budget.plannedAmount - budget.usedAmount;
    final budgetEndMonthTotal = budget.endYear * 12 + budget.endMonth;
    final remainingMonths = (budgetEndMonthTotal - nowMonthTotal + 1).clamp(1, 9999);
    final rawCurrentMonthlyAmount = remainingAmount / remainingMonths;
    final currentMonthlyAmount = rawCurrentMonthlyAmount.clamp(0.0, double.infinity);
    return BudgetCalculation(
      budget: budget,
      usageRate: usageRate,
      status: status,
      remainingAmount: remainingAmount,
      remainingMonths: remainingMonths,
      currentMonthlyAmount: currentMonthlyAmount,
      displayCurrentMonthlyAmount: rawCurrentMonthlyAmount,
    );
  }).toList();

  // ②予算月額の合計（原資判定・PJT配分ポットの両方で使う。期間終了済みの予算は除外）
  double affordBudget = 0;
  // 表示用「予算枠」＝affordBudgetのクランプなし版（マイナス許容）。計算には使わない。
  double displayAffordBudget = 0;
  for (final bc in budgetCalculations) {
    final rawRemaining =
        (bc.budget.endYear * 12 + bc.budget.endMonth) - nowMonthTotal + 1;
    if (rawRemaining <= 0) continue; // 期間終了済みの予算は除外
    affordBudget += bc.currentMonthlyAmount;
    displayAffordBudget += bc.displayCurrentMonthlyAmount;
  }

  // Goal計算 第1段：配分（ratio/pot）に依存しない値を先に確定する
  // ③PJT必要月額＝(目標−確保済み)÷残月数、PJT積立分＝目標÷全期間月数×経過月数
  final goalIntermediates = allocationGoals.map((goal) {
    final startTotal = goal.startYear * 12 + goal.startMonth;
    final endTotal = goal.endYear * 12 + goal.endMonth;
    final totalMonths = _totalMonths(goal.startYear, goal.startMonth, goal.endYear, goal.endMonth);
    // 経過月数：開始前なら0（まだ積立を始めていない扱い）。開始後は(現在−開始+1)を
    // 0〜totalMonthsでクランプする（totalMonths<=0の異常値でも落ちないよう下限0でガード）。
    final elapsedMonths = nowMonthTotal < startTotal
        ? 0
        : (nowMonthTotal - startTotal + 1).clamp(0, totalMonths > 0 ? totalMonths : 0);
    // 残月数：起点を「開始月と現在の遅いほう」にする（開始前の期間を積立期間に含めない）。
    final calculationStart = nowMonthTotal < startTotal ? startTotal : nowMonthTotal;
    final remainingMonths = (endTotal - calculationStart + 1).clamp(1, 9999);
    final remainingNeeded = (goal.targetAmount - goal.manualAmount).clamp(0, double.infinity);
    final requiredMonthlyAmount = remainingNeeded / remainingMonths;
    final pjtAccumulated =
        totalMonths > 0 ? goal.targetAmount / totalMonths * elapsedMonths : 0.0;
    final plannedProgress = totalMonths > 0 ? elapsedMonths / totalMonths : 0.0;
    return (
      goal: goal,
      totalMonths: totalMonths,
      remainingMonths: remainingMonths,
      requiredMonthlyAmount: requiredMonthlyAmount,
      pjtAccumulated: pjtAccumulated,
      plannedProgress: plannedProgress,
    );
  }).toList();

  // あるべき進捗額合計・確保済み合計（全アクティブGoal合計）
  final sumPjtAccumulated = goalIntermediates.fold(0.0, (sum, gi) => sum + gi.pjtAccumulated);
  final sumManualAmount = allocationGoals.fold(0.0, (sum, g) => sum + g.manualAmount);

  // 余剰金＝MAX(0, 口座残高−④月間自由枠（計算用・下限0）−②予算月額)。マイナスにはしない。
  final surplus = (effectiveBalance - calculationMonthlyFreeAmount - affordBudget)
      .clamp(0.0, double.infinity);

  // PJT割振り分（全体）＝余剰金の大きさに応じた階段式で決定する。
  // 4段目（あるべき進捗額−確保済み）だけ確保済みを差し引き、他の段では差し引かない。
  // 4段目は確保済みが大きいとマイナスになり得るため、下限0でクランプする。
  final double rawGoalAllocatablePot;
  if (surplus > sumPjtAccumulated * 1.2) {
    rawGoalAllocatablePot = sumPjtAccumulated * 1.2;
  } else if (surplus > sumPjtAccumulated * 1.1) {
    rawGoalAllocatablePot = sumPjtAccumulated * 1.1;
  } else if (surplus > sumPjtAccumulated) {
    rawGoalAllocatablePot = sumPjtAccumulated;
  } else if (surplus > sumPjtAccumulated - sumManualAmount) {
    rawGoalAllocatablePot = sumPjtAccumulated - sumManualAmount;
  } else {
    rawGoalAllocatablePot = surplus;
  }
  final goalAllocatablePot = rawGoalAllocatablePot.clamp(0.0, double.infinity);

  // ①動かせるお金＝口座残高−PJT割振り分（全体）
  final movableFunds = effectiveBalance - goalAllocatablePot;

  // 比率(各Goal)＝requiredMonthlyAmount÷Σ(全activeGoalのrequiredMonthlyAmount)
  final sumRequiredMonthly =
      goalIntermediates.fold(0.0, (sum, gi) => sum + gi.requiredMonthlyAmount);

  // Goal計算 第2段：PJT割振り分（全体）を比率配分し、全体進捗などを確定する
  final goalCalculations = goalIntermediates.map((gi) {
    final goal = gi.goal;
    final ratio = sumRequiredMonthly > 0 ? gi.requiredMonthlyAmount / sumRequiredMonthly : 0.0;
    final virtualAmount = goalAllocatablePot * ratio;
    // 全体進捗の算出には床上げしない実額を使う（マイナス・200%超を許容、クランプしない）
    final rawAmount = goal.manualAmount + virtualAmount;
    // 表示用の積立額（金額表示）は0未満を床上げする
    final displayAmount = rawAmount.clamp(0.0, double.infinity);
    final overallProgress = goal.targetAmount > 0 ? rawAmount / goal.targetAmount : 0.0;

    // 計画進捗 = 実際の進捗 ÷ 本来あるべき進捗
    final rawPlanProgress = gi.plannedProgress > 0 ? overallProgress / gi.plannedProgress : 0.0;
    // 開始直後（本来あるべき進捗が極小）は比率が発散するため、表示・判定上は200%で上限を設ける。
    final planProgress = rawPlanProgress.clamp(0.0, 2.0);

    debugPrint(
      '[calculation_provider] goal="${goal.name}" totalMonths=${gi.totalMonths} '
      'plannedProgress=${gi.plannedProgress} '
      'overallProgress=$overallProgress rawPlanProgress=$rawPlanProgress '
      'planProgress(clamped)=$planProgress',
    );

    final planStatus = _toPlanStatus(planProgress);

    // PJT必要月額（表示用・原資判定用）＝(目標−PJT割振り分−確保済み)÷残月数。
    // 全体進捗の分子（割振り分+確保済み）と揃え、目標との差分を残月数で割る。
    final remainingNeededByAllocation =
        (goal.targetAmount - virtualAmount - goal.manualAmount).clamp(0.0, double.infinity);
    final displayRequiredMonthlyAmount =
        remainingNeededByAllocation / gi.remainingMonths;

    return GoalCalculation(
      goal: goal,
      virtualAmount: virtualAmount,
      displayAmount: displayAmount,
      overallProgress: overallProgress,
      planProgress: planProgress,
      plannedProgress: gi.plannedProgress,
      planStatus: planStatus,
      requiredMonthlyAmount: gi.requiredMonthlyAmount,
      displayRequiredMonthlyAmount: displayRequiredMonthlyAmount,
      remainingMonths: gi.remainingMonths,
    );
  }).toList();

  // 全体進捗＝金額ベース（実際進捗額合計÷目標額合計）。集計対象はallocationGoals
  // （進行中のみ。達成済み・凍結・断念は含めない）。床上げ済みdisplayAmountを使う。
  // ※全体計画進捗（あるべき進捗額ベース）とは別物：こちらは「目標に対する貯まり具合」。
  final totalTarget = allocationGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
  final totalDisplay = goalCalculations.fold(0.0, (sum, gc) => sum + gc.displayAmount);
  final totalOverallProgress = totalTarget > 0 ? totalDisplay / totalTarget : 0.0;

  // 全体計画進捗＝金額加重（実際進捗額合計÷あるべき進捗額合計）。単純平均だと
  // 金額の大きいPJTの遅れが金額の小さいPJTの進みに埋もれてしまうため、金額で重み付けする。
  // totalDisplay・sumPjtAccumulatedはいずれもallocationGoals（進行中のみ）由来。
  final totalPlanProgress = sumPjtAccumulated > 0
      ? (totalDisplay / sumPjtAccumulated).clamp(0.0, 2.0)
      : 0.0;

  final hasNoGoals = allocationGoals.isEmpty;

  final overallPlanStatus = hasNoGoals ? null : _toPlanStatus(totalPlanProgress);

  // ③PJT必要月額の合計＝displayRequiredMonthlyAmount（新・必要月額）の合計。
  // 按分比率用のrequiredMonthlyAmount（目標−確保済み）÷残月数）とは別物（循環回避のため据え置き）。
  // 期間終了済みのプロジェクトはゼロ割・過剰加算を避けるため除外。
  double affordProject = 0;
  for (final gc in goalCalculations) {
    final rawRemaining =
        (gc.goal.endYear * 12 + gc.goal.endMonth) - nowMonthTotal + 1;
    if (rawRemaining <= 0) continue;
    affordProject += gc.displayRequiredMonthlyAmount;
  }
  // 原資の健全性判定（①動かせる金で②③（＋④）をまかなえるか）
  final affordabilityStatus = _toAffordabilityStatus(
      movableFunds, affordBudget, affordProject, monthlyFreeAmount);

  debugPrint(
    '[calculation_provider] affordability movableFunds=$movableFunds '
    'affordBudget=$affordBudget affordProject=$affordProject monthlyFreeAmount=$monthlyFreeAmount '
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
    'effectiveBalance=$effectiveBalance surplus=$surplus '
    'sumPjtAccumulated(あるべき進捗額合計)=$sumPjtAccumulated sumManualAmount(確保済み合計)=$sumManualAmount '
    'goalAllocatablePot(PJT割振り分合計)=$goalAllocatablePot movableFunds(動かせるお金)=$movableFunds '
    'totalOverallProgress=$totalOverallProgress totalPlanProgress=$totalPlanProgress '
    'overallPlanStatus=$overallPlanStatus',
  );
  for (final gc in goalCalculations) {
    debugPrint(
      '[calculation_provider] goal="${gc.goal.name}" manualAmount=${gc.goal.manualAmount} '
      'virtualAmount=${gc.virtualAmount} displayAmount=${gc.displayAmount} '
      'overallProgress=${gc.overallProgress} planProgress=${gc.planProgress} '
      'planStatus=${gc.planStatus} '
      'displayRequiredMonthlyAmount=${gc.displayRequiredMonthlyAmount} '
      'remainingMonths=${gc.remainingMonths}',
    );
  }

  return CalculationResult(
    annualFreeMoney: annualFreeMoney,
    monthlyFreeMoney: monthlyFreeMoney,
    annualFreeAmount: annualFreeAmount,
    monthlyFreeAmount: monthlyFreeAmount,
    allocatableAmount: goalAllocatablePot,
    movableFunds: movableFunds,
    goalCalculations: goalCalculations,
    budgetCalculations: budgetCalculations,
    totalOverallProgress: totalOverallProgress,
    totalPlanProgress: totalPlanProgress,
    overallPlanStatus: overallPlanStatus,
    headline: headline,
    hasCurrentMonthReview: hasCurrentMonthReview,
    affordBudget: affordBudget,
    displayAffordBudget: displayAffordBudget,
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

// 原資の健全性判定：①動かせる金で「②予算月額＋③PJT必要月額」（＋④月間自由枠）を
// まかなえているかを見る、独立した判定（予算バッジの利用率判定とは無関係）。
// 境界値は余裕がある側（上の区分）に入れる：各区分の下限側は>=、上限側は<で統一。
AffordStatus? _toAffordabilityStatus(double movableFunds, double affordBudget,
    double affordProject, double monthlyFreeAmount) {
  if (affordBudget <= 0 && affordProject <= 0) return null; // 予算・プロジェクトが0件
  // 境界値は「余裕がある側（上の区分）」に入れるため、各区分の下限側は>=、上限側は<で統一する。
  final total = affordBudget + affordProject;
  final comfortable = movableFunds - total >= monthlyFreeAmount;
  final ok = movableFunds - affordBudget >= monthlyFreeAmount &&
      movableFunds - total < monthlyFreeAmount;
  final tight = movableFunds >= affordBudget &&
      movableFunds - affordBudget < monthlyFreeAmount;
  if (comfortable) return AffordStatus.comfortable;
  if (ok) return AffordStatus.ok;
  if (tight) return AffordStatus.tight;
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
