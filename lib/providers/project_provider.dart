import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project.dart';

final projectsProvider = StateNotifierProvider<ProjectsNotifier, List<Project>>((ref) {
  return ProjectsNotifier();
});

class ProjectsNotifier extends StateNotifier<List<Project>> {
  ProjectsNotifier() : super([]) {
    _load();
  }

  final _box = Hive.box<Project>('projects');

  void _load() {
    state = _box.values.toList();
  }

  Future<void> add(Project project) async {
    await _box.put(project.id, project);
    _load();
  }

  Future<void> update(Project project) async {
    await _box.put(project.id, project);
    _load();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _load();
  }
}
