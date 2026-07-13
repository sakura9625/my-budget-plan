import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/goal.dart';
import '../models/simulation.dart';
import '../providers/goal_provider.dart';
import '../providers/simulation_provider.dart';
import '../theme.dart';
import 'simulation_goal_form_screen.dart';

// 「既存プロジェクトを変更」「プロジェクトを断念」共通の対象選択画面。
// 既に変更・断念のいずれかで登録済みのプロジェクトは、同一対象への重複変更を防ぐため
// 選択肢から除外する。
class SimulationGoalPickerScreen extends ConsumerWidget {
  final bool forStatusChange; // true: 断念用の選択、false: 変更用の選択
  const SimulationGoalPickerScreen({super.key, required this.forStatusChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalProvider);
    final conditions = ref.watch(simulationConditionsProvider);
    final targetedIds = {
      for (final c in conditions.whereType<EditGoalCondition>()) c.goalId,
      for (final c in conditions.whereType<ChangeGoalStatusCondition>()) c.goalId,
    };
    final selectable = goals.where((g) => !targetedIds.contains(g.id)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(forStatusChange ? '断念するプロジェクトを選択' : '対象プロジェクトを選択')),
      body: selectable.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '選べるプロジェクト・貯蓄がありません。\n（登録済み・断念登録済みは選択できません）',
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
                final goal = selectable[index];
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
                    leading: Text(goal.emoji ?? '🎯',
                        style: const TextStyle(fontSize: 22)),
                    title: Text(goal.name,
                        style: const TextStyle(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${goal.startYear}/${goal.startMonth} 〜 ${goal.endYear}/${goal.endMonth}'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => forStatusChange
                        ? _confirmAbandon(context, ref, goal)
                        : Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  SimulationGoalFormScreen(existingGoal: goal),
                            ),
                          ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmAbandon(BuildContext context, WidgetRef ref, Goal goal) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('プロジェクトを断念'),
        content: Text('「${goal.name}」を断念（シミュレーション上のみ）にしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(simulationConditionsProvider.notifier).add(
                    ChangeGoalStatusCondition(
                      id: const Uuid().v4(),
                      goalId: goal.id,
                      goalName: goal.name,
                      newStatus: GoalStatus.abandoned,
                    ),
                  );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('断念にする', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}
