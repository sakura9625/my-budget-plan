import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/calculation_provider.dart';
import '../providers/review_provider.dart';
import '../theme.dart';
import '../utils/formatter.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calc = ref.watch(calculationProvider);
    final reviews = ref.watch(reviewProvider);
    final hasReview = ref.read(reviewProvider.notifier).hasCurrentMonthReview;

    if (calc == null) {
      return const Scaffold(
        body: Center(child: Text('設定を完了してください')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Budget Plan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeadline(context, calc.headline),
          const SizedBox(height: 16),
          _buildFreeAmountCard(context, calc),
          const SizedBox(height: 16),
          if (calc.budgetCalculations.isNotEmpty) ...[
            _buildSectionTitle(context, '予算'),
            const SizedBox(height: 8),
            ...calc.budgetCalculations.map((b) => _buildBudgetCard(context, b)),
            const SizedBox(height: 16),
          ],
          _buildSectionTitle(context, '年間計画'),
          const SizedBox(height: 8),
          _buildOverallCard(context, calc),
          const SizedBox(height: 16),
          if (calc.goalCalculations.isNotEmpty) ...[
            _buildSectionTitle(context, 'プロジェクト・貯蓄'),
            const SizedBox(height: 8),
            ..._sortedGoals(calc).map((g) => _buildGoalCard(context, g)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  List<GoalCalculation> _sortedGoals(CalculationResult calc) {
    final order = [
      PlanStatus.difficult,
      PlanStatus.needsReview,
      PlanStatus.danger,
      PlanStatus.safe,
      PlanStatus.onTrack,
      PlanStatus.comfortable,
    ];
    final sorted = [...calc.goalCalculations];
    sorted.sort((a, b) =>
        order.indexOf(a.planStatus).compareTo(order.indexOf(b.planStatus)));
    return sorted;
  }

  Widget _buildHeadline(BuildContext context, String headline) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              headline,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeAmountCard(BuildContext context, CalculationResult calc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF7B8AF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('月間自由枠',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            Formatter.man(calc.monthlyFreeAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryChip('年間自由資金', Formatter.man(calc.annualFreeMoney)),
              const SizedBox(width: 16),
              _summaryChip('年間自由枠', Formatter.man(calc.annualFreeAmount)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildBudgetCard(BuildContext context, BudgetCalculation b) {
    final color = AppTheme.budgetStatusColor(b.status);
    final label = AppTheme.budgetStatusLabel(b.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(b.budget.emoji ?? '💰',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.budget.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('月額 ${Formatter.man(b.budget.monthlyAmount)}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('利用済 ${Formatter.man(b.budget.usedAmount)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text('残り ${Formatter.man(b.remainingAmount)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: b.usageRate.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallCard(BuildContext context, CalculationResult calc) {
    final color = AppTheme.planStatusColor(calc.overallPlanStatus);
    final label = AppTheme.planStatusLabel(calc.overallPlanStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('全体進捗',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
                Text(
                  '${(calc.totalOverallProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('計画進捗',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
                Text(
                  '${(calc.totalPlanProgress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalCalculation g) {
    final color = AppTheme.planStatusColor(g.planStatus);
    final label = AppTheme.planStatusLabel(g.planStatus);
    final progress = g.overallProgress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(g.goal.emoji ?? '🎯',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.goal.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      g.goal.type.toString() == 'GoalType.saving'
                          ? '貯蓄'
                          : 'プロジェクト',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Formatter.man(g.displayAmount)} / ${Formatter.man(g.goal.targetAmount)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '全体 ${(g.overallProgress * 100).toStringAsFixed(0)}% / 計画 ${(g.planProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          if (g.remainingMonths > 0) ...[
            const SizedBox(height: 4),
            Text(
              '必要月額 ${Formatter.man(g.requiredMonthlyAmount)} / 残${g.remainingMonths}ヶ月',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontSize: 15));
  }
}
