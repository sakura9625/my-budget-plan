import 'package:intl/intl.dart';

class Formatter {
  static final _yen = NumberFormat('#,###', 'ja_JP');
  static final _man = NumberFormat('#,###.#', 'ja_JP');

  /// 万円単位の数値を「150万円」形式で表示
  static String man(double value) {
    if (value == value.truncateToDouble()) {
      return '${NumberFormat('#,###').format(value.toInt())}万円';
    }
    return '${_man.format(value)}万円';
  }

  /// 円単位の数値を「1,500,000円」形式で表示
  static String yen(double value) {
    return '${_yen.format(value.toInt())}円';
  }

  /// 万円単位をそのまま数値文字列で「1,500」形式で表示（suffixText用）
  static String manNumber(double value) {
    return _yen.format(value.toInt());
  }
}
