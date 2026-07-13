import 'package:flutter/material.dart';
import '../models/simulation.dart';
import '../theme.dart';
import 'simulation_budget_picker_screen.dart';
import 'simulation_condition_form_screen.dart';
import 'simulation_fixed_cost_form_screen.dart';
import 'simulation_goal_form_screen.dart';
import 'simulation_goal_picker_screen.dart';

// 「条件を追加」で開く、条件タイプの選択画面。
// 各タイプをタップすると、そのタイプ用の入力フォームへ遷移する。全6タイプ実装済み。
class SimulationConditionTypeScreen extends StatelessWidget {
  const SimulationConditionTypeScreen({super.key});

  static const _options = [
    (type: SimulationType.addGoal, emoji: '🎯', label: '新しいプロジェクトを追加'),
    (type: SimulationType.editGoal, emoji: '✏️', label: '既存プロジェクトを変更'),
    (type: SimulationType.editBudget, emoji: '💰', label: '予算月額を変更'),
    (type: SimulationType.reduceBalance, emoji: '🛍️', label: '大きな買い物をする'),
    (type: SimulationType.changeGoalStatus, emoji: '💀', label: 'プロジェクトを断念'),
    (type: SimulationType.changeFixedCost, emoji: '🏠', label: '固定費を変更'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('条件を追加')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final option = _options[index];
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
              leading: Text(option.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(option.label,
                  style: const TextStyle(
                      color: AppTheme.textDark, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _screenFor(option.type),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _screenFor(SimulationType type) {
    switch (type) {
      case SimulationType.addGoal:
        return const SimulationGoalFormScreen();
      case SimulationType.editGoal:
        return const SimulationGoalPickerScreen(forStatusChange: false);
      case SimulationType.changeGoalStatus:
        return const SimulationGoalPickerScreen(forStatusChange: true);
      case SimulationType.editBudget:
        return const SimulationBudgetPickerScreen();
      case SimulationType.changeFixedCost:
        return const SimulationFixedCostFormScreen();
      case SimulationType.reduceBalance:
        return SimulationConditionFormScreen(type: type);
    }
  }
}
