import 'package:flutter/material.dart';
import '../providers/calculation_provider.dart';
import '../theme.dart';

// 「見方について」説明ページ。
// ホームのメインカードに出てくる数字と、3種類のバッジ（原資判定/計画進捗判定/予算判定）
// が何を意味するかを説明する。バッジの色・ラベルはAppThemeの判定系ヘルパー
// （afford/plan/budgetStatus〜）をそのまま使い、本体の表示とズレないようにする。
class JudgementHelpScreen extends StatelessWidget {
  const JudgementHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '見方について',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _body(
                'ホームには、今のお金の状態や目標の進み具合が表示されます。'
                'ここでは、それぞれの数字とバッジの意味を説明します。',
              ),
              const SizedBox(height: 28),

              // ── 1. メインカードの数字 ──
              _sectionTitle('メインカードの数字'),
              const SizedBox(height: 12),
              _infoTable(
                [
                  (
                    [_numberLabel('今月 動かせるお金')],
                    '口座残高から、これまでに積んでおくべき貯蓄・プロジェクトのぶんを差し引いた、'
                        '今の時点で口座から動かせるお金です。ただし、この中には今月ぶんの予算枠・貯蓄枠が'
                        'まだ含まれています。実際に自由に使えるのは、ここから予算枠と貯蓄枠を確保した残りです。'
                        'どれくらい余裕があるかは、下の「お金の余裕の判定」バッジで確認できます。',
                  ),
                  (
                    [_numberLabel('予算枠')],
                    '今月使える予算（推し活などの費目）の合計です。期間内の予算だけが対象です。',
                  ),
                  (
                    [_numberLabel('貯蓄枠')],
                    '今月、貯蓄・プロジェクトのために積み立てるべき額の合計です。'
                        '今まさに積み立て期間にあるものが対象です。',
                  ),
                  (
                    [_numberLabel('計画進捗')],
                    '「今の時点で本来これくらい進んでいるはず」というペースに対して、実際にどれだけ'
                        '進んでいるかを表します。100%を超えていれば予定より進んでいる状態です。',
                  ),
                ],
                leftColumnWidth: 112,
              ),
              const SizedBox(height: 28),

              // ── 2. お金の余裕の判定（バッジ） ──
              _sectionTitle('お金の余裕の判定'),
              _body('今月どれくらい自由にお金を使える状態かを4段階で表しています。'),
              const SizedBox(height: 12),
              _infoTable([
                (
                  [_affordBadge(AffordStatus.comfortable)],
                  '予算も、貯蓄・プロジェクトへの積み立ても、自由に使うお金も、すべてまかなえる状態です。'
                      '計画どおりに使って大丈夫です。',
                ),
                (
                  [_affordBadge(AffordStatus.ok)],
                  '予算と自由に使うお金は確保できますが、貯蓄・プロジェクトへの積み立てまで含めると'
                      '少し足りない状態です。使いすぎに注意しましょう。',
                ),
                (
                  [_affordBadge(AffordStatus.tight)],
                  '予算は払えますが、それを差し引くと自由に使えるお金が計画より少なくなる状態です。'
                      '今月は控えめにしておくのが安心です。',
                ),
                (
                  [_affordBadge(AffordStatus.critical)],
                  '予算をまかなうのも厳しい状態か、そもそも計画に無理がある状態です。'
                      '目標や予算を見直すことをおすすめします。',
                ),
              ]),
              const SizedBox(height: 28),

              // ── 3. 目標の進み具合の判定（バッジ） ──
              _sectionTitle('目標の進み具合の判定'),
              _body('貯蓄やプロジェクトが目標に対して予定どおり進んでいるかを表しています。'),
              const SizedBox(height: 12),
              _infoTable([
                (
                  [_planBadge(PlanStatus.safe)],
                  '計画に対して順調に進んでいます。このペースを保ちましょう。',
                ),
                (
                  [_planBadge(PlanStatus.needsReview)],
                  'やや遅れ気味です。ペースを上げるか、目標や期間の見直しを検討しましょう。',
                ),
                (
                  [_planBadge(PlanStatus.danger), _planBadge(PlanStatus.difficult)],
                  'このままのペースでは目標の達成が難しい状態です。'
                      '目標額や期限、積み立て額を見直しましょう。',
                ),
                (
                  [_notStartedBadge()],
                  'まだ開始月になっていないプロジェクトです。開始月になると判定が始まります。',
                ),
              ]),
              const SizedBox(height: 28),

              // ── 4. 予算の判定（バッジ） ──
              _sectionTitle('予算の判定'),
              _body('各予算を、決めた予算に対してどれくらい使ったか（使いすぎていないか）で表しています。'),
              const SizedBox(height: 12),
              _infoTable([
                (
                  [_budgetBadge(BudgetStatus.comfortable)],
                  '予算にまだ余裕があります（使用は8割未満）。このペースで大丈夫です。',
                ),
                (
                  [_budgetBadge(BudgetStatus.safe)],
                  '予算の8割ほどを使っています。残りに気をつけながら使いましょう。',
                ),
                (
                  [_budgetBadge(BudgetStatus.danger)],
                  '予算を使い切り、少しオーバーしています。今月は控えめにしましょう。',
                ),
                (
                  [_budgetBadge(BudgetStatus.overBudget)],
                  '予算を大きくオーバーしています（2割以上超過）。使いすぎに注意してください。',
                ),
              ]),
              const SizedBox(height: 8),
              _body('※これは予算ごとの使用状況で、上の「お金の余裕の判定」とは別の判定です。'),
              const SizedBox(height: 28),

              // ── 補足 ──
              _sectionTitle('補足'),
              _bullet('判定は、入力した収入・固定費・目標・予算・残高をもとに自動で計算されます。'),
              _bullet('判定はあくまで目安です。実際のお金の使い方はご自身の状況に合わせて判断してください。'),
              _bullet('数字や判定が想定と違うときは、各項目の入力内容（金額や期間）を見直してみてください。'),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.bottomRight,
                child: Image.asset(
                  'assets/characters/pig_bank_cute.png',
                  width: 110,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
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
        ),
      ),
    );
  }

  static Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  static Widget _body(String text) {
    return Text(text,
        style: const TextStyle(color: AppTheme.textDark, fontSize: 13, height: 1.6));
  }

  // メインカードの数字テーブル用の項目名ラベル（左列）。
  static Widget _numberLabel(String text) {
    return Text(text,
        style: const TextStyle(
            color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 13, height: 1.4));
  }

  // 左列（幅固定）＋説明文列の2列テーブル。左列の中身の文字数が違っても
  // 説明文の開始位置が全行で揃うようにする。行の間は薄い罫線で区切り、
  // テーブル全体は薄いベージュのカードに乗せる。
  // 1項目に複数バッジが対応する場合（「危険・達成困難」等）はWrapで折り返す。
  static Widget _infoTable(List<(List<Widget> left, String text)> rows,
      {double leftColumnWidth = 96}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        columnWidths: {0: FixedColumnWidth(leftColumnWidth)},
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        border: const TableBorder(
          horizontalInside: BorderSide(color: Color(0xFFEADFC4)),
        ),
        children: [
          for (final row in rows)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: row.$1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 10, bottom: 10),
                  child: Text(row.$2,
                      style: const TextStyle(
                          color: AppTheme.textDark, fontSize: 11, height: 1.6)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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

  // 本体（home_tab.dart等）のバッジと同じ見た目（色・角丸ピル）にするため、
  // AppThemeの判定系ヘルパーをそのまま使う。
  static Widget _affordBadge(AffordStatus status) {
    return _statusBadge(
      AppTheme.affordStatusLabel(status),
      AppTheme.affordStatusColor(status),
      AppTheme.affordStatusBgColor(status),
    );
  }

  static Widget _planBadge(PlanStatus status) {
    return _statusBadge(
      AppTheme.planStatusLabel(status),
      AppTheme.planStatusColor(status),
      AppTheme.planStatusBgColor(status),
    );
  }

  static Widget _budgetBadge(BudgetStatus status) {
    return _statusBadge(
      AppTheme.budgetStatusLabel(status),
      AppTheme.budgetStatusColor(status),
      AppTheme.budgetStatusBgColor(status),
    );
  }

  // home_tab.dartの「開始前」バッジ（開始前のプロジェクト）と同じ配色を再現。
  static Widget _notStartedBadge() {
    return _statusBadge('開始前', Colors.grey, const Color(0xFFF5F5F5));
  }

  static Widget _statusBadge(String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
