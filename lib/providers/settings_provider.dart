import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/life_settings.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, LifeSettings?>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<LifeSettings?> {
  SettingsNotifier() : super(null) {
    _load();
  }

  final _box = Hive.box<LifeSettings>('settings');

  void _load() {
    state = _box.isNotEmpty ? _box.getAt(0) : null;
  }

  Future<void> save(LifeSettings settings) async {
    if (_box.isEmpty) {
      await _box.add(settings);
    } else {
      await _box.putAt(0, settings);
    }
    state = settings;
  }
}
