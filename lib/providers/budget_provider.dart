import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget.dart';

final budgetProvider =
    StateNotifierProvider<BudgetNotifier, List<Budget>>((ref) {
  return BudgetNotifier();
});

class BudgetNotifier extends StateNotifier<List<Budget>> {
  BudgetNotifier() : super([]) {
    _load();
  }

  final _box = Hive.box<Budget>('budgets');

  void _load() {
    state = _box.values.toList();
  }

  Future<void> add(Budget budget) async {
    await _box.put(budget.id, budget);
    _load();
  }

  Future<void> update(Budget budget) async {
    await _box.put(budget.id, budget);
    _load();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _load();
  }
}
