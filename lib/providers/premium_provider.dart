import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// 未来シミュレーション課金（有料化）の購入済みフラグ。
// 単純なbool一つなのでHiveアダプタは使わず、プリミティブ型のままBox<bool>に保存する。
// アプリ再起動時もこの値がすぐ反映されるようにし、起動時のrestorePurchases()（後述の
// purchase_service.dart）が過去の購入を見つけた場合はここがtrueに更新される。
final premiumStatusProvider =
    StateNotifierProvider<PremiumStatusNotifier, bool>((ref) {
  return PremiumStatusNotifier();
});

class PremiumStatusNotifier extends StateNotifier<bool> {
  PremiumStatusNotifier() : super(false) {
    _load();
  }

  static const _key = 'isPremium';
  final _box = Hive.box<bool>('premium_status');

  void _load() {
    state = _box.get(_key, defaultValue: false) ?? false;
  }

  Future<void> setPremium(bool value) async {
    await _box.put(_key, value);
    state = value;
  }

  // データリセット用（テスト・初期化用）
  Future<void> clear() async {
    await _box.clear();
    _load();
  }
}
