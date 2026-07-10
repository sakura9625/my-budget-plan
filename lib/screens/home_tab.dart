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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('My Budget Plan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeadline(context, calc.headline),
          const SizedBox(height: 8),
          _buildAffordabilityDebugLabel(calc),
          const SizedBox(height: 20),
          _buildFreeAmountCard(context, calc),
          const SizedBox(height: 28),
          if (calc.budgetCalculations.isNotEmpty) ...[
            _buildSectionTitle(context, '予算'),
            const SizedBox(height: 10),
            ...calc.budgetCalculations.map((b) => _buildBudgetCard(context, b)),
            const SizedBox(height: 28),
          ],
          _buildSectionTitle(context, '年間計画'),
          const SizedBox(height: 10),
          _buildOverallCard(context, calc),
          const SizedBox(height: 28),
          if (calc.goalCalculations.isNotEmpty) ...[
            _buildSectionTitle(context, 'プロジェクト・貯蓄'),
            const SizedBox(height: 10),
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
          const Icon(Icons.lightbulb_outline, color: AppTheme.navy, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              headline,
              style: const TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [DEBUG] 原資の健全性判定の確認用表示。本組み込みは別途対応予定。
  Widget _buildAffordabilityDebugLabel(CalculationResult calc) {
    final status = calc.affordabilityStatus;
    if (status == null) {
      return const SizedBox.shrink();
    }
    final label = AppTheme.affordStatusLabel(status);
    final color = AppTheme.affordStatusColor(status);
    final bgColor = AppTheme.affordStatusBgColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '[DEBUG] 原資の健全性: $label '
        '(①動かせる金${Formatter.man(calc.movableFunds)} / 残高${Formatter.man(calc.totalBalance)} / '
        '②予算${Formatter.man(calc.affordBudget)}+③プロジェクト${Formatter.man(calc.affordProject)}'
        '=${Formatter.man(calc.affordBudget + calc.affordProject)} / ④自由枠${Formatter.man(calc.monthlyFreeAmount)})',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFreeAmountCard(BuildContext context, CalculationResult calc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('月間自由枠',
              style: TextStyle(color: AppTheme.navy.withOpacity(0.6), fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            Formatter.man(calc.monthlyFreeAmount),
            style: const TextStyle(
              color: AppTheme.navy,
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.navy.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'この金額を使い切った前提で、下記の進捗を計算しています。',
              style: TextStyle(
                color: AppTheme.navy,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: AppTheme.navy.withOpacity(0.6), fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildBudgetCard(BuildContext context, BudgetCalculation b) {
    final color = AppTheme.budgetStatusColor(b.status);
    final label = AppTheme.budgetStatusLabel(b.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    Text('月額 ${Formatter.man(b.currentMonthlyAmount)}',
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.budgetStatusBgColor(b.status),
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
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
    final hasNoGoals = calc.goalCalculations.isEmpty;

    if (hasNoGoals) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('📋', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('年間計画',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('計画なし',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  const Text('計画タブから貯蓄・プロジェクトを追加してください',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final color = AppTheme.planStatusColor(calc.overallPlanStatus ?? PlanStatus.safe);
    final label = AppTheme.planStatusLabel(calc.overallPlanStatus ?? PlanStatus.safe);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('全体進捗',
                        style: TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12)),
                    Text(
                      '${(calc.totalOverallProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark),
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
                            color: Color(0xFF6B7280), fontSize: 12)),
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
                  color: AppTheme.planStatusBgColor(
                      calc.overallPlanStatus ?? PlanStatus.safe),
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
          const Divider(height: 20),
          const Text(
            '毎月の自由枠を使い切った場合の計画達成見込みです。',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, height: 1.5),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    Text(
                      g.goal.type.toString() == 'GoalType.saving'
                          ? '貯蓄'
                          : 'プロジェクト',
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.planStatusBgColor(g.planStatus),
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
          _buildProgressWithPaceMarker(progress, g.plannedProgress, color),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Formatter.man(g.displayAmount)} / ${Formatter.man(g.goal.targetAmount)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                '全体 ${(g.overallProgress * 100).toStringAsFixed(0)}% / 計画 ${(g.planProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (g.remainingMonths > 0) ...[
            const SizedBox(height: 4),
            Text(
              '必要月額 ${Formatter.man(g.requiredMonthlyAmount)} / 残${g.remainingMonths}ヶ月',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              '※自由枠使用後の残高をもとに計算した見込み額です。',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13,
              color: Colors.white.withOpacity(0.75),
            ));
  }

  // 進捗バー＋「本来あるべき進捗位置」の点線マーカー
  Widget _buildProgressWithPaceMarker(
      double progress, double plannedProgress, Color color) {
    final markerPosition = plannedProgress.clamp(0.0, 1.0);
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final markerX = markerPosition * constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 2,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 8,
                  ),
                ),
              ),
              Positioned(
                left: (markerX - 0.75).clamp(0.0, constraints.maxWidth - 1.5),
                top: 0,
                child: const _DashedVerticalMarker(height: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ネイビーの点線マーカー（計画上あるべき進捗位置を示す）
class _DashedVerticalMarker extends StatelessWidget {
  final double height;
  const _DashedVerticalMarker({required this.height});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(1.5, height),
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.navy
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashHeight = 3.0;
    const dashSpace = 2.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0.75, y), Offset(0.75, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
