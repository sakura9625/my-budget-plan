import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/funding_entry.dart';

final fundingProvider = StateNotifierProvider<FundingNotifier, List<FundingEntry>>((ref) {
  return FundingNotifier();
});

class FundingNotifier extends StateNotifier<List<FundingEntry>> {
  FundingNotifier() : super([]) {
    _load();
  }

  final _box = Hive.box<FundingEntry>('funding_entries');

  void _load() {
    state = _box.values.toList();
  }

  Future<void> add(FundingEntry entry) async {
    await _box.put(entry.id, entry);
    _load();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _load();
  }

  List<FundingEntry> forProject(String projectId) {
    return state.where((e) => e.projectId == projectId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
