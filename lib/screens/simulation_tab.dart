import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation.dart';
import '../providers/simulation_provider.dart';
import '../theme.dart';
import '../utils/formatter.dart';
import '../widgets/pig_background_body.dart';
import 'simulation_condition_type_screen.dart';
import 'simulation_result_screen.dart';

// 未来シミュレーション トップ画面。
// 「現在のデータを変えずに、計画を変更した場合の影響を確認する」機能の入口。
// この段階では条件の追加・一覧・削除の器と画面遷移のみで、実際の再計算は行わない。
class SimulationTab extends ConsumerWidget {
  const SimulationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditions = ref.watch(simulationConditionsProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('未来シミュレーション'),
      ),
      body: PigBackgroundBody(
        pigAsset: 'pig_bank_rich.png',
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '計画を変更した場合の影響を、現在のデータを変えずに確認できます。',
              style: TextStyle(
                color: Color(0xFFC7CDDB),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (conditions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'まだ条件がありません。\n「条件を追加」から作成してください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ...conditions.map((c) => _ConditionCard(condition: c)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SimulationConditionTypeScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('条件を追加'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: conditions.isEmpty
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SimulationResultScreen(),
                      ),
                    );
                  },
            child: const Text('未来をシミュレーション'),
          ),
        ],
      ),
    );
  }
}

class _ConditionCard extends ConsumerWidget {
  final SimulationCondition condition;
  const _ConditionCard({required this.condition});

  String get _label {
    switch (condition) {
      case AddGoalCondition c:
        return '${c.name}を追加 ${Formatter.man(c.targetAmount)}';
      case EditGoalCondition c:
        return c.isDelete ? '${c.name} 削除' : '${c.name}に変更';
      case EditBudgetCondition c:
        return c.isDelete
            ? '${c.name} 削除'
            : '${c.name} 月額${Formatter.man(c.monthlyAmount)}に変更';
      case ReduceBalanceCondition c:
        return '${c.purchaseName} ${Formatter.man(c.amount)}';
      case ChangeGoalStatusCondition c:
        return '${c.goalName}を断念';
      case ChangeFixedCostCondition c:
        return '固定費を${Formatter.man(c.newAnnualFixedCost)}に変更';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(_label,
                style: const TextStyle(
                    color: AppTheme.textDark, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF6B7280), size: 20),
            onPressed: () {
              // 編集は「削除して選び直す」方式にする（重複登録を防ぐため）。
              ref
                  .read(simulationConditionsProvider.notifier)
                  .removeById(condition.id);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SimulationConditionTypeScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.danger, size: 20),
            onPressed: () => ref
                .read(simulationConditionsProvider.notifier)
                .removeById(condition.id),
          ),
        ],
      ),
    );
  }
}
