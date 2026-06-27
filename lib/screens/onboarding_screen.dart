import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/life_settings.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _incomeController = TextEditingController();
  final _fixedCostController = TextEditingController();
  final _savingsController = TextEditingController();

  double get _freeAmount {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final fixed = double.tryParse(_fixedCostController.text) ?? 0;
    final savings = double.tryParse(_savingsController.text) ?? 0;
    return income - fixed - savings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildWelcomePage(),
            _buildConceptPage(),
            _buildSettingsPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text('人生の夢を\nお金で管理する',
              style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 16),
          Text(
            '家計簿ではありません。\nあなたのやりたいことを\nプロジェクト化して実現を目指すアプリです。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDark.withOpacity(0.6),
                  height: 1.8,
                ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
            child: const Text('はじめる'),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text('個人版\nクラウドファンディング',
              style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 16),
          ...[
            '🏝  モルディブに行けるのか',
            '🐶  犬を飼えるのか',
            '📷  カメラを買えるのか',
            '🔥  FIREできるのか',
          ].map((text) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          height: 1.6,
                        )),
              )),
          const SizedBox(height: 16),
          Text('これが本当に知りたいことのはず。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  )),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
            child: const Text('次へ'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('初期設定', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('あとで変更できます',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textDark.withOpacity(0.5),
                  )),
          const SizedBox(height: 32),
          _buildInputField('年間手取り（万円）', _incomeController, '例：800'),
          const SizedBox(height: 16),
          _buildInputField('年間固定費（万円）', _fixedCostController, '例：300'),
          const SizedBox(height: 16),
          _buildInputField('年間貯蓄目標（万円）', _savingsController, '例：200'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('年間自由資金',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _incomeController,
                    _fixedCostController,
                    _savingsController,
                  ]),
                  builder: (context, _) => Text(
                    '${_freeAmount.toStringAsFixed(0)}万円',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primary,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('設定完了'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInputField(
      String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixText: '万円',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final fixed = double.tryParse(_fixedCostController.text) ?? 0;
    final savings = double.tryParse(_savingsController.text) ?? 0;

    if (income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('年間手取りを入力してください')));
      return;
    }

    await ref.read(settingsProvider.notifier).save(LifeSettings(
          annualIncome: income,
          fixedCost: fixed,
          savingsGoal: savings,
        ));

    if (mounted) context.go('/home');
  }
}
