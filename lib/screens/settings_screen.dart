import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/life_settings.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _incomeController;
  late TextEditingController _fixedCostController;
  late TextEditingController _savingsController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _incomeController = TextEditingController(
        text: settings?.annualIncome.toStringAsFixed(0) ?? '');
    _fixedCostController = TextEditingController(
        text: settings?.fixedCost.toStringAsFixed(0) ?? '');
    _savingsController = TextEditingController(
        text: settings?.savingsGoal.toStringAsFixed(0) ?? '');
  }

  double get _freeAmount {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final fixed = double.tryParse(_fixedCostController.text) ?? 0;
    final savings = double.tryParse(_savingsController.text) ?? 0;
    return income - fixed - savings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
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
                Text('収入・支出設定',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 16)),
                const SizedBox(height: 20),
                _buildField(context, '年間手取り（万円）', _incomeController),
                const SizedBox(height: 16),
                _buildField(context, '年間固定費（万円）', _fixedCostController),
                const SizedBox(height: 16),
                _buildField(
                    context, '年間貯蓄目標（万円）', _savingsController),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('年間自由資金',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _incomeController,
                          _fixedCostController,
                          _savingsController,
                        ]),
                        builder: (context, _) => Text(
                          '${_freeAmount.toStringAsFixed(0)}万円',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('保存'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, String label,
      TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
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

  Future<void> _save() async {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final fixed = double.tryParse(_fixedCostController.text) ?? 0;
    final savings = double.tryParse(_savingsController.text) ?? 0;

    await ref.read(settingsProvider.notifier).save(LifeSettings(
          annualIncome: income,
          fixedCost: fixed,
          savingsGoal: savings,
        ));

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('保存しました')));
      Navigator.pop(context);
    }
  }
}
