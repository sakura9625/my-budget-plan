import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/manual_entry.dart';

final manualEntryProvider =
    StateNotifierProvider<ManualEntryNotifier, List<ManualEntry>>((ref) {
  return ManualEntryNotifier();
});

class ManualEntryNotifier extends StateNotifier<List<ManualEntry>> {
  ManualEntryNotifier() : super([]) {
    _load();
  }

  final _box = Hive.box<ManualEntry>('manual_entries');

  void _load() {
    state = _box.values.toList();
  }

  Future<void> add(ManualEntry entry) async {
    await _box.put(entry.id, entry);
    _load();
  }

  // データリセット用（テスト・初期化用）
  Future<void> clear() async {
    await _box.clear();
    _load();
  }

  List<ManualEntry> forGoal(String goalId) {
    return state.where((e) => e.goalId == goalId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
