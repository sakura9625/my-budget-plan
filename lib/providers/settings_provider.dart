import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings?>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings?> {
  SettingsNotifier() : super(null) {
    _load();
  }

  final _box = Hive.box<AppSettings>('settings');

  void _load() {
    state = _box.isNotEmpty ? _box.getAt(0) : null;
  }

  Future<void> save(AppSettings settings) async {
    if (_box.isEmpty) {
      await _box.add(settings);
    } else {
      await _box.putAt(0, settings);
    }
    state = settings;
  }
}
