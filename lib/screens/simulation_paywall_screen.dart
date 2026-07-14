import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/purchase_service.dart';
import '../theme.dart';

// 利用規約・プライバシーポリシーのURL。
const String _kTermsUrl = 'https://sakura9625.github.io/my-budget-plan/terms.html';
const String _kPrivacyPolicyUrl =
    'https://sakura9625.github.io/my-budget-plan/privacy.html';

// 未来シミュレーションの課金案内（ペイウォール）画面。
// 未購入ユーザーがシミュレーションタブを開いたときに、SimulationTab側の
// premiumStatusProvider監視によってこちらが表示される（購入済みになれば
// 自動的に通常画面へ切り替わる。ここから明示的に画面遷移はしない）。
class SimulationPaywallScreen extends ConsumerWidget {
  const SimulationPaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(simulationProductProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('未来シミュレーション')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '新しいプロジェクトや大きな買い物、固定費の変更が、'
              '今後の計画にどう影響するかを事前に確認できます。',
              style: TextStyle(color: Colors.white, fontSize: 15, height: 1.7),
            ),
            const SizedBox(height: 14),
            _bullet('新しいプロジェクトを追加したら？'),
            _bullet('引っ越して固定費が増えたら？'),
            _bullet('予算を見直したら？'),
            _bullet('大きな買い物をしたら？'),
            const SizedBox(height: 14),
            const Text(
              '現在の計画を変更せずに、Before／Afterを比較できます。',
              style: TextStyle(color: Colors.white, fontSize: 15, height: 1.7),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/help/simulation_result_sample.png',
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 28),
            Center(child: _priceDisplay(productAsync)),
            const SizedBox(height: 14),
            const Text(
              '購入後は自動更新されます。解約はApp Storeの設定からいつでも可能です。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legalLink('利用規約', _kTermsUrl),
                const Text('　・　',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                _legalLink('プライバシーポリシー', _kPrivacyPolicyUrl),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startPurchase(context, ref, productAsync),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('未来シミュを有効にする',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _restorePurchases(context, ref),
                child: const Text('購入を復元', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('・', style: TextStyle(color: Colors.white, fontSize: 15)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, height: 1.5)),
          ),
        ],
      ),
    );
  }

  // 価格はApp Storeから取得したローカライズ済み文字列のみを表示する（ハードコードしない）。
  Widget _priceDisplay(AsyncValue<ProductDetails?> productAsync) {
    return productAsync.when(
      data: (product) {
        if (product == null) {
          return const Text('価格情報を取得できませんでした',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13));
        }
        return Text('${product.price} ／ 年',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22));
      },
      loading: () => const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      error: (error, stackTrace) => const Text('価格情報を取得できませんでした',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
    );
  }

  Widget _legalLink(String label, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              decoration: TextDecoration.underline)),
    );
  }

  Future<void> _startPurchase(BuildContext context, WidgetRef ref,
      AsyncValue<ProductDetails?> productAsync) async {
    final product = productAsync.valueOrNull;
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('価格情報を取得できませんでした。時間をおいて再度お試しください。')),
      );
      return;
    }
    await ref.read(purchaseServiceProvider).buy(product);
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('購入履歴を確認しています…')),
    );
    await ref.read(purchaseServiceProvider).restorePurchases();
  }
}
