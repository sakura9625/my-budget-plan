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
    await _box.put(review.id, review);
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
