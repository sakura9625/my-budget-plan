import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation.dart';
import '../providers/simulation_provider.dart';
import '../theme.dart';
import '../utils/formatter.dart';
import '../widgets/pig_background_body.dart';
import 'simulation_condition_type_screen.dart';
import 'simulation_result_screen.dart';

// 未来シミュレーション トップ画面。
// 「現在のデータを変えずに、計画を変更した場合の影響を確認する」機能の入口。
// この段階では条件の追加・一覧・削除の器と画面遷移のみで、実際の再計算は行わない。
class SimulationTab extends ConsumerWidget {
  const SimulationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditions = ref.watch(simulationConditionsProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('未来シミュレーション'),
        actions: [
          IconButton(
            icon: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Text('?',
                  style: TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            tooltip: '使い方',
            onPressed: () => _showHelpDialog(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PigBackgroundBody(
        pigAsset: 'pig_bank_rich.png',
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '計画を変更した場合の影響を、現在のデータを変えずに確認できます。',
              style: TextStyle(
                color: Color(0xFFC7CDDB),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (conditions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'まだ条件がありません。\n「条件を追加」から作成してください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ...conditions.map((c) => _ConditionCard(condition: c)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SimulationConditionTypeScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('条件を追加'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: conditions.isEmpty
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SimulationResultScreen(),
                      ),
                    );
                  },
            child: const Text('未来をシミュレーション'),
          ),
        ],
      ),
    );
  }

  static void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('未来シミュレーションの使い方',
            style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _helpSectionTitle('未来シミュレーションとは'),
                _helpBody(
                    'いまの計画を変えずに、「もし〜したら？」を試せる機能です。\n'
                    '新しいプロジェクトを始めたり、大きな買い物をしたら、家計がどう変わるかを'
                    '事前に確認できます。試した内容は、あなたが「反映」するまで実際の計画には影響しません。'),
                const SizedBox(height: 16),
                _helpSectionTitle('使い方'),
                _helpStep(1, '「条件を追加」から、試したいことを選びます。'),
                _helpBullet('新しいプロジェクトを追加'),
                _helpBullet('既存プロジェクトを変更もしくは削除'),
                _helpBullet('予算月額を変更もしくは削除'),
                _helpBullet('大きな買い物をする'),
                _helpBullet('プロジェクトを断念'),
                _helpBullet('固定費を変更'),
                _helpStep(2, '必要な項目を入力して登録します。条件は何個でも組み合わせられます。'),
                _helpStep(
                    3,
                    '「未来をシミュレーション」を押すと、現状（現在の計画）と'
                    'シミュレーション結果を左右で見比べられます。'),
                Padding(
                  padding: const EdgeInsets.only(left: 34, bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/help/simulation_result_sample.png',
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                _helpStep(4, '気に入った内容は「現在の計画へ反映」で、実際の計画に保存できます。'),
                const SizedBox(height: 16),
                _helpSectionTitle('ポイント'),
                _helpPointBullet('「反映」するまで、いまの計画・残高・確保額などは一切変わりません。'),
                _helpPointBullet(
                    '大きな買い物は、実際に購入したあと、次回のレビューで反映してください'
                    '（シミュレーションでは確認のみ）。'),
                _helpPointBullet('複数の条件を同時に試せます（例：固定費が増えて、旅行を追加したら？）。'),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppTheme.navy,
                side: const BorderSide(color: Color(0xFFB9C0D9)),
              ),
              child: const Text('閉じる', textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _helpSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  static Widget _helpBody(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(color: AppTheme.textDark, fontSize: 13, height: 1.6)),
    );
  }

  // 手順1〜4の番号バッジ。丸背景（ネイビー）＋白文字の数字で、番号が一目で分かるようにする。
  static Widget _helpStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.navy,
              shape: BoxShape.circle,
            ),
            child: Text('$number',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text,
                  style: const TextStyle(
                      color: AppTheme.textDark, fontSize: 13, height: 1.6)),
            ),
          ),
        ],
      ),
    );
  }

  // 手順1のサブ項目（条件タイプ一覧）用の控えめな「・」箇条書き。
  static Widget _helpBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 34),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('・',
              style: TextStyle(color: AppTheme.textDark, fontSize: 13, height: 1.6)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textDark, fontSize: 13, height: 1.6)),
          ),
        ],
      ),
    );
  }

  // 「ポイント」セクション用の、目立つアクセントカラーの丸箇条書き。
  static Widget _helpPointBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 8, color: AppTheme.primaryDark),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textDark, fontSize: 13, height: 1.6)),
          ),
        ],
      ),
    );
  }
}

class _ConditionCard extends ConsumerWidget {
  final SimulationCondition condition;
  const _ConditionCard({required this.condition});

  String get _label {
    switch (condition) {
      case AddGoalCondition c:
        return '${c.name}を追加 ${Formatter.man(c.targetAmount)}';
      case EditGoalCondition c:
        return c.isDelete ? '${c.name} 削除' : '${c.name}に変更';
      case EditBudgetCondition c:
        return c.isDelete
            ? '${c.name} 削除'
            : '${c.name} 月額${Formatter.man(c.monthlyAmount)}に変更';
      case ReduceBalanceCondition c:
        return '${c.purchaseName} ${Formatter.man(c.amount)}';
      case ChangeGoalStatusCondition c:
        return '${c.goalName}を断念';
      case ChangeFixedCostCondition c:
        return '固定費を${Formatter.man(c.newAnnualFixedCost)}に変更';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(_label,
                style: const TextStyle(
                    color: AppTheme.textDark, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF6B7280), size: 20),
            onPressed: () {
              // 編集は「削除して選び直す」方式にする（重複登録を防ぐため）。
              ref
                  .read(simulationConditionsProvider.notifier)
                  .removeById(condition.id);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SimulationConditionTypeScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.danger, size: 20),
            onPressed: () => ref
                .read(simulationConditionsProvider.notifier)
                .removeById(condition.id),
          ),
        ],
      ),
    );
  }
}
