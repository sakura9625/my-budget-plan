import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation.dart';

// 未来シミュレーションの条件一覧。アプリ再起動時の復元は不要なため、
// Hiveなどへの永続化はせずメモリ上だけで保持する。
final simulationConditionsProvider = StateNotifierProvider<
    SimulationConditionsNotifier, List<SimulationCondition>>((ref) {
  return SimulationConditionsNotifier();
});

class SimulationConditionsNotifier extends StateNotifier<List<SimulationCondition>> {
  SimulationConditionsNotifier() : super([]);

  void add(SimulationCondition condition) {
    state = [...state, condition];
  }

  void removeById(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void clear() {
    state = [];
  }
}
