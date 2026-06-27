import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/monthly_review.dart';

final monthlyReviewProvider =
    StateNotifierProvider<MonthlyReviewNotifier, List<MonthlyReview>>((ref) {
  return MonthlyReviewNotifier();
});

class MonthlyReviewNotifier extends StateNotifier<List<MonthlyReview>> {
  MonthlyReviewNotifier() : super([]) {
    _load();
  }

  final _box = Hive.box<MonthlyReview>('monthly_reviews');

  void _load() {
    state = _box.values.toList()
      ..sort((a, b) {
        final yearComp = b.year.compareTo(a.year);
        return yearComp != 0 ? yearComp : b.month.compareTo(a.month);
      });
  }

  Future<void> save(MonthlyReview review) async {
    await _box.put(review.id, review);
    _load();
  }

  MonthlyReview? getLatest() => state.isNotEmpty ? state.first : null;

  MonthlyReview? getByYearMonth(int year, int month) {
    try {
      return state.firstWhere((r) => r.year == year && r.month == month);
    } catch (_) {
      return null;
    }
  }
}
