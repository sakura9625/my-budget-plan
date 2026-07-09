import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/review.dart';
import '../models/goal.dart';
import '../models/manual_entry.dart';
import '../models/budget_entry.dart';
import '../providers/review_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/manual_entry_provider.dart';
import '../providers/budget_entry_provider.dart';
import '../providers/calculation_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import '../utils/formatter.dart';

class ReviewTab extends ConsumerStatefulWidget {
  const ReviewTab({super.key});

  @override
  ConsumerState<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends ConsumerState<ReviewTab> {
  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(reviewProvider);
    final hasCurrentReview =
        ref.read(reviewProvider.notifier).hasCurrentMonthReview;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('レビュー')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCurrentMonthCard(context, hasCurrentReview, now),
          const SizedBox(height: 24),
          if (reviews.isNotEmpty) ...[
            Text('過去のレビュー',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...reviews.map((r) => _buildReviewHistoryCard(context, r)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCurrentMonthCard(
      BuildContext context, bool hasReview, DateTime now) {
    final review = ref
        .read(reviewProvider.notifier)
        .getByYearMonth(now.year, now.month);

    if (hasReview && review != null) {
      return _buildReviewDoneCard(context, review);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${now.year}年${now.month}月のレビュー',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Text(
            '今月のレビューがまだ完了していません。\nレビューをすると、今月あといくら使えるか確認できます。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _startReview(context),
            child: const Text('レビューを始める'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewDoneCard(BuildContext context, Review review) {
    // 進捗・判定はcalculationProvider（ホーム画面と共通の単一計算元）から取得し、
    // レビュー保存時点のスナップショットとズレないようにする。
    final calc = ref.watch(calculationProvider);
    final overallProgress = calc?.totalOverallProgress ?? review.overallProgress;
    final planProgress = calc?.totalPlanProgress ?? review.planProgress;
    final statusLabel = calc?.overallPlanStatus != null
        ? AppTheme.planStatusLabel(calc!.overallPlanStatus)
        : review.overallStatus;
    final statusColor = calc?.overallPlanStatus != null
        ? AppTheme.planStatusColor(calc!.overallPlanStatus)
        : _statusColor(review.overallStatus);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${review.year}年${review.month}月のレビュー',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _reviewRow('残高', Formatter.man(review.effectiveBalance)),
          _reviewRow('全体進捗',
              '${(overallProgress * 100).toStringAsFixed(0)}%'),
          _reviewRow('計画進捗',
              '${(planProgress * 100).toStringAsFixed(0)}%'),
          if (review.comment != null) ...[
            const Divider(height: 20),
            Text(review.comment!,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _startReview(context, isEdit: true),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppTheme.primary),
            ),
            child: const Text('レビューを編集',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.textDark)),
        ],
      ),
    );
  }

  Widget _buildReviewHistoryCard(BuildContext context, Review review) {
    final statusColor = _statusColor(review.overallStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${review.year}年${review.month}月',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                Text('残高 ${Formatter.man(review.effectiveBalance)}',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                if (review.comment != null)
                  Text(review.comment!,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(review.overallStatus,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
              const SizedBox(height: 4),
              Text(
                '全体 ${(review.overallProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case '余裕': return AppTheme.success;
      case '順調': return AppTheme.primary;
      case '安全': return AppTheme.primary;
      case '危険': return AppTheme.warning;
      case '見直し要請': return AppTheme.needsReview;
      case '達成困難': return AppTheme.danger;
      default: return Colors.grey;
    }
  }

  void _startReview(BuildContext context, {bool isEdit = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewInputSheet(isEdit: isEdit),
    );
  }
}

// ---- レビュー入力シート ----

class _ReviewInputSheet extends ConsumerStatefulWidget {
  final bool isEdit;
  const _ReviewInputSheet({this.isEdit = false});

  @override
  ConsumerState<_ReviewInputSheet> createState() => _ReviewInputSheetState();
}

class _ReviewInputSheetState extends ConsumerState<_ReviewInputSheet> {
  int _step = 0;
  final _balanceController = TextEditingController();
  final _commentController = TextEditingController();

  // Goal手入力
  final Map<String, TextEditingController> _goalControllers = {};
  final Map<String, TextEditingController> _goalMemoControllers = {};

  // Budget手入力
  final Map<String, TextEditingController> _budgetControllers = {};
  final Map<String, TextEditingController> _budgetMemoControllers = {};

  @override
  void initState() {
    super.initState();
    // 現在の総残高（settings.totalBalance）を初期値として表示する
    final totalBalance = ref.read(settingsProvider)?.totalBalance ?? 0;
    if (totalBalance != 0) {
      _balanceController.text = totalBalance.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalProvider).where((g) =>
        g.status == GoalStatus.active).toList();
    final budgets = ref.watch(budgetProvider);

    for (final g in goals) {
      _goalControllers.putIfAbsent(g.id, () => TextEditingController());
      _goalMemoControllers.putIfAbsent(g.id, () => TextEditingController());
    }
    for (final b in budgets) {
      _budgetControllers.putIfAbsent(b.id, () => TextEditingController());
      _budgetMemoControllers.putIfAbsent(b.id, () => TextEditingController());
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildSheetHeader(context),
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: _buildStep(goals, budgets),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetHeader(BuildContext context) {
    final titles = ['残高入力', 'Goal手入力', '予算利用額', 'コメント', '確認・保存'];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          if (_step > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _step--),
              padding: EdgeInsets.zero,
            ),
          Expanded(
            child: Text(titles[_step],
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: List.generate(5, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i <= _step ? AppTheme.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep(List goals, List budgets) {
    switch (_step) {
      case 0: return _buildStep1();
      case 1: return _buildStep2(goals);
      case 2: return _buildStep3(budgets);
      case 3: return _buildStep4();
      case 4: return _buildStep5(goals, budgets);
      default: return const SizedBox.shrink();
    }
  }

  // Step1: 残高入力
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('現在の口座残高を入力してください',
            style: _labelStyle()),
        const SizedBox(height: 4),
        Text('ざっくりで大丈夫です。カード引き落としが気になる場合は差し引いた金額で入力してください。',
            style: const TextStyle(color: Color(0xFFC7CDDB), fontSize: 12)),
        const SizedBox(height: 16),
        TextField(
          controller: _balanceController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: '例：200', suffixText: '万円'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: (_balanceController.text.isNotEmpty)
              ? () => setState(() => _step++)
              : null,
          child: const Text('次へ'),
        ),
      ],
    );
  }

  // Step2: Goal手入力
  Widget _buildStep2(List goals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('貯蓄口座へ移した金額や、プロジェクトで支払った金額はありますか？',
            style: _labelStyle()),
        const SizedBox(height: 4),
        Text('なければスキップできます。',
            style: const TextStyle(color: Color(0xFFC7CDDB), fontSize: 12)),
        const SizedBox(height: 16),
        if (goals.isEmpty)
          const Text('進行中のGoalがありません',
              style: TextStyle(color: Color(0xFFC7CDDB))),
        ...goals.map((g) => _buildGoalInput(g)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => setState(() => _step++),
          child: Text(goals.isEmpty ? 'スキップ' : '次へ'),
        ),
      ],
    );
  }

  Widget _buildGoalInput(goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.emoji ?? '🎯',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(goal.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _goalControllers[goal.id],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                hintText: '確保した金額（万円）', suffixText: '万円'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _goalMemoControllers[goal.id],
            decoration: const InputDecoration(hintText: 'メモ（任意）'),
          ),
        ],
      ),
    );
  }

  // Step3: Budget手入力
  Widget _buildStep3(List budgets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('登録している予算で使った金額はありますか？',
            style: _labelStyle()),
        const SizedBox(height: 4),
        Text('なければスキップできます。',
            style: const TextStyle(color: Color(0xFFC7CDDB), fontSize: 12)),
        const SizedBox(height: 16),
        if (budgets.isEmpty)
          const Text('予算が登録されていません',
              style: TextStyle(color: Color(0xFFC7CDDB))),
        ...budgets.map((b) => _buildBudgetInput(b)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => setState(() => _step++),
          child: Text(budgets.isEmpty ? 'スキップ' : '次へ'),
        ),
      ],
    );
  }

  Widget _buildBudgetInput(budget) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(budget.emoji ?? '💰',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(budget.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const Spacer(),
              Text('月額 ${Formatter.man(budget.monthlyAmount)}',
                  style: const TextStyle(
                      color: Color(0xFF6B7280), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _budgetControllers[budget.id],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                hintText: '利用額（万円）', suffixText: '万円'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _budgetMemoControllers[budget.id],
            decoration: const InputDecoration(hintText: 'メモ（任意）'),
          ),
        ],
      ),
    );
  }

  // Step4: コメント
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('今月のコメント（任意）', style: _labelStyle()),
        const SizedBox(height: 4),
        Text('今月の振り返りや気づきを記録しておきましょう。',
            style: const TextStyle(color: Color(0xFFC7CDDB), fontSize: 12)),
        const SizedBox(height: 16),
        TextField(
          controller: _commentController,
          maxLines: 4,
          decoration: const InputDecoration(
              hintText: '例：今月は旅行が多かった'),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => setState(() => _step++),
          child: const Text('次へ'),
        ),
      ],
    );
  }

  // Step5: 確認・保存
  Widget _buildStep5(List goals, List budgets) {
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final calc = ref.read(calculationProvider);
    final allocatable = balance - (calc?.monthlyFreeAmount ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('レビュー結果', style: _labelStyle()),
        const SizedBox(height: 16),
        _confirmRow('現在残高', Formatter.man(balance)),
        _confirmRow('月間自由枠', Formatter.man(calc?.monthlyFreeAmount ?? 0)),
        _confirmRow(
          '目標配分可能額',
          Formatter.man(allocatable),
          valueColor: allocatable >= 0 ? AppTheme.success : AppTheme.danger,
        ),
        if (calc != null) ...[
          const Divider(height: 20),
          _confirmRow(
            '全体進捗',
            '${(calc.totalOverallProgress * 100).toStringAsFixed(0)}%',
          ),
          _confirmRow(
            '計画進捗',
            '${(calc.totalPlanProgress * 100).toStringAsFixed(0)}%',
            valueColor: AppTheme.planStatusColor(calc.overallPlanStatus),
          ),
          _confirmRow(
            '判定',
            AppTheme.planStatusLabel(calc.overallPlanStatus),
            valueColor: AppTheme.planStatusColor(calc.overallPlanStatus),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => _saveReview(goals, budgets),
          child: const Text('レビューを保存'),
        ),
      ],
    );
  }

  Widget _confirmRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFFC7CDDB), fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: valueColor ?? Colors.white)),
        ],
      ),
    );
  }

  TextStyle _labelStyle() {
    return const TextStyle(
        fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white);
  }

  Future<void> _saveReview(List goals, List budgets) async {
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final now = DateTime.now();

    // Goal手入力を保存
    for (final g in goals) {
      final amountText = _goalControllers[g.id]?.text ?? '';
      final amount = double.tryParse(amountText) ?? 0;
      if (amount > 0) {
        final entry = ManualEntry(
          id: const Uuid().v4(),
          goalId: g.id,
          amount: amount,
          date: now,
          memo: _goalMemoControllers[g.id]?.text.isEmpty == true
              ? null
              : _goalMemoControllers[g.id]?.text,
        );
        await ref.read(manualEntryProvider.notifier).add(entry);
        g.manualAmount += amount;
        await ref.read(goalProvider.notifier).update(g);
      }
    }

    // Budget手入力を保存
    for (final b in budgets) {
      final amountText = _budgetControllers[b.id]?.text ?? '';
      final amount = double.tryParse(amountText) ?? 0;
      if (amount > 0) {
        final entry = BudgetEntry(
          id: const Uuid().v4(),
          budgetId: b.id,
          amount: amount,
          date: now,
          memo: _budgetMemoControllers[b.id]?.text.isEmpty == true
              ? null
              : _budgetMemoControllers[b.id]?.text,
        );
        await ref.read(budgetEntryProvider.notifier).add(entry);
        b.usedAmount += amount;
        await ref.read(budgetProvider.notifier).update(b);
      }
    }

    // 総残高（アプリ全体で1つ、settings.totalBalance）を更新する。
    // レビュー・ホーム・設定画面はすべてこの値を単一の残高ソースとして参照する。
    final settings = ref.read(settingsProvider);
    if (settings != null) {
      settings.totalBalance = balance;
      await ref.read(settingsProvider.notifier).save(settings);
    }

    // Review保存
    // 先に一旦保存してeffectiveBalanceを確定させ、calculationProvider（ホーム画面と
    // 共通の単一計算元）にこのレビューの残高・手入力を反映させた上で進捗を取得する。
    // これにより保存される履歴の値がホーム画面の表示と一致する。
    final review = Review(
      id: const Uuid().v4(),
      year: now.year,
      month: now.month,
      reviewDate: now,
      accountBalance: balance,
      effectiveBalance: balance,
      overallProgress: 0,
      planProgress: 0,
      overallStatus: '安全',
      comment: _commentController.text.isEmpty
          ? null
          : _commentController.text,
      homeHeadline: null,
    );
    await ref.read(reviewProvider.notifier).save(review);

    final calc = ref.read(calculationProvider);
    review.overallProgress = calc?.totalOverallProgress ?? 0;
    review.planProgress = calc?.totalPlanProgress ?? 0;
    review.overallStatus = calc != null
        ? AppTheme.planStatusLabel(calc.overallPlanStatus)
        : '安全';
    review.homeHeadline = calc?.headline;
    await ref.read(reviewProvider.notifier).save(review);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('レビューを保存しました')),
      );
    }
  }
}
