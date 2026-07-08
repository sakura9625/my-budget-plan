import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../providers/goal_provider.dart';
import '../providers/budget_provider.dart';
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
        _buildAddButton(context, ref, type),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref, GoalType type) {
    return GestureDetector(
      onTap: () => _showGoalDialog(context, ref, type),
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
            Text(
              type == GoalType.saving ? '貯蓄を追加' : 'プロジェクトを追加',
              style: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref, GoalType type) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final now = DateTime.now();
    int startYear = now.year;
    int startMonth = now.month;
    int endYear = now.year + 1;
    int endMonth = now.month;

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
                type == GoalType.saving ? '貯蓄を追加' : 'プロジェクトを追加',
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
                      onChanged: (y, m) =>
                          setModalState(() { startYear = y; startMonth = m; }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MonthPicker(
                      label: '終了',
                      year: endYear,
                      month: endMonth,
                      onChanged: (y, m) =>
                          setModalState(() { endYear = y; endMonth = m; }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (name.isEmpty || amount <= 0) return;
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
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('追加'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
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
              Text(
                '手入力 ${Formatter.man(goal.manualAmount)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '進捗 ${((calc?.overallProgress ?? 0) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _statusButton(context, ref),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusButton(BuildContext context, WidgetRef ref) {
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
        _buildAddButton(context, ref),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showBudgetDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppTheme.primary.withOpacity(0.4), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text('予算を追加',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final now = DateTime.now();
    int startYear = now.year;
    int startMonth = now.month;
    int endYear = now.year;
    int endMonth = 12;

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
              Text('予算を追加',
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
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (name.isEmpty || amount <= 0) return;
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
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('追加'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
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
              Text(
                '利用済 ${Formatter.man(budget.usedAmount)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '予算合計 ${Formatter.man(budget.plannedAmount)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
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
