import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../models/app_settings.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../providers/settings_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/calculation_provider.dart' show monthlyFromAnnual;
import '../theme.dart';
import '../utils/formatter.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step1
  final _incomeController = TextEditingController();
  final _fixedCostController = TextEditingController();

  // Step2 貯蓄
  final List<Map<String, dynamic>> _savings = [];

  // Step3 現在の残高
  final _totalBalanceController = TextEditingController();

  // Step4 プロジェクト
  final List<Map<String, dynamic>> _projects = [];

  // Step5 予算
  final List<Map<String, dynamic>> _budgets = [];

  // Step6 レビュー日
  int _reviewDay = 28;

  double get _annualFreeMoney {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final fixed = double.tryParse(_fixedCostController.text) ?? 0;
    return income - fixed;
  }

  double get _monthlyFreeMoney => monthlyFromAnnual(_annualFreeMoney);

  final _stepTitles = [
    '収入・固定費',
    '貯蓄目標',
    '現在の残高',
    'プロジェクト',
    '予算',
    '年間設計確認',
    'レビュー日設定',
    '完了',
  ];

  void _nextStep() {
    if (_currentStep < 7) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevStep,
              )
            : null,
        title: Text(_stepTitles[_currentStep]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStepBalance(),
          _buildStep3(),
          _buildStep4(),
          _buildStep5(),
          _buildStep6(),
          _buildStep7(),
        ],
      ),
    );
  }

  // Step1: 収入・固定費
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('まず基本情報を入力してください',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFC7CDDB),
                  )),
          const SizedBox(height: 24),
          _buildLabel('年間手取り（万円）'),
          const SizedBox(height: 8),
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '例：500', suffixText: '万円'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          _buildLabel('年間固定費（万円）'),
          const SizedBox(height: 8),
          TextField(
            controller: _fixedCostController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '例：240', suffixText: '万円'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          if (_annualFreeMoney > 0) ...[
            _buildResultCard(
              '年間自由資金',
              Formatter.man(_annualFreeMoney),
              sub: '月間 ${Formatter.man(_monthlyFreeMoney)}',
            ),
          ],
          if (_annualFreeMoney < 0) ...[
            _buildWarningCard('固定費が手取りを上回っています。見直してください。'),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _annualFreeMoney > 0 ? _nextStep : null,
            child: const Text('次へ'),
          ),
        ],
      ),
    );
  }

  // Step2: 貯蓄
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('純粋な貯蓄目標はありますか？',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('老後資金・緊急資金など。なければスキップできます。',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          ..._savings.asMap().entries.map((e) => _buildGoalChip(e.value, () {
                setState(() => _savings.removeAt(e.key));
              })),
          _buildAddGoalButton('貯蓄を追加', () => _showGoalDialog(isSaving: true)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextStep,
            child: Text(_savings.isEmpty ? 'スキップ' : '次へ'),
          ),
        ],
      ),
    );
  }

  // Step3: 現在の残高
  Widget _buildStepBalance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('現在の残高',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('今の貯蓄・口座残高の合計を入力しましょう',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          _buildLabel('現在の残高（万円）'),
          const SizedBox(height: 8),
          TextField(
            controller: _totalBalanceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '例：100', suffixText: '万円'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextStep,
            child: const Text('次へ'),
          ),
        ],
      ),
    );
  }

  // Step4: プロジェクト
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('特定の目的のために貯めたいお金はありますか？',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('旅行・カメラ・車など。なければスキップできます。',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          ..._projects.asMap().entries.map((e) => _buildGoalChip(e.value, () {
                setState(() => _projects.removeAt(e.key));
              })),
          _buildAddGoalButton('プロジェクトを追加', () => _showGoalDialog(isSaving: false)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextStep,
            child: Text(_projects.isEmpty ? 'スキップ' : '次へ'),
          ),
        ],
      ),
    );
  }

  // Step4: 予算
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('月々の予算を決めておきたいテーマはありますか？',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('推し活・外食・趣味など。使い過ぎを防ぎたいものだけでOKです。',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          ..._budgets.asMap().entries.map((e) => _buildBudgetChip(e.value, () {
                setState(() => _budgets.removeAt(e.key));
              })),
          _buildAddGoalButton('予算を追加', _showBudgetDialog),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextStep,
            child: Text(_budgets.isEmpty ? 'スキップ' : '次へ'),
          ),
        ],
      ),
    );
  }

  // Step5: 年間設計確認
  Widget _buildStep5() {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final fixed = double.tryParse(_fixedCostController.text) ?? 0;
    final annualFree = income - fixed;

    double totalGoal = 0;
    for (final g in [..._savings, ..._projects]) {
      final months = (g['endYear'] * 12 + g['endMonth']) -
          (g['startYear'] * 12 + g['startMonth']) + 1;
      totalGoal += (g['amount'] as double) / months *
          _targetMonthsInCurrentYear(
              g['startYear'], g['startMonth'], g['endYear'], g['endMonth']);
    }

    double totalBudget = 0;
    for (final b in _budgets) {
      totalBudget += (b['amount'] as double) *
          _targetMonthsInCurrentYear(
              b['startYear'], b['startMonth'], b['endYear'], b['endMonth']);
    }

    final annualFreeAmount = annualFree - totalGoal - totalBudget;
    final monthlyFreeAmount = monthlyFromAnnual(annualFreeAmount);
    final isNegative = annualFreeAmount < 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('この内容で年間予算を作成します',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          _buildSummaryRow('年間手取り', Formatter.man(income)),
          _buildSummaryRow('年間固定費', Formatter.man(fixed)),
          _buildSummaryRow('年間自由資金', Formatter.man(annualFree)),
          _buildSummaryRow('現在の残高',
              Formatter.man(double.tryParse(_totalBalanceController.text) ?? 0)),
          Divider(height: 24, color: Colors.white.withOpacity(0.2)),
          _buildSummaryRow('今年の貯蓄目標', Formatter.man(totalGoal)),
          _buildSummaryRow('今年のプロジェクト', ''),
          _buildSummaryRow('今年の予算合計', Formatter.man(totalBudget)),
          Divider(height: 24, color: Colors.white.withOpacity(0.2)),
          _buildSummaryRow(
            '年間自由枠',
            Formatter.man(annualFreeAmount),
            highlight: true,
            isNegative: isNegative,
          ),
          _buildSummaryRow(
            '月間自由枠',
            Formatter.man(monthlyFreeAmount),
            highlight: true,
            isNegative: isNegative,
          ),
          if (isNegative) ...[
            const SizedBox(height: 16),
            _buildWarningCard('この計画では自由に使えるお金がマイナスになります。貯蓄・プロジェクト・予算のいずれかを見直してください。'),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextStep,
            child: const Text('次へ'),
          ),
        ],
      ),
    );
  }

  // Step6: レビュー日設定
  Widget _buildStep6() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('毎月レビューする日を設定してください',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('給与振込・固定費・カード引き落としが概ね終わった日がおすすめです。',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('毎月',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_reviewDay > 1) setState(() => _reviewDay--);
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppTheme.primary,
                    ),
                    Text('$_reviewDay日',
                        style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary)),
                    IconButton(
                      onPressed: () {
                        if (_reviewDay < 28) setState(() => _reviewDay++);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveAndComplete,
            child: const Text('年間予算を作成する'),
          ),
        ],
      ),
    );
  }

  // Step7: 完了
  Widget _buildStep7() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            Text('年間予算ができました！',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(
              'ホーム画面で今月の状況を確認してみましょう。',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFC7CDDB),
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => context.go('/main'),
              child: const Text('ホームへ'),
            ),
          ],
        ),
      ),
    );
  }

  // ---- ヘルパーUI ----

  Widget _buildLabel(String text) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildResultCard(String label, String value, {String? sub}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
              if (sub != null)
                Text(sub,
                    style: const TextStyle(
                        color: AppTheme.primary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppTheme.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalChip(Map<String, dynamic> data, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(data['emoji'] ?? '🎯', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                Text(
                    '目標 ${Formatter.man((data['amount'] as double))} / ${data['startYear']}/${data['startMonth']}〜${data['endYear']}/${data['endMonth']}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetChip(Map<String, dynamic> data, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(data['emoji'] ?? '💰', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                Text('月額 ${Formatter.man((data['amount'] as double))}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildAddGoalButton(String label, VoidCallback onTap) {
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

  Widget _buildSummaryRow(String label, String value,
      {bool highlight = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight:
                      highlight ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                  color: Colors.white)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: highlight ? 16 : 14,
                  color: isNegative
                      ? AppTheme.danger
                      : (highlight ? AppTheme.primary : Colors.white))),
        ],
      ),
    );
  }

  // ---- ダイアログ ----

  void _showGoalDialog({required bool isSaving}) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String emoji = isSaving ? '💰' : '🎯';
    final now = DateTime.now();
    int startYear = now.year;
    int startMonth = now.month;
    // 6ヶ月間（開始月を1ヶ月目として数える）＝開始月+5
    final endDefault = DateTime(now.year, now.month + 5);
    int endYear = endDefault.year;
    int endMonth = endDefault.month;

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
              Text(isSaving ? '貯蓄を追加' : 'プロジェクトを追加',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppTheme.textDark)),
              if (!isSaving) ...[
                const SizedBox(height: 4),
                const Text('どんな目的でいくら貯めたいか記入しましょう',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                    hintText: isSaving ? '例：老後資金' : '例：モルディブ旅行'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(hintText: '目標金額（万円）', suffixText: '万円'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMonthPicker(
                      '開始',
                      startYear,
                      startMonth,
                      (y, m) => setModalState(() {
                        startYear = y;
                        startMonth = m;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMonthPicker(
                      '終了',
                      endYear,
                      endMonth,
                      (y, m) => setModalState(() {
                        endYear = y;
                        endMonth = m;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (name.isEmpty || amount <= 0) return;
                  final data = {
                    'name': name,
                    'amount': amount,
                    'emoji': emoji,
                    'startYear': startYear,
                    'startMonth': startMonth,
                    'endYear': endYear,
                    'endMonth': endMonth,
                    'isSaving': isSaving,
                  };
                  setState(() {
                    if (isSaving) {
                      _savings.add(data);
                    } else {
                      _projects.add(data);
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text('追加'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final now = DateTime.now();
    int startYear = now.year;
    int startMonth = now.month;
    // 6ヶ月間（開始月を1ヶ月目として数える）＝開始月+5
    final endDefault = DateTime(now.year, now.month + 5);
    int endYear = endDefault.year;
    int endMonth = endDefault.month;

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
              Text('毎月の特別予算を追加',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppTheme.textDark)),
              const SizedBox(height: 4),
              const Text('月々の特別に確保したい予算を記入しましょう',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
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
                    child: _buildMonthPicker(
                      '開始',
                      startYear,
                      startMonth,
                      (y, m) => setModalState(() {
                        startYear = y;
                        startMonth = m;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMonthPicker(
                      '終了',
                      endYear,
                      endMonth,
                      (y, m) => setModalState(() {
                        endYear = y;
                        endMonth = m;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (name.isEmpty || amount <= 0) return;
                  setState(() {
                    _budgets.add({
                      'name': name,
                      'amount': amount,
                      'emoji': '💰',
                      'startYear': startYear,
                      'startMonth': startMonth,
                      'endYear': endYear,
                      'endMonth': endMonth,
                    });
                  });
                  Navigator.pop(context);
                },
                child: const Text('追加'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthPicker(
      String label, int year, int month, Function(int, int) onChanged) {
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
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text('$year年$month月',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textDark)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  int y = year, m = month - 1;
                  if (m < 1) { m = 12; y--; }
                  onChanged(y, m);
                },
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.chevron_left,
                      size: 20, color: AppTheme.primary),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  int y = year, m = month + 1;
                  if (m > 12) { m = 1; y++; }
                  onChanged(y, m);
                },
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.chevron_right,
                      size: 20, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- 保存処理 ----

  Future<void> _saveAndComplete() async {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final fixed = double.tryParse(_fixedCostController.text) ?? 0;

    final totalBalance = double.tryParse(_totalBalanceController.text) ?? 0;

    final settings = AppSettings(
      annualIncome: income,
      annualFixedCost: fixed,
      reviewDay: _reviewDay,
      notificationEnabled: true,
      initialSetupCompleted: true,
      totalBalance: totalBalance,
    );
    await ref.read(settingsProvider.notifier).save(settings);

    for (final s in _savings) {
      await ref.read(goalProvider.notifier).add(Goal(
            id: const Uuid().v4(),
            type: GoalType.saving,
            name: s['name'],
            targetAmount: s['amount'],
            startYear: s['startYear'],
            startMonth: s['startMonth'],
            endYear: s['endYear'],
            endMonth: s['endMonth'],
            emoji: s['emoji'],
            createdAt: DateTime.now(),
          ));
    }

    for (final p in _projects) {
      await ref.read(goalProvider.notifier).add(Goal(
            id: const Uuid().v4(),
            type: GoalType.project,
            name: p['name'],
            targetAmount: p['amount'],
            startYear: p['startYear'],
            startMonth: p['startMonth'],
            endYear: p['endYear'],
            endMonth: p['endMonth'],
            emoji: p['emoji'],
            createdAt: DateTime.now(),
          ));
    }

    for (final b in _budgets) {
      await ref.read(budgetProvider.notifier).add(Budget(
            id: const Uuid().v4(),
            name: b['name'],
            monthlyAmount: b['amount'],
            startYear: b['startYear'],
            startMonth: b['startMonth'],
            endYear: b['endYear'],
            endMonth: b['endMonth'],
            emoji: b['emoji'],
            createdAt: DateTime.now(),
          ));
    }

    _nextStep();
  }

  int _targetMonthsInCurrentYear(
      int startYear, int startMonth, int endYear, int endMonth) {
    final now = DateTime.now();
    final yearStart = now.year * 12 + 1;
    final yearEnd = now.year * 12 + 12;
    final goalStart = startYear * 12 + startMonth;
    final goalEnd = endYear * 12 + endMonth;
    final overlapStart = goalStart < yearStart ? yearStart : goalStart;
    final overlapEnd = goalEnd > yearEnd ? yearEnd : goalEnd;
    return (overlapEnd - overlapStart + 1).clamp(0, 12);
  }
}
