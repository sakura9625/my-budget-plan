import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/review.dart';

final reviewProvider =
    StateNotifierProvider<ReviewNotifier, List<Review>>((ref) {
  return ReviewNotifier();
});

class ReviewNotifier extends StateNotifier<List<Review>> {
  ReviewNotifier() : super([]) {
    _load();
  }

  final _box = Hive.box<Review>('reviews');

  void _load() {
    state = _box.values.toList()
      ..sort((a, b) {
        final y = b.year.compareTo(a.year);
        return y != 0 ? y : b.month.compareTo(a.month);
      });
  }

  Future<void> save(Review review) async {
    // 同じ年月の既存レビューを削除してから保存する（月1個・上書き）。
    final dup = _box.values
        .where((r) => r.year == review.year && r.month == review.month)
        .toList();
    for (final r in dup) {
      await _box.delete(r.id);
    }
    await _box.put(review.id, review);
    _load();
  }

  // データリセット用（テスト・初期化用）
  Future<void> clear() async {
    await _box.clear();
    _load();
  }

  Review? get latest => state.isNotEmpty ? state.first : null;

  Review? getByYearMonth(int year, int month) {
    try {
      return state.firstWhere((r) => r.year == year && r.month == month);
    } catch (_) {
      return null;
    }
  }

  bool get hasCurrentMonthReview {
    final now = DateTime.now();
    return getByYearMonth(now.year, now.month) != null;
  }
}
