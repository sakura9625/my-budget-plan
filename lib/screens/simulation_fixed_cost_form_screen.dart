import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/simulation.dart';
import '../providers/settings_provider.dart';
import '../providers/simulation_provider.dart';
import '../theme.dart';
import '../utils/formatter.dart';

// 「固定費を変更」の入力フォーム。既存の設定画面の「年間固定費（万円）」と同じ形式。
class SimulationFixedCostFormScreen extends ConsumerStatefulWidget {
  const SimulationFixedCostFormScreen({super.key});

  @override
  ConsumerState<SimulationFixedCostFormScreen> createState() =>
      _SimulationFixedCostFormScreenState();
}

class _SimulationFixedCostFormScreenState
    extends ConsumerState<SimulationFixedCostFormScreen> {
  final _amountController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final annualIncome = settings?.annualIncome ?? 0;
    final amount = double.tryParse(_amountController.text);
    final exceedsIncome = amount != null && amount > annualIncome;

    return Scaffold(
      appBar: AppBar(title: const Text('固定費を変更')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('変更後の年間固定費（万円）',
                style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '例：300', suffixText: '万円'),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
            ],
            if (exceedsIncome) ...[
              const SizedBox(height: 8),
              Text(
                '年間手取り（${Formatter.man(annualIncome)}）を超えています。'
                '登録はできますが、月間自由枠は大きくマイナスになります。',
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
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 0) {
      setState(() => _error = '固定費は0以上で入力してください。');
      return;
    }
    ref.read(simulationConditionsProvider.notifier).add(
          ChangeFixedCostCondition(
            id: const Uuid().v4(),
            newAnnualFixedCost: amount,
          ),
        );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
