import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/simulation.dart';
import '../providers/simulation_provider.dart';
import '../theme.dart';
import '../widgets/month_picker.dart';

// 「予算月額を変更」の入力フォーム。既存のBudget編集（plan_tab）と同じ項目
// （名前・月額・開始/終了年月）を、選択済みの予算の現在値でプリフィルする。
class SimulationBudgetFormScreen extends ConsumerStatefulWidget {
  final Budget budget;
  const SimulationBudgetFormScreen({super.key, required this.budget});

  @override
  ConsumerState<SimulationBudgetFormScreen> createState() =>
      _SimulationBudgetFormScreenState();
}

class _SimulationBudgetFormScreenState
    extends ConsumerState<SimulationBudgetFormScreen> {
  late final _nameController = TextEditingController(text: widget.budget.name);
  late final _amountController =
      TextEditingController(text: widget.budget.monthlyAmount.toStringAsFixed(0));
  late int _startYear = widget.budget.startYear;
  late int _startMonth = widget.budget.startMonth;
  late int _endYear = widget.budget.endYear;
  late int _endMonth = widget.budget.endMonth;
  bool _isDelete = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('予算月額を変更')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('この予算を削除する',
                    style: TextStyle(
                        color: AppTheme.textDark, fontWeight: FontWeight.bold)),
                subtitle: const Text(
                    'シミュレーション上でこの予算自体を無かったことにします（本丸データは変更しません）。',
                    style: TextStyle(fontSize: 12)),
                value: _isDelete,
                onChanged: (v) => setState(() => _isDelete = v),
              ),
            ),
            const SizedBox(height: 20),
            AbsorbPointer(
              absorbing: _isDelete,
              child: Opacity(
                opacity: _isDelete ? 0.4 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('名前',
                        style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(controller: _nameController),
                    const SizedBox(height: 20),
                    const Text('月額予算（万円）',
                        style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(suffixText: '万円/月'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: MonthPicker(
                            label: '開始',
                            year: _startYear,
                            month: _startMonth,
                            onChanged: (y, m) => setState(() {
                              _startYear = y;
                              _startMonth = m;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MonthPicker(
                            label: '終了',
                            year: _endYear,
                            month: _endMonth,
                            onChanged: (y, m) => setState(() {
                              _endYear = y;
                              _endMonth = m;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isDelete ? '削除として登録' : '登録'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_isDelete) {
      ref.read(simulationConditionsProvider.notifier).add(
            EditBudgetCondition(
              id: const Uuid().v4(),
              budgetId: widget.budget.id,
              name: widget.budget.name,
              monthlyAmount: widget.budget.monthlyAmount,
              startYear: widget.budget.startYear,
              startMonth: widget.budget.startMonth,
              endYear: widget.budget.endYear,
              endMonth: widget.budget.endMonth,
              isDelete: true,
            ),
          );
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text);
    final startTotal = _startYear * 12 + _startMonth;
    final endTotal = _endYear * 12 + _endMonth;

    if (name.isEmpty) {
      setState(() => _error = '名前を入力してください。');
      return;
    }
    if (amount == null || amount < 0) {
      setState(() => _error = '月額は0以上で入力してください。');
      return;
    }
    if (startTotal > endTotal) {
      setState(() => _error = '開始年月は終了年月以前にしてください。');
      return;
    }

    ref.read(simulationConditionsProvider.notifier).add(
          EditBudgetCondition(
            id: const Uuid().v4(),
            budgetId: widget.budget.id,
            name: name,
            monthlyAmount: amount,
            startYear: _startYear,
            startMonth: _startMonth,
            endYear: _endYear,
            endMonth: _endMonth,
          ),
        );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
