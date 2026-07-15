import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/calculation_provider.dart';
import '../providers/review_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tab_provider.dart';
import '../theme.dart';
import '../utils/formatter.dart';
import '../widgets/pig_background_body.dart';
import 'judgement_help_screen.dart';

// レビュータブのインデックス（MainScreenの_tabs順に対応）。
const int _reviewTabIndex = 2;

// 計画進捗を3段階に集約したもの（良好=safe/onTrack/comfortable、悪い=danger/needsReview、達成困難=difficult）
enum _ProgressTier { good, bad, difficult }

const String _noAffordDataComment = 'まずは予算とプロジェクトを登録しような！';

// 計画破綻時（①④月間自由枠マイナス、②movableFundsマイナス）のセリフ。
// 原資判定×計画進捗の9パターンより優先して判定する（①→②の順）。
enum _BreakdownStatus { excessivePlan, insufficientFunds }

const Map<_BreakdownStatus, String> _breakdownCommentTable = {
  _BreakdownStatus.excessivePlan:
      'さすがに計画に無理がありすぎるぜ！目標か予算を、一回見直そうや',
  _BreakdownStatus.insufficientFunds:
      'おっと、手元が足りてないぜ！このままじゃ回らねぇ。確保を少し戻すか、計画をゆるめようや',
};

// キャラのセリフ一覧（原資判定 × 計画進捗）。ここが唯一の管理場所。
// 表にない組み合わせ（余裕あり×悪い/達成困難、要自粛×悪い）は _pigComment() 側のフォールバックで解決する。
const Map<AffordStatus, Map<_ProgressTier, String>> _pigCommentTable = {
  AffordStatus.comfortable: {
    _ProgressTier.good:
        'イケイケだな！余裕も計画もバッチリだ！次の目標いっちゃう？もっと遊ぼうぜ！',
  },
  AffordStatus.ok: {
    _ProgressTier.good:
        '計画は花マルだ、やったじゃないか！今月は使いすぎ注意、そこだけ気をつけな！',
    _ProgressTier.bad:
        'カネは回ってる、そこはOK！けど計画が遅れ気味だぞ？財布のヒモ、キュッといこう！',
    _ProgressTier.difficult:
        'カネはあるある！…が、このままじゃ目標ムリかも、マジかよ！計画、練り直しだな！',
  },
  AffordStatus.tight: {
    _ProgressTier.good:
        'これまでの蓄えはお見事！やるねぇ！でも今月はちょーっと大人しめでいこうな！',
    _ProgressTier.bad:
        '進みは遅い、余裕も少なめ…しょぼーんだぜ。今月はグッと我慢のしどころだ！',
    _ProgressTier.difficult:
        'うわ、これはマズいぞ～！支出をキュッと絞って、計画も立て直しだ。踏ん張れ！',
  },
  AffordStatus.critical: {
    _ProgressTier.good:
        '蓄えはバッチリなんだけどな～、手元が寂しい、目を疑うぜ！今は使うの我慢だ！',
    _ProgressTier.difficult:
        'カネも計画も赤信号、マジかよ～！でも大丈夫、思い切って計画を練り直そうぜ！',
  },
};

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calc = ref.watch(calculationProvider);
    final reviews = ref.watch(reviewProvider);
    final hasReview = ref.read(reviewProvider.notifier).hasCurrentMonthReview;
    final settings = ref.watch(settingsProvider);
    // 赤アラートは「レビュー日を過ぎている（当日含む）」かつ「今月未実施」の両方を満たすときだけ。
    final reviewDay = settings?.reviewDay ?? 28;
    final showReviewAlert = !hasReview && DateTime.now().day >= reviewDay;

    if (calc == null) {
      return const Scaffold(
        body: Center(child: Text('設定を完了してください')),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('攻める家計簿'),
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
            tooltip: '見方について',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const JudgementHelpScreen(),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PigBackgroundBody(
        pigAsset: 'pig_navy_chair.png',
        children: [
          _buildHeadline(context, ref, showReviewAlert),
          const SizedBox(height: 4),
          _buildPigAndMoneyCard(calc),
          const SizedBox(height: 12),
          _buildBottomStatsRow(calc),
          const SizedBox(height: 28),
          _buildSectionTitle(context, '年間計画'),
          const SizedBox(height: 10),
          _buildOverallCard(context, calc),
          const SizedBox(height: 28),
          if (calc.goalCalculations.isNotEmpty) ...[
            _buildSectionTitle(context, 'プロジェクト・貯蓄'),
            const SizedBox(height: 10),
            ..._sortedGoals(calc).map((g) => _buildGoalCard(context, g)),
            const SizedBox(height: 28),
          ],
          if (calc.budgetCalculations.isNotEmpty) ...[
            _buildSectionTitle(context, '予算'),
            const SizedBox(height: 10),
            ...calc.budgetCalculations.map((b) => _buildBudgetCard(context, b)),
          ],
        ],
      ),
    );
  }

  List<GoalCalculation> _sortedGoals(CalculationResult calc) {
    final order = [
      PlanStatus.difficult,
      PlanStatus.needsReview,
      PlanStatus.danger,
      PlanStatus.safe,
      PlanStatus.onTrack,
      PlanStatus.comfortable,
    ];
    final sorted = [...calc.goalCalculations];
    sorted.sort((a, b) =>
        order.indexOf(a.planStatus).compareTo(order.indexOf(b.planStatus)));
    return sorted;
  }

  // 最上部バナー。計画状態に応じたメッセージは廃止し（役割はメインカードのキャラ
  // 吹き出しが担う）、「レビュー日を過ぎている（当日含む）かつ今月未実施」かどうかで
  // 2状態を出し分ける（レビュー日前は未実施でも赤にしない）。
  Widget _buildHeadline(
      BuildContext context, WidgetRef ref, bool showReviewAlert) {
    if (showReviewAlert) {
      return GestureDetector(
        onTap: () =>
            ref.read(mainTabIndexProvider.notifier).state = _reviewTabIndex,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.danger,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '今月のレビューがまだ完了していません。',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: AppTheme.navy, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '貯めないブタはただのブタ',
              style: TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 吹き出し＋顔（キャラのひとこと）と金色カード（動かせるお金）をまとめて1つの
  // Stackで組む。ブタ画像を金カードより前面のレイヤーに描画するため、行内では
  // レイアウト用の透明なブタ（余白確保だけ）を置き、実際に見えるブタ画像は
  // Stackの最後（＝最前面）にPositionedで重ねて描く。
  Widget _buildPigAndMoneyCard(CalculationResult calc) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pigWidth = constraints.maxWidth * 0.32;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                _buildPigBubbleRow(calc, pigWidth),
                const SizedBox(height: 4),
                _MainMoneyCard(calc: calc),
              ],
            ),
            Positioned(
              top: 24,
              right: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/characters/pig_common.png',
                  width: pigWidth,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPigBubbleRow(CalculationResult calc, double pigWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildSpeechBubble(calc),
          ),
        ),
        const SizedBox(width: 12),
        // 実際に見えるブタ画像はStack最前面のPositionedが担うため、ここでは
        // レイアウト上の高さ・幅だけを確保する透明なプレースホルダーにする。
        Opacity(
          opacity: 0,
          child: Image.asset(
            'assets/characters/pig_common.png',
            width: pigWidth,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeechBubble(CalculationResult calc) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            _pigComment(
              afford: calc.affordabilityStatus,
              planStatus: calc.overallPlanStatus,
              hasGoals: calc.goalCalculations.isNotEmpty,
              monthlyFreeAmount: calc.monthlyFreeAmount,
              movableFunds: calc.movableFunds,
            ),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                height: 1.4),
          ),
        ),
        Positioned(
          right: -6,
          child: Transform.rotate(
            angle: pi / 4,
            child: Container(width: 12, height: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // 最下段：計画進捗（左）／年間自由資金・計画を見込むと（右）。
  // Rowを直接ListView内に置くと、cross軸(縦)の制約が無限大になり
  // CrossAxisAlignment.stretchがBoxConstraints例外を起こすため、
  // IntrinsicHeightで先に高さを確定させてからstretchする。
  Widget _buildBottomStatsRow(CalculationResult calc) {
    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _statsBox([
            Text('計画進捗',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
            const SizedBox(height: 6),
            Text(
              '${(calc.totalPlanProgress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statsBox([
            _statRow('年間自由資金', _manNoYen(calc.annualFreeMoney)),
            const SizedBox(height: 8),
            _statRow('計画を見込むと', _manNoYen(calc.annualFreeAmount)),
          ]),
        ),
      ],
      ),
    );
  }

  Widget _statsBox(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // 万円単位（円を付けない簡潔表記）。年間自由資金・計画を見込むとの表示専用。
  String _manNoYen(double value) {
    if (value < 0) return '▲${value.abs().round()}万';
    return '${value.round()}万';
  }

  // キャラのひとこと。原資判定(AffordStatus)×計画進捗(_ProgressTier)の組み合わせから引く。
  // 予算・プロジェクトが1件もない場合のみ、判定不能として案内文を返す。
  // ただし①④月間自由枠マイナス／②movableFundsマイナスの計画破綻は、
  // 9パターン判定より先に判定する（①が根本問題のため①→②の順）。
  String _pigComment({
    required AffordStatus? afford,
    required PlanStatus? planStatus,
    required bool hasGoals,
    required double monthlyFreeAmount,
    required double movableFunds,
  }) {
    if (monthlyFreeAmount < 0) {
      return _breakdownCommentTable[_BreakdownStatus.excessivePlan]!;
    }
    if (movableFunds < 0) {
      return _breakdownCommentTable[_BreakdownStatus.insufficientFunds]!;
    }
    if (afford == null) return _noAffordDataComment;

    final tier = hasGoals ? _progressTierOf(planStatus) : _ProgressTier.good;
    final tierMap = _pigCommentTable[afford]!;
    // 表にない組み合わせは、達成困難寄りにフォールバックし、それも無ければ良好にフォールバックする。
    // （余裕あり×悪い/達成困難 → 1番。要自粛×悪い → 9番。いずれもこの2段階で解決する）
    return tierMap[tier] ??
        tierMap[_ProgressTier.difficult] ??
        tierMap[_ProgressTier.good]!;
  }

  _ProgressTier _progressTierOf(PlanStatus? status) {
    switch (status) {
      case PlanStatus.comfortable:
      case PlanStatus.onTrack:
      case PlanStatus.safe:
        return _ProgressTier.good;
      case PlanStatus.danger:
      case PlanStatus.needsReview:
        return _ProgressTier.bad;
      case PlanStatus.difficult:
        return _ProgressTier.difficult;
      case null:
        return _ProgressTier.good;
    }
  }

  Widget _buildBudgetCard(BuildContext context, BudgetCalculation b) {
    final color = AppTheme.budgetStatusColor(b.status);
    final label = AppTheme.budgetStatusLabel(b.status);
    // 今月の目安がマイナス（予算超過）のときだけ、表示専用の▲表記に切り替える。
    // 計算に使うb.currentMonthlyAmountは0クランプのまま変更しない。
    final isOverBudget = b.displayCurrentMonthlyAmount < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(b.budget.emoji ?? '💰',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.budget.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    if (isOverBudget) ...[
                      Text(
                        '今月の目安：▲${Formatter.man(b.displayCurrentMonthlyAmount.abs())}',
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12),
                      ),
                      Text(
                        '${Formatter.man(b.remainingAmount.abs())}オーバーしています',
                        style: const TextStyle(
                            color: AppTheme.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ] else
                      Text('月額 ${Formatter.man(b.currentMonthlyAmount)}',
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.budgetStatusBgColor(b.status),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('利用済 ${Formatter.man(b.budget.usedAmount)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              Text('残り ${Formatter.man(b.remainingAmount)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: b.usageRate.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallCard(BuildContext context, CalculationResult calc) {
    final hasNoGoals = calc.goalCalculations.isEmpty;

    if (hasNoGoals) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('📋', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('年間計画',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('計画なし',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  const Text('計画タブから貯蓄・プロジェクトを追加してください',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final color = AppTheme.planStatusColor(calc.overallPlanStatus ?? PlanStatus.safe);
    final label = AppTheme.planStatusLabel(calc.overallPlanStatus ?? PlanStatus.safe);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('全体進捗',
                        style: TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12)),
                    Text(
                      '${(calc.totalOverallProgress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('計画進捗',
                        style: TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12)),
                    Text(
                      '${(calc.totalPlanProgress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.planStatusBgColor(
                      calc.overallPlanStatus ?? PlanStatus.safe),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ],
          ),
          const Divider(height: 20),
          const Text(
            '毎月の自由枠を使い切った場合の計画達成見込みです。',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalCalculation g) {
    // 開始前のPJTはplanStatusが進捗0起因の「達成困難」になり得るため、
    // 専用の「開始前」表示にする（達成困難として誤表示しない）。
    final color =
        g.hasStarted ? AppTheme.planStatusColor(g.planStatus) : Colors.grey;
    final bgColor = g.hasStarted
        ? AppTheme.planStatusBgColor(g.planStatus)
        : const Color(0xFFF5F5F5);
    final label =
        g.hasStarted ? AppTheme.planStatusLabel(g.planStatus) : '開始前';
    final progress = g.overallProgress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(g.goal.emoji ?? '🎯',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.goal.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    Text(
                      g.goal.type.toString() == 'GoalType.saving'
                          ? '貯蓄'
                          : 'プロジェクト',
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
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
          _buildProgressWithPaceMarker(progress, g.plannedProgress, color),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Formatter.man(g.displayAmount)} / ${Formatter.man(g.goal.targetAmount)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                '全体 ${(g.overallProgress * 100).toStringAsFixed(1)}% / 計画 ${(g.planProgress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (g.remainingMonths > 0) ...[
            const SizedBox(height: 4),
            Text(
              '必要月額 ${Formatter.man(g.displayRequiredMonthlyAmount)} / 残${g.remainingMonths}ヶ月',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              '※自由枠使用後の残高をもとに計算した見込み額です。',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13,
              color: Colors.white.withOpacity(0.75),
            ));
  }

  // 進捗バー＋「本来あるべき進捗位置」の点線マーカー
  Widget _buildProgressWithPaceMarker(
      double progress, double plannedProgress, Color color) {
    final markerPosition = plannedProgress.clamp(0.0, 1.0);
    return SizedBox(
      height: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final markerX = markerPosition * constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 2,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 16,
                  ),
                ),
              ),
              Positioned(
                left: (markerX - 0.75).clamp(0.0, constraints.maxWidth - 1.5),
                top: 0,
                child: const _DashedVerticalMarker(height: 20),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 3枠（自由枠・予算枠・貯蓄枠）を▲▼で調整できる「表示だけのシミュレーション」。
// ここで動かす数値はこのウィジェットのローカルstateのみに閉じており、
// Provider・保存データ・他の計算には一切書き戻さない。画面を離れて（このWidgetが
// 破棄されて）戻れば、本来の値から再構築される。
class _MainMoneyCard extends StatefulWidget {
  final CalculationResult calc;
  const _MainMoneyCard({required this.calc});

  @override
  State<_MainMoneyCard> createState() => _MainMoneyCardState();
}

enum _FrameKind { free, budget, savings }

class _MainMoneyCardState extends State<_MainMoneyCard> {
  // 表示専用の調整値（万円単位）。本来の値はwidget.calcから毎回読み、
  // ここにはズレ（シミュレーション中の値）だけを保持する。
  late double _free;
  late double _budget;
  late double _savings;

  // 直近にstateを組み立てた際の本来値（実データ由来）。これが変わったら
  // ＝実データが変わったとみなし、シミュレーションを本来の値に作り直す。
  late double _baseMovable;
  late double _baseBudget;
  late double _baseSavings;

  @override
  void initState() {
    super.initState();
    _resetToBaseline(widget.calc);
  }

  @override
  void didUpdateWidget(covariant _MainMoneyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.calc.movableFunds != _baseMovable ||
        widget.calc.displayAffordBudget != _baseBudget ||
        widget.calc.displaySavingsFrame != _baseSavings) {
      _resetToBaseline(widget.calc);
    }
  }

  void _resetToBaseline(CalculationResult calc) {
    _baseMovable = calc.movableFunds;
    _baseBudget = calc.displayAffordBudget;
    _baseSavings = calc.displaySavingsFrame;
    _budget = _baseBudget;
    _savings = _baseSavings;
    _free = _baseMovable - _baseBudget - _baseSavings;
  }

  bool get _isAdjusted =>
      _budget != _baseBudget ||
      _savings != _baseSavings ||
      _free != (_baseMovable - _baseBudget - _baseSavings);

  // ▲▼のルール：3枠の合計は常に「今月動かせるお金」を維持する。
  // 1枠を1万動かすと、残り2枠が0.5万ずつ逆方向に動く。予算枠・貯蓄枠は
  // 0未満にできず、そこで止まった分は自由枠（マイナス可）が引き受ける。
  void _press(_FrameKind target, double sign) {
    setState(() {
      const step = 1.0;
      const half = 0.5;
      final increasing = sign > 0;

      switch (target) {
        case _FrameKind.free:
          if (increasing) {
            final bDec = _budget < half ? _budget : half;
            final sDec = _savings < half ? _savings : half;
            _free += bDec + sDec;
            _budget -= bDec;
            _savings -= sDec;
          } else {
            _free -= step;
            _budget += half;
            _savings += half;
          }
          break;
        case _FrameKind.budget:
          if (increasing) {
            final sDec = _savings < half ? _savings : half;
            final shortfall = half - sDec;
            _savings -= sDec;
            _free -= half + shortfall;
            _budget += step;
          } else {
            final bDec = _budget < step ? _budget : step;
            _budget -= bDec;
            final each = bDec / 2;
            _free += each;
            _savings += each;
          }
          break;
        case _FrameKind.savings:
          if (increasing) {
            final bDec = _budget < half ? _budget : half;
            final shortfall = half - bDec;
            _budget -= bDec;
            _free -= half + shortfall;
            _savings += step;
          } else {
            final sDec = _savings < step ? _savings : step;
            _savings -= sDec;
            final each = sDec / 2;
            _free += each;
            _budget += each;
          }
          break;
      }
    });
  }

  void _reset() {
    setState(() {
      _budget = _baseBudget;
      _savings = _baseSavings;
      _free = _baseMovable - _baseBudget - _baseSavings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final calc = widget.calc;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Formatter.manDecimal(calc.movableFunds),
                      style: const TextStyle(
                          color: AppTheme.navy,
                          fontSize: 30,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('が今月 動かせるお金',
                        style: TextStyle(
                            color: AppTheme.navy.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            if (calc.affordabilityStatus != null || _isAdjusted) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (calc.affordabilityStatus != null)
                    _affordabilityBadge(calc.affordabilityStatus!),
                  if (_isAdjusted) ...[
                    const SizedBox(width: 8),
                    _resetButton(),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _frameColumn(
                      label: '自由枠', baseValue: null, value: _free, kind: _FrameKind.free),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _frameColumn(
                      label: '予算枠',
                      baseValue: _baseBudget,
                      value: _budget,
                      kind: _FrameKind.budget),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _frameColumn(
                      label: '貯蓄枠',
                      baseValue: _baseSavings,
                      value: _savings,
                      kind: _FrameKind.savings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _frameColumn({
    required String label,
    required double? baseValue,
    required double value,
    required _FrameKind kind,
  }) {
    final labelText =
        baseValue == null ? label : '$label：${_frameAmountText(baseValue)}';
    final isNegative = value < -0.001;
    final canDecrease = kind == _FrameKind.free || value > 0.001;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(labelText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: AppTheme.navy.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_frameAmountText(value),
                style: TextStyle(
                    color: isNegative ? AppTheme.danger : AppTheme.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepButton(Icons.arrow_drop_up, () => _press(kind, 1)),
            const SizedBox(width: 4),
            _stepButton(
                Icons.arrow_drop_down, canDecrease ? () => _press(kind, -1) : null),
          ],
        ),
      ],
    );
  }

  Widget _stepButton(IconData icon, VoidCallback? onPressed) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.navy : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: enabled ? Colors.white : const Color(0xFFAAAAAA), size: 22),
      ),
    );
  }

  // 本体（原資判定バッジ）と同じ見た目にするため、AppThemeのヘルパーをそのまま使う。
  Widget _affordabilityBadge(AffordStatus status) {
    final label = AppTheme.affordStatusLabel(status);
    final color = AppTheme.affordStatusColor(status);
    final bgColor = AppTheme.affordStatusBgColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // 3枠を本来の値に戻すボタン。原資判定バッジの右隣に並べて表示する。
  Widget _resetButton() {
    return IconButton(
      icon: const Icon(Icons.refresh, color: AppTheme.navy, size: 20),
      tooltip: '本来の値に戻す',
      onPressed: _reset,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  // 0.5万刻みの調整値を表示用文字列にする（浮動小数の誤差は0.5万グリッドへのスナップで吸収）。
  // マイナスは本アプリの慣例に合わせ「▲」で表す。
  String _frameAmountText(double value) {
    final snapped = (value * 2).round() / 2;
    final isNegative = snapped < -0.001;
    final absVal = snapped.abs();
    final isWhole = (absVal - absVal.roundToDouble()).abs() < 0.001;
    final text = isWhole ? '${absVal.round()}万' : '${absVal.toStringAsFixed(1)}万';
    return isNegative ? '▲$text' : text;
  }
}

// ネイビーの点線マーカー（計画上あるべき進捗位置を示す）
class _DashedVerticalMarker extends StatelessWidget {
  final double height;
  const _DashedVerticalMarker({required this.height});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(1.5, height),
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.navy
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashHeight = 3.0;
    const dashSpace = 2.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0.75, y), Offset(0.75, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
