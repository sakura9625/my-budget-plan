import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/simulation.dart';
import '../providers/settings_provider.dart';
import '../providers/simulation_provider.dart';
import '../theme.dart';
import '../utils/formatter.dart';

// 「大きな買い物をする（reduceBalance）」の入力フォーム。
// 他の5タイプは専用画面（simulation_goal_form_screen等）へ移行済みのため、
// このクラスは実質reduceBalance専用になっている（type分岐の他ケースは到達しない）。
class SimulationConditionFormScreen extends ConsumerStatefulWidget {
  final SimulationType type;
  const SimulationConditionFormScreen({super.key, required this.type});

  @override
  ConsumerState<SimulationConditionFormScreen> createState() =>
      _SimulationConditionFormScreenState();
}

class _SimulationConditionFormScreenState
    extends ConsumerState<SimulationConditionFormScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String? _amountError;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.type) {
      case SimulationType.addGoal:
        return '新しいプロジェクトを追加';
      case SimulationType.editGoal:
        return '既存プロジェクトを変更';
      case SimulationType.editBudget:
        return '予算月額を変更';
      case SimulationType.reduceBalance:
        return '大きな買い物をする';
      case SimulationType.changeGoalStatus:
        return 'プロジェクトを断念';
      case SimulationType.changeFixedCost:
        return '固定費を変更';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type != SimulationType.reduceBalance) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction,
                  color: AppTheme.textMuted, size: 40),
              const SizedBox(height: 16),
              const Text(
                'この条件の入力フォームは次のステップで実装します。',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLight),
              ),
            ],
          ),
        ),
      );
    }

    final settings = ref.watch(settingsProvider);
    final currentBalance = settings?.totalBalance ?? 0;
    final amount = double.tryParse(_amountController.text);
    final exceedsBalance = amount != null && amount > currentBalance;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('名称（任意）',
                style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: '例：車の頭金'),
            ),
            const SizedBox(height: 20),
            const Text('支出金額（万円）',
                style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '例：20',
                suffixText: '万円',
              ),
              onChanged: (_) => setState(() => _amountError = null),
            ),
            if (_amountError != null) ...[
              const SizedBox(height: 8),
              Text(_amountError!,
                  style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
            ],
            if (exceedsBalance) ...[
              const SizedBox(height: 8),
              Text(
                '現在残高（${Formatter.man(currentBalance)}）を超えています。'
                '計算上は残高0円までとして扱われます。',
                style: const TextStyle(color: AppTheme.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('登録'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount < 1) {
      setState(() => _amountError = '支出金額は1万円以上で入力してください。');
      return;
    }
    final name = _nameController.text.trim().isEmpty
        ? '大きな買い物'
        : _nameController.text.trim();
    ref.read(simulationConditionsProvider.notifier).add(
          ReduceBalanceCondition(
            id: const Uuid().v4(),
            purchaseName: name,
            amount: amount,
          ),
        );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
