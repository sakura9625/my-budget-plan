import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../widgets/pig_speech_bubble.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _Page1(onNext: _goNext),
      _Page2(onNext: _goNext),
      _Page3(onNext: _goNext),
      _Page4(onNext: _goNext),
      _Page5(onNext: _goNext),
    ];
  }

  void _goNext() {
    if (_currentPage == _pages.length - 1) {
      context.go('/setup');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: _pages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == i ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == i
                ? AppTheme.primary
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ページ内埋め込み用の共通「次へ」ボタン。キャラ画像の下に置き、
// コンテンツの一部としてスクロールに含める（固定表示にしない）。
class _NextButton extends StatelessWidget {
  final String label;
  final VoidCallback onNext;
  const _NextButton({required this.label, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onNext,
      child: Text(label),
    );
  }
}

class _Page1 extends StatelessWidget {
  final VoidCallback onNext;
  const _Page1({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      emoji: '😔',
      title: 'お金のこと、こんなふうに思ったことはありませんか？',
      body: 'もっと貯金したい。\n趣味にもお金を使いたい。\n今月あといくら使っていいか分からない。\n\nでも、家計簿は続かない。',
      supplement: 'このアプリは、毎月1回・3つの入力だけで、あなたのお金の計画をサポートします。',
      prominentSupplement: true,
      pigAsset: 'pig_bank_cute.png',
      pigComment: 'それは助かる！めんどくさがりのボクにぴったりだ！',
      topSpacing: 0,
      onNext: onNext,
      buttonLabel: '次へ',
    );
  }
}

class _Page2 extends StatelessWidget {
  final VoidCallback onNext;
  const _Page2({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('お金ではなく、\n未来を管理します',
              style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 16),
          Text(
            '旅行、カメラ、貯蓄、推し活。\nお金を目的ごとに整理すると、\n「何に使っていいか」が見えるようになります。',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  height: 1.8,
                ),
          ),
          const SizedBox(height: 32),
          _buildDiagram(context),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _descItem('💰 貯蓄', '純粋に貯めておきたいお金'),
                const SizedBox(height: 8),
                _descItem('🎯 プロジェクト', '特定の目的・計画のためにつくりたいお金（例：海外旅行）'),
                const SizedBox(height: 8),
                _descItem('📋 予算', '「趣味にいくら使いたい！」というお金。生活費とは別にして管理'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Center(
            child: PigWithSpeech(
              asset: 'pig_bank_rich.png',
              text: 'なんでもかんでも登録すると失敗するから特別なやつだけ登録するんだぜ',
            ),
          ),
          const SizedBox(height: 32),
          _NextButton(label: '次へ', onNext: onNext),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _descItem(String label, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.textDark)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(desc,
              style: TextStyle(
                  color: AppTheme.textDark.withOpacity(0.7), fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildDiagram(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _diagramItem(context, '年間自由資金', AppTheme.primary, isTop: true),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          Row(
            children: [
              Expanded(child: _diagramItem(context, '貯蓄', AppTheme.success)),
              const SizedBox(width: 8),
              Expanded(
                  child: _diagramItem(context, 'プロジェクト', AppTheme.primary)),
              const SizedBox(width: 8),
              Expanded(
                  child: _diagramItem(context, '予算', AppTheme.needsReview)),
              const SizedBox(width: 8),
              Expanded(child: _diagramItem(context, '自由枠', Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _diagramItem(BuildContext context, String label, Color color,
      {bool isTop = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: isTop ? 14 : 11,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Page3 extends StatelessWidget {
  final VoidCallback onNext;
  const _Page3({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('今月、あといくら使えるか\nが分かります',
              style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 16),
          Text(
            '今月は余裕があるのか。\n少し自粛した方がいいのか。\nホームを見れば、すぐに分かります。',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  height: 1.8,
                ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今月は安心して使えます。',
                    style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const Divider(height: 24),
                _homeItem(
                    context, '今月の自由枠', '82,000円', '余裕あり', AppTheme.success),
                const SizedBox(height: 12),
                _homeItem(context, '旅行', '順調', '60%', AppTheme.onTrack),
                const SizedBox(height: 12),
                _homeItem(context, '推し活', '余裕あり', '32%', AppTheme.success),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Center(
            child: PigWithSpeech(
              asset: 'pig_bank_cute.png',
              text: 'おお！これは分かりやすい！',
            ),
          ),
          const SizedBox(height: 32),
          _NextButton(label: '次へ', onNext: onNext),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _homeItem(BuildContext context, String label, String value, String sub,
      Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textDark, fontSize: 14)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            Text(sub,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _Page4 extends StatelessWidget {
  final VoidCallback onNext;
  const _Page4({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('毎月1回、\nざっくりで大丈夫',
              style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 16),
          Text(
            '細かな家計簿は不要です。\n入力するのは、月に1回だけ。\n入力を忘れた月があっても、\n次回レビューで計画を調整できます。',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  height: 1.8,
                ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('毎月の入力はこれだけ',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.primary)),
                const SizedBox(height: 16),
                _inputItem(context, '1', '現在の残高'),
                const SizedBox(height: 12),
                _inputItem(context, '2', 'プロジェクト用に確保した金額'),
                const SizedBox(height: 12),
                _inputItem(context, '3', '予算で使った金額'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Expanded(
                child: PigWithSpeech(
                  asset: 'pig_bank_cute.png',
                  text: 'うんうん♪',
                  imageSize: 76,
                  fontSize: 12,
                  flipImage: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: PigWithSpeech(
                  asset: 'pig_bank_rich.png',
                  text: 'これならお前でも続くだろ？',
                  imageSize: 76,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _NextButton(label: '次へ', onNext: onNext),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _inputItem(BuildContext context, String num, String label) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(num,
                style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(color: AppTheme.textDark, fontSize: 16)),
      ],
    );
  }
}

class _Page5 extends StatelessWidget {
  final VoidCallback onNext;
  const _Page5({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      emoji: '🎯',
      title: 'あなた専用の\n年間予算を作りましょう',
      body:
          '年間手取り、固定費、貯蓄目標、\nプロジェクト、予算を登録すると、\n\n毎月あといくら使えるか、\n目標を達成できそうかを\n確認できるようになります。',
      pigAsset: 'pig_bank_rich.png',
      pigComment: 'オレさまは家計簿を振り返るためにつけるんじゃねぇ。攻めるために使うんだぜ',
      onNext: onNext,
      buttonLabel: '年間予算を作る',
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  final String? supplement;
  final bool prominentSupplement;
  final String? pigAsset;
  final String? pigComment;
  final double topSpacing;
  final VoidCallback onNext;
  final String buttonLabel;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.body,
    this.supplement,
    this.prominentSupplement = false,
    this.pigAsset,
    this.pigComment,
    this.topSpacing = 24,
    required this.onNext,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topSpacing),
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 16),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  height: 1.8,
                ),
          ),
          if (supplement != null) ...[
            SizedBox(height: prominentSupplement ? 28 : 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(prominentSupplement ? 24 : 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                supplement!,
                textAlign:
                    prominentSupplement ? TextAlign.center : TextAlign.start,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primary,
                      height: 1.6,
                      fontSize: prominentSupplement ? 16 : null,
                      fontWeight: prominentSupplement
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
              ),
            ),
          ],
          if (pigAsset != null && pigComment != null) ...[
            const SizedBox(height: 32),
            Center(child: PigWithSpeech(asset: pigAsset!, text: pigComment!)),
          ],
          const SizedBox(height: 32),
          _NextButton(label: buttonLabel, onNext: onNext),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
