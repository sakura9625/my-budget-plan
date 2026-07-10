import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import '../utils/formatter.dart';
import '../services/notification_service.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  late TextEditingController _incomeController;
  late TextEditingController _fixedCostController;
  late TextEditingController _totalBalanceController;
  late int _reviewDay;
  late bool _notificationEnabled;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _incomeController = TextEditingController(
        text: settings?.annualIncome.toStringAsFixed(0) ?? '');
    _fixedCostController = TextEditingController(
        text: settings?.annualFixedCost.toStringAsFixed(0) ?? '');
    _totalBalanceController = TextEditingController(
        text: settings?.totalBalance.toStringAsFixed(0) ?? '');
    _reviewDay = settings?.reviewDay ?? 28;
    _notificationEnabled = settings?.notificationEnabled ?? true;
  }

  double get _annualFreeMoney {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final fixed = double.tryParse(_fixedCostController.text) ?? 0;
    return income - fixed;
  }

  @override
  Widget build(BuildContext context) {
    // 他画面（レビュー）でtotalBalanceが更新された場合も表示を同期する
    ref.listen<AppSettings?>(settingsProvider, (previous, next) {
      if (next == null) return;
      final text = next.totalBalance.toStringAsFixed(0);
      if (_totalBalanceController.text != text) {
        _totalBalanceController.text = text;
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: '収入・固定費',
            children: [
              _buildInputField('年間手取り（万円）', _incomeController),
              const SizedBox(height: 16),
              _buildInputField('年間固定費（万円）', _fixedCostController),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('年間自由資金',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark)),
                    AnimatedBuilder(
                      animation: Listenable.merge(
                          [_incomeController, _fixedCostController]),
                      builder: (context, _) => Text(
                        Formatter.man(_annualFreeMoney),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveIncome,
                child: const Text('保存'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            title: '現在の残高',
            children: [
              const Text(
                'アプリ全体で1つの総残高として扱われます。レビューで残高を入力すると、ここも同じ値に更新されます。',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, height: 1.6),
              ),
              const SizedBox(height: 16),
              _buildInputField('現在の残高（万円）', _totalBalanceController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTotalBalance,
                child: const Text('保存'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            title: 'レビュー日設定',
            children: [
              Text(
                '給与振込・固定費・カード引き落としが概ね終わった日がおすすめです。',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF6B7280), height: 1.6),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_reviewDay > 1) setState(() => _reviewDay--);
                    },
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppTheme.primary),
                  ),
                  Text(
                    '毎月$_reviewDay日',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_reviewDay < 28) setState(() => _reviewDay++);
                    },
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveReviewDay,
                child: const Text('保存'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            title: '通知',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('レビューリマインダー',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark)),
                      Text(
                        '毎月$_reviewDay日に通知します',
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                  Switch(
                    value: _notificationEnabled,
                    onChanged: (val) async {
                      setState(() => _notificationEnabled = val);
                      await _saveNotification(val);
                    },
                    activeColor: AppTheme.primary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            title: 'アプリ情報',
            children: [
              _buildInfoRow('バージョン', '1.0.0'),
              const SizedBox(height: 8),
              _buildInfoRow('データ保存', 'ローカル（端末内）'),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textDark)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textDark)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          decoration: const InputDecoration(suffixText: '万円'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      ],
    );
  }

  Future<void> _saveIncome() async {
    FocusScope.of(context).unfocus();
    final settings = ref.read(settingsProvider);
    if (settings == null) return;
    final income = double.tryParse(_incomeController.text) ?? 0;
    final fixed = double.tryParse(_fixedCostController.text) ?? 0;
    if (income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('年間手取りを入力してください')));
      return;
    }
    settings.annualIncome = income;
    settings.annualFixedCost = fixed;
    await ref.read(settingsProvider.notifier).save(settings);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('保存しました')));
    }
  }

  Future<void> _saveTotalBalance() async {
    FocusScope.of(context).unfocus();
    final settings = ref.read(settingsProvider);
    if (settings == null) return;
    settings.totalBalance = double.tryParse(_totalBalanceController.text) ?? 0;
    await ref.read(settingsProvider.notifier).save(settings);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('保存しました')));
    }
  }

  Future<void> _saveReviewDay() async {
    FocusScope.of(context).unfocus();
    final settings = ref.read(settingsProvider);
    if (settings == null) return;
    settings.reviewDay = _reviewDay;
    await ref.read(settingsProvider.notifier).save(settings);
    if (settings.notificationEnabled) {
      await NotificationService.scheduleMonthlyReviewReminder(_reviewDay);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('保存しました')));
    }
  }

  Future<void> _saveNotification(bool enabled) async {
    final settings = ref.read(settingsProvider);
    if (settings == null) return;
    settings.notificationEnabled = enabled;
    await ref.read(settingsProvider.notifier).save(settings);
  }
}
