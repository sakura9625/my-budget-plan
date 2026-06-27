import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

const _emojis = [
  '🏝','🐶','📷','✈️','🏖','🔥','🎸','🏠','🚗','💻','🎓','🌏','⛵','🎯','💎'
];

class AddProjectSheet extends ConsumerStatefulWidget {
  const AddProjectSheet({super.key});

  @override
  ConsumerState<AddProjectSheet> createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends ConsumerState<AddProjectSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedEmoji = '🏝';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('新しいプロジェクト',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Text('絵文字', style: _labelStyle(context)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                final emoji = _emojis[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _selectedEmoji == emoji
                          ? AppTheme.primary.withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: _selectedEmoji == emoji
                          ? Border.all(color: AppTheme.primary, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child:
                        Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text('プロジェクト名', style: _labelStyle(context)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration('例：モルディブ遠征'),
          ),
          const SizedBox(height: 16),
          Text('目標金額（万円）', style: _labelStyle(context)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('例：50'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Text('追加する'),
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) =>
      Theme.of(context)
          .textTheme
          .bodyMedium!
          .copyWith(fontWeight: FontWeight.bold);

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (name.isEmpty || amount <= 0) return;

    await ref.read(projectsProvider.notifier).add(Project(
          id: const Uuid().v4(),
          emoji: _selectedEmoji,
          name: name,
          targetAmount: amount,
          createdAt: DateTime.now(),
        ));

    if (mounted) Navigator.pop(context);
  }
}
