import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../providers/premium_provider.dart';

// 未来シミュレーションの年額課金の商品ID（App Store Connect / Google Play Consoleに
// 登録するIDと一致させること）。
const String kSimulationYearlyProductId = 'mybudgetplan_simulation_yearly';

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService(ref);
  ref.onDispose(service.dispose);
  return service;
});

// アプリ起動時に一度だけ購読して、過去の購入状態をリストア（復元）する。
// FutureProviderのキャッシュにより、アプリ起動中は一度しか実行されない。
final purchaseRestoreProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(purchaseServiceProvider);
  await service.restorePurchases();
});

// 未来シミュレーション年額課金の商品情報（ローカライズ済み価格文字列を含む）。
// ペイウォールUI（次のステップ）はこれをwatchして価格を表示する想定。
// ストア未接続・商品未取得時はnullを返す。
final simulationProductProvider = FutureProvider<ProductDetails?>((ref) async {
  final service = ref.watch(purchaseServiceProvider);
  final response = await service.queryProductDetails();
  if (response.productDetails.isEmpty) return null;
  return response.productDetails.first;
});

// 未来シミュレーションの年額課金（商品情報取得・購入・復元）を扱う土台。
// この段階では購入処理までを実装し、ペイウォールUI・タブの出し分けは次のステップで行う。
//
// in_app_purchaseはApp Store/Google Playの実プラットフォームが前提のプラグインのため、
// Web/デスクトップ（Chrome確認用の開発サーバー等）ではプラットフォーム実装が
// 登録されておらずMissingPluginException等で落ちる。そのためAndroid/iOS以外では
// 各メソッドを早期リターンのno-opにし、他プラットフォームでもビルド・起動できるようにする。
class PurchaseService {
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  PurchaseService(this._ref) {
    if (!_isSupportedPlatform) return;
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        debugPrint('[PurchaseService] purchaseStream error: $error');
      },
    );
  }

  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  // 商品情報（ローカライズ済み価格文字列を含む）を取得する。
  // 失敗原因の調査用に、結果（取得できた商品ID・notFoundIDs・エラー内容）を
  // デバッグログへ出力する。UI側にはエラー文言を出さない。
  Future<ProductDetailsResponse> queryProductDetails() async {
    if (!_isSupportedPlatform) {
      debugPrint('[PurchaseService] queryProductDetails: unsupported platform '
          '(kIsWeb=$kIsWeb, defaultTargetPlatform=$defaultTargetPlatform)');
      return ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: [kSimulationYearlyProductId],
      );
    }
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[PurchaseService] queryProductDetails: store not available');
      return ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: [kSimulationYearlyProductId],
      );
    }
    final response = await _iap.queryProductDetails({kSimulationYearlyProductId});
    debugPrint('[PurchaseService] queryProductDetails result: '
        'found=${response.productDetails.map((p) => p.id).toList()}, '
        'notFoundIDs=${response.notFoundIDs}, '
        'error=${response.error}');
    return response;
  }

  // 購入を開始する。結果はpurchaseStream経由で_handlePurchaseUpdatesに届く。
  Future<void> buy(ProductDetails product) async {
    if (!_isSupportedPlatform) return;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // 購入を復元する（審査必須）。復元されたPurchaseDetailsもpurchaseStream経由で届く。
  Future<void> restorePurchases() async {
    if (!_isSupportedPlatform) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[PurchaseService] restorePurchases error: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          debugPrint('[PurchaseService] purchase error: ${purchase.error}');
          break;
        case PurchaseStatus.canceled:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == kSimulationYearlyProductId) {
            _ref.read(premiumStatusProvider.notifier).setPremium(true);
          }
          break;
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
