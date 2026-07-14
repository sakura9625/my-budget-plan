import 'package:intl/intl.dart';

class Formatter {
  static final _comma = NumberFormat('#,###', 'ja_JP');

  /// 万円単位 → 「150万円」形式（小数点なし）
  static String man(double value) {
    return '${_comma.format(value.round())}万円';
  }

  /// 万円単位 → 「58.3万円」形式（小数点第1位まで）
  static String manDecimal(double value) {
    return '${value.toStringAsFixed(1)}万円';
  }

  /// 円単位 → 「1,500,000円」形式
  static String yen(double value) {
    return '${_comma.format(value.round())}円';
  }
}
