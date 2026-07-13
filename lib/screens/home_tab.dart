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
      ),
      body: PigBackgroundBody(
        pigAsset: 'pig_navy_chair.png',
        children: [
          _buildHeadline(context, ref, showReviewAlert),
          const SizedBox(height: 20),
          _buildFreeAmountCard(context, calc),
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

  Widget _buildFreeAmountCard(BuildContext context, CalculationResult calc) {
    final hasGoals = calc.goalCalculations.isNotEmpty;

    // カードの実際の描画幅を基準にキャラのサイズを決める。MediaQuery.size.widthは
    // ウィンドウ/ビューポート全体の幅であり、Web版ではスクロールバー分などの差異で
    // 実際にカードへ割り当てられる幅と数px〜十数pxずれることがあり、それが右端の
    // オーバーフローの原因になる。LayoutBuilderでこのカード自身の実測幅を使うことで
    // 常にレイアウトと矛盾しないサイズにする。
    return LayoutBuilder(
      builder: (context, constraints) {
        // 顔を大きくしすぎると右側の吹き出し用スペース（bubbleWidth）が左のテキスト列を
        // 圧迫し、金額などが不自然な位置で折り返されるため、テキスト優先で控えめにする。
        final pigWidth = constraints.maxWidth * 0.44;
        // pig_common.pngはトリミング済みの正方形素材（769x768）。widthのみ指定し
        // 高さは元画像の比率で自動計算する。
        final pigHeight = pigWidth / (769 / 768);
        // 吹き出し＋顔の右側ブロックがRow内で確保する幅。これがそのまま左テキスト列の
        // 残り幅を決めるため、中央（0.5）を超えないよう、ちょうど半分に制限する。
        final bubbleWidth = constraints.maxWidth * 0.5;
        // 吹き出し＋顔がテキスト列と重ならないよう、テキスト列側にもその分の高さを確保する
        // （吹き出しの文字数で高さが変わるため、長めのセリフでも2〜3行で収まる想定の概算値）。
        const bubbleHeightEstimate = 100.0;
        // 顔をカード下端にべったり付けないための余白（近づけつつ少し余裕を残す）。
        const pigBottomSpacing = 16.0;

        return _buildFreeAmountCardContent(
          context,
          calc,
          hasGoals,
          pigWidth,
          pigHeight,
          bubbleWidth,
          bubbleHeightEstimate,
          pigBottomSpacing,
        );
      },
    );
  }

  Widget _buildFreeAmountCardContent(
    BuildContext context,
    CalculationResult calc,
    bool hasGoals,
    double pigWidth,
    double pigHeight,
    double bubbleWidth,
    double bubbleHeightEstimate,
    double pigBottomSpacing,
  ) {
    return ClipRRect(
      // 顔をカードの右下角ぴったりまで届かせる（Positionedでカード端に直接配置する）ため、
      // 角の外に絵がはみ出さないよう、カードの角丸に合わせてクリップする。
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                // 1. 今月 動かせるお金
                Text('今月 動かせるお金',
                    style: TextStyle(
                        color: AppTheme.navy.withOpacity(0.6), fontSize: 13)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Formatter.man(calc.movableFunds),
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 2. 原資判定バッジ
                if (calc.affordabilityStatus != null) ...[
                  const SizedBox(height: 8),
                  _affordabilityBadge(calc.affordabilityStatus!),
                ],
                const SizedBox(height: 10),
                // 3. 初期計画時の月間自由枠
                _summaryChip(
                    '初期計画時の月間自由枠', Formatter.man(calc.monthlyFreeAmount)),
                const SizedBox(height: 8),
                // 4. 予算枠（表示はマイナス許容。計算に使うcalc.affordBudgetは0クランプのまま）
                _summaryChip('予算枠', _formatSignedMan(calc.displayAffordBudget)),
                // 5. 計画進捗
                if (hasGoals) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('計画進捗',
                          style: TextStyle(
                              color: AppTheme.navy.withOpacity(0.6),
                              fontSize: 11)),
                      const SizedBox(width: 6),
                      Text(
                        '${(calc.totalPlanProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: AppTheme.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
                // 6. 年間自由資金 / 予算を除くと（縦積み。左テキスト列の幅をフルに使う）
                const SizedBox(height: 10),
                        _summaryChip(
                            '年間自由資金', Formatter.man(calc.annualFreeMoney)),
                        const SizedBox(height: 8),
                        _summaryChip(
                            '予算を除くと', Formatter.man(calc.annualFreeAmount)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 右側は吹き出し＋顔の分だけ幅・高さを確保するプレースホルダー。
                  // 吹き出しと顔本体はこの下でPositionedとしてまとめて配置するため、
                  // ここでは左のテキスト列と重ならないためのスペース確保のみ行う。
                  SizedBox(
                    width: bubbleWidth,
                    height: bubbleHeightEstimate + 10 + pigHeight + pigBottomSpacing,
                  ),
                ],
              ),
            ),
            // 吹き出し＋顔を「ひとかたまり」として、カード下寄りにまとめて配置する
            // （中央寄せだと顔の下に余白が空きすぎるため、下寄り＋余白少なめにする）。
            // 右側にも少し余白を持たせ、吹き出しがカード右端にくっつかないようにする。
            Positioned(
              bottom: pigBottomSpacing,
              right: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildSpeechBubble(calc, bubbleWidth),
                  const SizedBox(height: 10),
                  Image.asset(
                    'assets/characters/pig_common.png',
                    width: pigWidth,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeechBubble(CalculationResult calc, double bubbleWidth) {
    return SizedBox(
      width: bubbleWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.4),
            ),
          ),
          Positioned(
            bottom: -6,
            child: Transform.rotate(
              angle: pi / 4,
              child: Container(width: 12, height: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

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

  // マイナスのときは「▲◯万円」で表示する（表示専用。計算には使わない）。
  String _formatSignedMan(double value) {
    if (value < 0) return '▲${Formatter.man(value.abs())}';
    return Formatter.man(value);
  }

  Widget _summaryChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: AppTheme.navy.withOpacity(0.6), fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
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
                      '${(calc.totalOverallProgress * 100).toStringAsFixed(0)}%',
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
                      '${(calc.totalPlanProgress * 100).toStringAsFixed(0)}%',
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
    final color = AppTheme.planStatusColor(g.planStatus);
    final label = AppTheme.planStatusLabel(g.planStatus);
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
                  color: AppTheme.planStatusBgColor(g.planStatus),
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
                '全体 ${(g.overallProgress * 100).toStringAsFixed(0)}% / 計画 ${(g.planProgress * 100).toStringAsFixed(0)}%',
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
