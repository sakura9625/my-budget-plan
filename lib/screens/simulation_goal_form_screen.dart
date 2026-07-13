import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/goal.dart';
import '../models/simulation.dart';
import '../providers/simulation_provider.dart';
import '../theme.dart';
import '../widgets/month_picker.dart';

// 「新しいプロジェクトを追加」「既存プロジェクトを変更」の入力フォーム。
// existingGoalがnullなら追加（AddGoalCondition）、そうでなければ変更
// （EditGoalCondition、対象は既存プロジェクトから選んで渡される）。
class SimulationGoalFormScreen extends ConsumerStatefulWidget {
  final Goal? existingGoal;
  const SimulationGoalFormScreen({super.key, this.existingGoal});

  @override
  ConsumerState<SimulationGoalFormScreen> createState() =>
      _SimulationGoalFormScreenState();
}

class _SimulationGoalFormScreenState
    extends ConsumerState<SimulationGoalFormScreen> {
  late final _nameController =
      TextEditingController(text: widget.existingGoal?.name ?? '');
  late final _amountController = TextEditingController(
      text: widget.existingGoal != null
          ? widget.existingGoal!.targetAmount.toStringAsFixed(0)
          : '');
  late final _emojiController =
      TextEditingController(text: widget.existingGoal?.emoji ?? '');
  late final _memoController =
      TextEditingController(text: widget.existingGoal?.memo ?? '');

  late GoalType _goalType = widget.existingGoal?.type ?? GoalType.project;
  late final now = DateTime.now();
  late int _startYear = widget.existingGoal?.startYear ?? now.year;
  late int _startMonth = widget.existingGoal?.startMonth ?? now.month;
  late int _endYear = widget.existingGoal?.endYear ?? now.year;
  late int _endMonth = widget.existingGoal?.endMonth ?? now.month;
  String? _error;

  bool get _isEdit => widget.existingGoal != null;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _emojiController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'プロジェクトを変更' : '新しいプロジェクトを追加')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isEdit) ...[
              const Text('種別',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
              const SizedBox(height: 8),
              SegmentedButton<GoalType>(
                segments: const [
                  ButtonSegment(
                      value: GoalType.saving, label: Text('純粋貯蓄')),
                  ButtonSegment(
                      value: GoalType.project, label: Text('プロジェクト')),
                ],
                selected: {_goalType},
                onSelectionChanged: (s) =>
                    setState(() => _goalType = s.first),
              ),
              const SizedBox(height: 20),
            ],
            const Text('名前',
                style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: '例：旅行'),
            ),
            const SizedBox(height: 20),
            const Text('目標金額（万円）',
                style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '例：30', suffixText: '万円'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: MonthPicker(
                    label: '開始',
                    year: _startYear,
                    month: _startMonth,
                    onChanged: (y, m) =>
                        setState(() {
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
                    onChanged: (y, m) =>
                        setState(() {
                      _endYear = y;
                      _endMonth = m;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('絵文字（任意）',
                style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _emojiController,
              decoration: const InputDecoration(hintText: '例：🎯'),
            ),
            const SizedBox(height: 20),
            const Text('メモ（任意）',
                style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              maxLines: 3,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isEdit ? '登録' : '登録'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    final startTotal = _startYear * 12 + _startMonth;
    final endTotal = _endYear * 12 + _endMonth;

    if (name.isEmpty) {
      setState(() => _error = '名前を入力してください。');
      return;
    }
    if (amount < 1) {
      setState(() => _error = '目標金額は1万円以上で入力してください。');
      return;
    }
    if (startTotal > endTotal) {
      setState(() => _error = '開始年月は終了年月以前にしてください。');
      return;
    }

    final emoji = _emojiController.text.trim().isEmpty
        ? null
        : _emojiController.text.trim();
    final memo =
        _memoController.text.trim().isEmpty ? null : _memoController.text.trim();

    if (_isEdit) {
      ref.read(simulationConditionsProvider.notifier).add(
            EditGoalCondition(
              id: const Uuid().v4(),
              goalId: widget.existingGoal!.id,
              name: name,
              targetAmount: amount,
              startYear: _startYear,
              startMonth: _startMonth,
              endYear: _endYear,
              endMonth: _endMonth,
              emoji: emoji,
              memo: memo,
            ),
          );
    } else {
      ref.read(simulationConditionsProvider.notifier).add(
            AddGoalCondition(
              id: const Uuid().v4(),
              name: name,
              goalType: _goalType,
              targetAmount: amount,
              startYear: _startYear,
              startMonth: _startMonth,
              endYear: _endYear,
              endMonth: _endMonth,
              emoji: emoji,
              memo: memo,
            ),
          );
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
