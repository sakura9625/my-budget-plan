import 'package:flutter/material.dart';

// 背景にキャラを敷いた画面共通レイアウト。
// キャラ画像は最背面に固定表示し、コンテンツはその上のスクロール可能なレイヤーに置く。
// コンテンツ下部にキャラの高さ分の余白を確保し、最後までスクロールするとキャラ全身が見える。
class PigBackgroundBody extends StatelessWidget {
  final String pigAsset;
  final List<Widget> children;
  final double horizontalPadding;
  final double topPadding;
  final double bottomExtraPadding;

  const PigBackgroundBody({
    super.key,
    required this.pigAsset,
    required this.children,
    this.horizontalPadding = 16,
    this.topPadding = 16,
    this.bottomExtraPadding = 24,
  });

  // 各キャラ画像は同じアスペクト比（約1408x768）で書き出されている
  static const _pigAspectRatio = 1408 / 768;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = constraints.maxWidth / _pigAspectRatio;
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Image.asset(
                'assets/characters/$pigAsset',
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            ),
            Positioned.fill(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  imageHeight + bottomExtraPadding,
                ),
                children: children,
              ),
            ),
          ],
        );
      },
    );
  }
}
