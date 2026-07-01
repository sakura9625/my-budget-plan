import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/goal.dart';

final goalProvider =
    StateNotifierProvider<GoalNotifier, List<Goal>>((ref) {
  return GoalNotifier();
});

class GoalNotifier extends StateNotifier<List<Goal>> {
  GoalNotifier() : super([]) {
    _load();
  }

  final _box = Hive.box<Goal>('goals');

  void _load() {
    state = _box.values.toList();
  }

  Future<void> add(Goal goal) async {
    await _box.put(goal.id, goal);
    _load();
  }

  Future<void> update(Goal goal) async {
    await _box.put(goal.id, goal);
    _load();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _load();
  }

  List<Goal> get activeGoals =>
      state.where((g) => g.status == GoalStatus.active).toList();
}
