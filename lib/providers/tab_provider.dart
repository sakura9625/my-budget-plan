import 'package:flutter_riverpod/flutter_riverpod.dart';

// メイン画面の下部タブ選択状態。ホーム画面のバナーから「レビュー」タブへ
// 直接遷移させたい場合など、画面間でタブ切り替えを共有するために使う。
final mainTabIndexProvider = StateProvider<int>((ref) => 0);
