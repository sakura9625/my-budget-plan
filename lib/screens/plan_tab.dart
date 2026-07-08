import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/manual_entry.dart';
import '../providers/goal_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/manual_entry_provider.dart';
import '../providers/calculation_provider.dart';
import '../theme.dart';
import '../utils/formatter.dart';

class PlanTab extends ConsumerStatefulWidget {
  const PlanTab({super.key});

  @override
  ConsumerState<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends ConsumerState<PlanTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('計画'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '貯蓄'),
            Tab(text: 'プロジェクト'),
            Tab(text: '予算'),
          ],
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GoalList(type: GoalType.saving),
          _GoalList(type: GoalType.project),
          const _BudgetList(),
        ],
      ),
    );
  }
}

// ---- Goal一覧 ----

class _GoalList extends ConsumerWidget {
  final GoalType type;
  const _GoalList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalProvider)
        .where((g) => g.type == type)
        .toList();
    final calc = ref.watch(calculationProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...goals.map((g) {
          final gc = calc?.goalCalculations
              .where((c) => c.goal.id == g.id)
              .firstOrNull;
          return _GoalCard(goal: g, calc: gc);
        }),
        const SizedBox(height: 8),
        _AddButton(
          label: type == GoalType.saving ? '貯蓄を追加' : 'プロジェクトを追加',
          onTap: () => _showGoalDialog(context, ref, type),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref, GoalType type,
      {Goal? existing}) {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
        text: existing?.targetAmount.toStringAsFixed(0) ?? '');
    final now = DateTime.now();
    int startYear = existing?.startYear ?? now.year;
    int startMonth = existing?.startMonth ?? now.month;
    int endYear = existing?.endYear ?? now.year + 1;
    int endMonth = existing?.endMonth ?? now.month;
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit
                    ? (type == GoalType.saving ? '貯蓄を編集' : 'プロジェクトを編集')
                    : (type == GoalType.saving ? '貯蓄を追加' : 'プロジェクトを追加'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: type == GoalType.saving ? '例：老後資金' : '例：モルディブ旅行',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '目標金額（万円）',
                  suffixText: '万円',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MonthPicker(
                      label: '開始',
                      year: startYear,
                      month: startMonth,
                      onChanged: (y, m) => setModalState(
                          () { startYear = y; startMonth = m; }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MonthPicker(
                      label: '終了',
                      year: endYear,
                      month: endMonth,
                      onChanged: (y, m) => setModalState(
                          () { endYear = y; endMonth = m; }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final amount =
                      double.tryParse(amountController.text) ?? 0;
                  if (name.isEmpty || amount <= 0) return;

                  if (isEdit) {
                    existing!.name = name;
                    existing.targetAmount = amount;
                    existing.startYear = startYear;
                    existing.startMonth = startMonth;
                    existing.endYear = endYear;
                    existing.endMonth = endMonth;
                    await ref.read(goalProvider.notifier).update(existing);
                  } else {
                    await ref.read(goalProvider.notifier).add(Goal(
                          id: const Uuid().v4(),
                          type: type,
                          name: name,
                          targetAmount: amount,
                          startYear: startYear,
                          startMonth: startMonth,
                          endYear: endYear,
                          endMonth: endMonth,
                          emoji: type == GoalType.saving ? '💰' : '🎯',
                          createdAt: DateTime.now(),
                        ));
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(isEdit ? '保存' : '追加'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Goalカード ----

class _GoalCard extends ConsumerWidget {
  final Goal goal;
  final GoalCalculation? calc;
  const _GoalCard({required this.goal, this.calc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = calc != null
        ? AppTheme.planStatusColor(calc!.planStatus)
        : Colors.grey;
    final label = calc != null
        ? AppTheme.planStatusLabel(calc!.planStatus)
        : '-';
    final progress = (calc?.overallProgress ?? 0).clamp(0.0, 1.0);
    final entries = ref.watch(manualEntryProvider.notifier).forGoal(goal.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Text(goal.emoji ?? '🎯',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '目標 ${Formatter.man(goal.targetAmount)} / ${goal.endYear}年${goal.endMonth}月',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
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
          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('手入力 ${Formatter.man(goal.manualAmount)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                '進捗 ${((calc?.overallProgress ?? 0) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 20),
          // アクションボタン
          Row(
            children: [
              _actionButton(
                icon: Icons.add_circle_outline,
                label: '確保済み金額を入力',
                color: AppTheme.primary,
                onTap: () => _showManualEntryDialog(context, ref),
              ),
              const Spacer(),
              _iconAction(Icons.edit_outlined, Colors.grey,
                  () => _showEditDialog(context, ref)),
              const SizedBox(width: 4),
              _iconAction(Icons.delete_outline, Colors.redAccent,
                  () => _confirmDelete(context, ref)),
            ],
          ),
          // 手入力履歴
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text('確保履歴',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...entries.take(3).map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${e.date.year}/${e.date.month}/${e.date.day}${e.memo != null ? ' · ${e.memo}' : ''}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                      Text(Formatter.man(e.amount),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
          ],
          // ステータス変更
          const SizedBox(height: 8),
          _StatusDropdown(goal: goal),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _iconAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final memoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('確保済み金額を入力',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '実際に別口座へ移した・支払った金額を入力してください。',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: '例：10', suffixText: '万円'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: memoController,
              decoration:
                  const InputDecoration(hintText: 'メモ（任意）'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final amount =
                    double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;

                final entry = ManualEntry(
                  id: const Uuid().v4(),
                  goalId: goal.id,
                  amount: amount,
                  date: DateTime.now(),
                  memo: memoController.text.isEmpty
                      ? null
                      : memoController.text,
                );
                await ref.read(manualEntryProvider.notifier).add(entry);
                goal.manualAmount += amount;
                await ref.read(goalProvider.notifier).update(goal);

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: goal.name);
    final amountController =
        TextEditingController(text: goal.targetAmount.toStringAsFixed(0));
    int startYear = goal.startYear;
    int startMonth = goal.startMonth;
    int endYear = goal.endYear;
    int endMonth = goal.endMonth;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.type == GoalType.saving ? '貯蓄を編集' : 'プロジェクトを編集',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(controller: nameController,
                  decoration: const InputDecoration(hintText: '名前')),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: '目標金額（万円）', suffixText: '万円'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MonthPicker(
                      label: '開始',
                      year: startYear,
                      month: startMonth,
                      onChanged: (y, m) => setModalState(
                          () { startYear = y; startMonth = m; }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MonthPicker(
                      label: '終了',
                      year: endYear,
                      month: endMonth,
                      onChanged: (y, m) => setModalState(
                          () { endYear = y; endMonth = m; }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final amount =
                      double.tryParse(amountController.text) ?? 0;
                  if (name.isEmpty || amount <= 0) return;
                  goal.name = name;
                  goal.targetAmount = amount;
                  goal.startYear = startYear;
                  goal.startMonth = startMonth;
                  goal.endYear = endYear;
                  goal.endMonth = endMonth;
                  await ref.read(goalProvider.notifier).update(goal);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('「${goal.name}」を削除します。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(goalProvider.notifier).delete(goal.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ---- ステータスドロップダウン ----

class _StatusDropdown extends ConsumerWidget {
  final Goal goal;
  const _StatusDropdown({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<GoalStatus>(
      onSelected: (status) async {
        goal.status = status;
        await ref.read(goalProvider.notifier).update(goal);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: GoalStatus.active, child: Text('🚧 進行中')),
        PopupMenuItem(value: GoalStatus.completed, child: Text('✅ 達成')),
        PopupMenuItem(value: GoalStatus.frozen, child: Text('❄️ 凍結')),
        PopupMenuItem(value: GoalStatus.abandoned, child: Text('💀 断念')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_statusLabel(goal.status),
                style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _statusLabel(GoalStatus status) {
    switch (status) {
      case GoalStatus.active: return '🚧 進行中';
      case GoalStatus.completed: return '✅ 達成';
      case GoalStatus.frozen: return '❄️ 凍結';
      case GoalStatus.abandoned: return '💀 断念';
    }
  }
}

// ---- Budget一覧 ----

class _BudgetList extends ConsumerWidget {
  const _BudgetList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetProvider);
    final calc = ref.watch(calculationProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...budgets.map((b) {
          final bc = calc?.budgetCalculations
              .where((c) => c.budget.id == b.id)
              .firstOrNull;
          return _BudgetCard(budget: b, calc: bc);
        }),
        const SizedBox(height: 8),
        _AddButton(
          label: '予算を追加',
          onTap: () => _showBudgetDialog(context, ref),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref,
      {Budget? existing}) {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
        text: existing?.monthlyAmount.toStringAsFixed(0) ?? '');
    final now = DateTime.now();
    int startYear = existing?.startYear ?? now.year;
    int startMonth = existing?.startMonth ?? now.month;
    int endYear = existing?.endYear ?? now.year;
    int endMonth = existing?.endMonth ?? 12;
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? '予算を編集' : '予算を追加',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(hintText: '例：推し活、外食'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: '月額予算（万円）', suffixText: '万円'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MonthPicker(
                      label: '開始',
                      year: startYear,
                      month: startMonth,
                      onChanged: (y, m) => setModalState(
                          () { startYear = y; startMonth = m; }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MonthPicker(
                      label: '終了',
                      year: endYear,
                      month: endMonth,
                      onChanged: (y, m) => setModalState(
                          () { endYear = y; endMonth = m; }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final amount =
                      double.tryParse(amountController.text) ?? 0;
                  if (name.isEmpty || amount <= 0) return;

                  if (isEdit) {
                    existing!.name = name;
                    existing.monthlyAmount = amount;
                    existing.startYear = startYear;
                    existing.startMonth = startMonth;
                    existing.endYear = endYear;
                    existing.endMonth = endMonth;
                    await ref
                        .read(budgetProvider.notifier)
                        .update(existing);
                  } else {
                    await ref.read(budgetProvider.notifier).add(Budget(
                          id: const Uuid().v4(),
                          name: name,
                          monthlyAmount: amount,
                          startYear: startYear,
                          startMonth: startMonth,
                          endYear: endYear,
                          endMonth: endMonth,
                          emoji: '💰',
                          createdAt: DateTime.now(),
                        ));
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(isEdit ? '保存' : '追加'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Budgetカード ----

class _BudgetCard extends ConsumerWidget {
  final Budget budget;
  final BudgetCalculation? calc;
  const _BudgetCard({required this.budget, this.calc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = calc != null
        ? AppTheme.budgetStatusColor(calc!.status)
        : Colors.grey;
    final label = calc != null
        ? AppTheme.budgetStatusLabel(calc!.status)
        : '-';
    final progress = (calc?.usageRate ?? 0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(budget.emoji ?? '💰',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '月額 ${Formatter.man(budget.monthlyAmount)} / ${budget.endYear}年${budget.endMonth}月まで',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('利用済 ${Formatter.man(budget.usedAmount)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text('予算合計 ${Formatter.man(budget.plannedAmount)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _showEditDialog(context, ref),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmDelete(context, ref),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline,
                      size: 20, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: budget.name);
    final amountController =
        TextEditingController(text: budget.monthlyAmount.toStringAsFixed(0));
    int startYear = budget.startYear;
    int startMonth = budget.startMonth;
    int endYear = budget.endYear;
    int endMonth = budget.endMonth;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('予算を編集',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(controller: nameController,
                  decoration: const InputDecoration(hintText: '名前')),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: '月額予算（万円）', suffixText: '万円'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MonthPicker(
                      label: '開始',
                      year: startYear,
                      month: startMonth,
                      onChanged: (y, m) => setModalState(
                          () { startYear = y; startMonth = m; }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MonthPicker(
                      label: '終了',
                      year: endYear,
                      month: endMonth,
                      onChanged: (y, m) => setModalState(
                          () { endYear = y; endMonth = m; }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final amount =
                      double.tryParse(amountController.text) ?? 0;
                  if (name.isEmpty || amount <= 0) return;
                  budget.name = name;
                  budget.monthlyAmount = amount;
                  budget.startYear = startYear;
                  budget.startMonth = startMonth;
                  budget.endYear = endYear;
                  budget.endMonth = endMonth;
                  await ref.read(budgetProvider.notifier).update(budget);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('「${budget.name}」を削除します。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(budgetProvider.notifier).delete(budget.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('削除',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ---- 共通ウィジェット ----

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppTheme.primary.withOpacity(0.4), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  final String label;
  final int year;
  final int month;
  final Function(int, int) onChanged;

  const _MonthPicker({
    required this.label,
    required this.year,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text('$year年$month月',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  int y = year, m = month - 1;
                  if (m < 1) { m = 12; y--; }
                  onChanged(y, m);
                },
                child: const Icon(Icons.chevron_left,
                    size: 20, color: AppTheme.primary),
              ),
              GestureDetector(
                onTap: () {
                  int y = year, m = month + 1;
                  if (m > 12) { m = 1; y++; }
                  onChanged(y, m);
                },
                child: const Icon(Icons.chevron_right,
                    size: 20, color: AppTheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
