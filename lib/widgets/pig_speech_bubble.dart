import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

// キャラの上に乗るセリフ吹き出し。白背景・ネイビー文字、下端にキャラへ向く三角のしっぽ付き。
class PigSpeechBubble extends StatelessWidget {
  final String text;
  final double fontSize;
  const PigSpeechBubble(this.text, {super.key, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              height: 1.4,
            ),
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
    );
  }
}

// 吹き出し（上）＋キャラ画像（下）をまとめたウィジェット。
class PigWithSpeech extends StatelessWidget {
  final String asset;
  final String text;
  final double imageSize;
  final double fontSize;
  // trueの場合、キャラ画像だけを左右反転する（吹き出しの文字は反転しない）。
  final bool flipImage;
  const PigWithSpeech({
    super.key,
    required this.asset,
    required this.text,
    this.imageSize = 96,
    this.fontSize = 13,
    this.flipImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/characters/$asset',
      height: imageSize,
      fit: BoxFit.contain,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PigSpeechBubble(text, fontSize: fontSize),
        const SizedBox(height: 10),
        flipImage
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: image,
              )
            : image,
      ],
    );
  }
}
