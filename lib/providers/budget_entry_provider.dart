import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget_entry.dart';

final budgetEntryProvider =
    StateNotifierProvider<BudgetEntryNotifier, List<BudgetEntry>>((ref) {
  return BudgetEntryNotifier();
});

class BudgetEntryNotifier extends StateNotifier<List<BudgetEntry>> {
  BudgetEntryNotifier() : super([]) {
    _load();
  }

  final _box = Hive.box<BudgetEntry>('budget_entries');

  void _load() {
    state = _box.values.toList();
  }

  Future<void> add(BudgetEntry entry) async {
    await _box.put(entry.id, entry);
    _load();
  }

  Future<void> update(BudgetEntry entry) async {
    await _box.put(entry.id, entry);
    _load();
  }

  // データリセット用（テスト・初期化用）
  Future<void> clear() async {
    await _box.clear();
    _load();
  }

  List<BudgetEntry> forBudget(String budgetId) {
    return state.where((e) => e.budgetId == budgetId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
