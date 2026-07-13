import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation.dart';
import '../providers/budget_provider.dart';
import '../providers/simulation_provider.dart';
import '../theme.dart';
import '../utils/formatter.dart';
import 'simulation_budget_form_screen.dart';

// 「予算月額を変更」の対象選択画面。既に変更登録済みの予算は、同一対象への
// 重複変更を防ぐため選択肢から除外する。
class SimulationBudgetPickerScreen extends ConsumerWidget {
  const SimulationBudgetPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetProvider);
    final conditions = ref.watch(simulationConditionsProvider);
    final targetedIds = {
      for (final c in conditions.whereType<EditBudgetCondition>()) c.budgetId,
    };
    final selectable =
        budgets.where((b) => !targetedIds.contains(b.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('対象予算を選択')),
      body: selectable.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '選べる予算がありません。\n（変更登録済みの予算は選択できません）',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textLight),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: selectable.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final budget = selectable[index];
                return Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Text(budget.emoji ?? '💰',
                        style: const TextStyle(fontSize: 22)),
                    title: Text(budget.name,
                        style: const TextStyle(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text('月額 ${Formatter.man(budget.monthlyAmount)}'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SimulationBudgetFormScreen(budget: budget),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
