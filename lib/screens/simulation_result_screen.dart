import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/budget_provider.dart';
import '../providers/calculation_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/review_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/simulation_engine.dart';
import '../providers/simulation_provider.dart';
import '../theme.dart';
import '../utils/formatter.dart';

// 「計算する」で開く結果画面。Beforeは本丸データ、Afterは登録済み条件を適用した
// 複製データを、どちらも同じcalculatePlan()に渡した結果を左右分割デザインで比較表示する。
// 画面を左（現状・ネイビー）／右（シミュレーション結果・シアン）に2分割し、
// 各比較項目は左右にまたがる横長カード（左半分黄色・右半分白）＋中央の差分/判定バッジで表す。
class SimulationResultScreen extends ConsumerWidget {
  const SimulationResultScreen({super.key});

  static const _cyanBg = Color(0xFF00ACC1);
  static const _cardLeftFill = Color(0xFFFFF1B8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final before = ref.watch(calculationProvider);
    final settings = ref.watch(settingsProvider);
    final goals = ref.watch(goalProvider);
    final budgets = ref.watch(budgetProvider);
    final reviews = ref.watch(reviewProvider);
    final conditions = ref.watch(simulationConditionsProvider);

    if (before == null || settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('シミュレーション結果')),
        body: const Center(child: Text('設定を完了してください')),
      );
    }

    // 本丸データを複製し、登録済み条件（残高減額・固定費変更・既存PJT変更・断念・
    // 新規PJT追加・予算変更）を適用してAfterを計算する。
    // calculatePlan自体は変更せず、渡すデータだけを差し替えている。
    final simulatedSettings = buildSimulatedSettings(settings, conditions);
    final simulatedGoals = buildSimulatedGoals(goals, conditions);
    final simulatedBudgets = buildSimulatedBudgets(budgets, conditions);
    final after = calculatePlan(
      settings: simulatedSettings,
      goals: simulatedGoals,
      budgets: simulatedBudgets,
      reviews: reviews,
    );

    // Before/Afterで集合が異なりうる（新規追加はAfterのみ、断念はBeforeのみ）ため、
    // goal.idをキーに突き合わせて1枚のカードに両方（片方が無ければ「－」）を表示する。
    final beforeById = {for (final gc in before.goalCalculations) gc.goal.id: gc};
    final afterById = {for (final gc in after.goalCalculations) gc.goal.id: gc};
    final orderedIds = [
      ...before.goalCalculations.map((gc) => gc.goal.id),
      ...afterById.keys.where((id) => !beforeById.containsKey(id)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('シミュレーション結果')),
      body: Stack(
        children: [
          // 画面全体の左右分割背景（現状＝ネイビー／シミュレーション結果＝シアン）
          const Positioned.fill(
            child: Row(
              children: [
                Expanded(child: ColoredBox(color: AppTheme.navy)),
                Expanded(child: ColoredBox(color: _cyanBg)),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _headerPill('現状', Colors.white, AppTheme.textDark)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _headerPill(
                            'シミュレーション結果', AppTheme.danger, Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
                _amountCard('月間自由枠', before.monthlyFreeAmount, after.monthlyFreeAmount),
                const SizedBox(height: 12),
                _amountCard('動かせるお金', before.movableFunds, after.movableFunds),
                const SizedBox(height: 12),
                _statusCard(
                  '原資判定',
                  AppTheme.affordStatusLabel(before.affordabilityStatus),
                  AppTheme.affordStatusColor(before.affordabilityStatus),
                  AppTheme.affordStatusLabel(after.affordabilityStatus),
                  AppTheme.affordStatusColor(after.affordabilityStatus),
                ),
                const SizedBox(height: 12),
                _percentCard('全体進捗', before.totalOverallProgress, after.totalOverallProgress),
                const SizedBox(height: 12),
                _percentCard('計画進捗', before.totalPlanProgress, after.totalPlanProgress),
                const SizedBox(height: 20),
                const Text('プロジェクト・貯蓄',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 10),
                if (orderedIds.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('進行中のプロジェクト・貯蓄はありません。',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  )
                else
                  ...orderedIds.map((id) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _goalCard(beforeById[id], afterById[id]),
                      )),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.08)),
                  child: const Text('戻る'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('この機能は次のステップで実装します。')),
                    );
                  },
                  child: const Text('現在の計画へ反映'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _headerPill(String label, Color bg, Color fg) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  // 金額の差分：マイナス（減少）は▲、プラス（増加）は+で表示する。
  static String? _amountDiffLabel(double before, double after) {
    final diff = after - before;
    if (diff.round() == 0) return null;
    return diff < 0 ? '▲${Formatter.man(diff.abs())}' : '+${Formatter.man(diff)}';
  }

  static Widget _amountCard(String label, double before, double after) {
    final diff = _amountDiffLabel(before, after);
    return _CompareCard(
      title: label,
      beforeValue: Formatter.man(before),
      afterValue: Formatter.man(after),
      centerBadge: diff == null ? null : _diffBadge(diff),
    );
  }

  static Widget _percentCard(String label, double before, double after) {
    final beforePct = before * 100;
    final afterPct = after * 100;
    final diff = afterPct - beforePct;
    String? diffLabel;
    if (diff.abs() >= 0.05) {
      diffLabel = diff < 0
          ? '▲${diff.abs().toStringAsFixed(1)}pt'
          : '+${diff.toStringAsFixed(1)}pt';
    }
    return _CompareCard(
      title: label,
      beforeValue: '${beforePct.toStringAsFixed(1)}%',
      afterValue: '${afterPct.toStringAsFixed(1)}%',
      centerBadge: diffLabel == null ? null : _diffBadge(diffLabel),
    );
  }

  static Widget _statusCard(
      String label, String before, Color beforeColor, String after, Color afterColor) {
    return _CompareCard(
      title: label,
      beforeValue: before,
      afterValue: after,
      beforeValueColor: beforeColor,
      afterValueColor: afterColor,
      centerBadge: before == after
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('変化あり',
                  style: TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
            ),
    );
  }

  static Widget _diffBadge(String diff) {
    final isDown = diff.startsWith('▲');
    final color = isDown ? AppTheme.danger : AppTheme.success;
    final bg = isDown ? AppTheme.dangerBg : AppTheme.successBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(diff,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  static Widget _goalCard(GoalCalculation? beforeGc, GoalCalculation? afterGc) {
    final name = (afterGc ?? beforeGc)!.goal.name;
    final beforeValue = beforeGc == null
        ? '－'
        : '${Formatter.man(beforeGc.displayAmount)}/${Formatter.man(beforeGc.goal.targetAmount)}';
    final afterValue = afterGc == null
        ? '－'
        : '${Formatter.man(afterGc.displayAmount)}/${Formatter.man(afterGc.goal.targetAmount)}';

    Widget badge;
    if (afterGc != null) {
      final color =
          afterGc.hasStarted ? AppTheme.planStatusColor(afterGc.planStatus) : Colors.grey;
      final label = afterGc.hasStarted ? AppTheme.planStatusLabel(afterGc.planStatus) : '開始前';
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:
            BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
      );
    } else {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:
            BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
        child: const Text('断念',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
      );
    }

    return _CompareCard(
      title: name,
      beforeValue: beforeValue,
      afterValue: afterValue,
      centerBadge: badge,
    );
  }
}

// 比較項目1件の横長カード。左半分は黄色、右半分は白の塗り分け。
// 上に項目名、左右に現状/シミュレーション後の値、中央に差分または判定バッジを表示する。
class _CompareCard extends StatelessWidget {
  final String title;
  final String beforeValue;
  final String afterValue;
  final Color? beforeValueColor;
  final Color? afterValueColor;
  final Widget? centerBadge;

  const _CompareCard({
    required this.title,
    required this.beforeValue,
    required this.afterValue,
    this.beforeValueColor,
    this.afterValueColor,
    this.centerBadge,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                    child: ColoredBox(
                        color: SimulationResultScreen._cardLeftFill)),
                const Expanded(child: ColoredBox(color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(beforeValue,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: beforeValueColor ?? AppTheme.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                    ),
                    if (centerBadge != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: centerBadge,
                      )
                    else
                      const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: Text(afterValue,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: afterValueColor ?? AppTheme.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
