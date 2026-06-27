import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/monthly_review.dart';
import '../providers/monthly_review_provider.dart';
import '../theme.dart';

class MonthlyReviewScreen extends ConsumerStatefulWidget {
  const MonthlyReviewScreen({super.key});

  @override
  ConsumerState<MonthlyReviewScreen> createState() =>
      _MonthlyReviewScreenState();
}

class _MonthlyReviewScreenState extends ConsumerState<MonthlyReviewScreen> {
  final _totalAssetsController = TextEditingController();
  final _cashController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final reviews = ref.watch(monthlyReviewProvider);
    final latest = ref.read(monthlyReviewProvider.notifier).getLatest();

    return Scaffold(
      appBar: AppBar(title: const Text('月次レビュー')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${now.year}年${now.month}月',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                _buildField(
                    '総資産（万円）', _totalAssetsController, '例：7920'),
                const SizedBox(height: 16),
                _buildField('現金（万円）', _cashController, '例：200'),
                const SizedBox(height: 16),
                if (latest != null) ...[
                  _buildDiffPreview(latest),
                  const SizedBox(height: 16),
                ],
                _buildField(
                    'コメント（任意）', _commentController, '例：今月は旅行で出費多め',
                    maxLines: 3),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('保存'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (reviews.isNotEmpty) ...[
            Text('過去のレビュー',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            ...reviews.map((r) => _buildReviewCard(context, r)),
          ],
        ],
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType:
              maxLines == 1 ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiffPreview(MonthlyReview latest) {
    final current =
        double.tryParse(_totalAssetsController.text) ?? 0;
    if (current <= 0) return const SizedBox.shrink();
    final diff = current - latest.totalAssets;
    final isPositive = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isPositive ? AppTheme.success : Colors.redAccent)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('先月比（総資産）',
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(
            '${isPositive ? "+" : ""}${diff.toStringAsFixed(0)}万円',
            style: TextStyle(
              color: isPositive ? AppTheme.success : Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, MonthlyReview review) {
    final diff = review.totalAssetsDiff;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${review.year}年${review.month}月',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (diff != null)
                Text(
                  '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(0)}万円',
                  style: TextStyle(
                    color:
                        diff >= 0 ? AppTheme.success : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          Text('総資産 ${review.totalAssets.toStringAsFixed(0)}万円',
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          if (review.comment != null) ...[
            const SizedBox(height: 6),
            Text(review.comment!,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    final total =
        double.tryParse(_totalAssetsController.text) ?? 0;
    final cash = double.tryParse(_cashController.text) ?? 0;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('総資産を入力してください')));
      return;
    }

    final now = DateTime.now();
    final latest =
        ref.read(monthlyReviewProvider.notifier).getLatest();

    final review = MonthlyReview(
      id: const Uuid().v4(),
      year: now.year,
      month: now.month,
      totalAssets: total,
      cashAmount: cash,
      prevTotalAssets: latest?.totalAssets,
      prevCashAmount: latest?.cashAmount,
      comment: _commentController.text.isEmpty
          ? null
          : _commentController.text,
      createdAt: DateTime.now(),
    );

    await ref.read(monthlyReviewProvider.notifier).save(review);

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('保存しました')));
      Navigator.pop(context);
    }
  }
}
