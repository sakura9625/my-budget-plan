import 'package:flutter/material.dart';

// 画面下部に横幅いっぱいで自然に続く帯として表示するキャラ画像。
// 呼び出し元のListViewには横方向のpaddingを与えず、このウィジェットを
// 直接の子として並べることで、負のpadding計算なしに端まで表示する。
class PigBanner extends StatelessWidget {
  final String assetName;
  const PigBanner(this.assetName, {super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/characters/$assetName',
      width: double.infinity,
      fit: BoxFit.fitWidth,
    );
  }
}
