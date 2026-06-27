import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/funding_entry.dart';
import '../providers/project_provider.dart';
import '../providers/funding_provider.dart';
import '../theme.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final project = projects.firstWhere((p) => p.id == projectId);
    final entries =
        ref.watch(fundingProvider.notifier).forProject(projectId);

    return Scaffold(
      appBar: AppBar(
        title: Text('${project.emoji} ${project.name}'),
        actions: [
          PopupMenuButton<ProjectStatus>(
            onSelected: (status) async {
              project.status = status;
              if (status == ProjectStatus.achieved) {
                project.completedAt = DateTime.now();
              }
              await ref.read(projectsProvider.notifier).update(project);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: ProjectStatus.active, child: Text('🚧 進行中')),
              PopupMenuItem(
                  value: ProjectStatus.achieved, child: Text('✅ 実現済み')),
              PopupMenuItem(
                  value: ProjectStatus.frozen, child: Text('❄️ 凍結')),
              PopupMenuItem(
                  value: ProjectStatus.abandoned, child: Text('💀 断念')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProgressCard(context, project),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddFunding(context, ref, project),
            icon: const Icon(Icons.add),
            label: const Text('積立を追加'),
          ),
          const SizedBox(height: 24),
          Text('積立履歴',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('まだ積立がありません',
                  style: TextStyle(color: Colors.grey.shade400)),
            )
          else
            ...entries.map((e) => _buildEntryTile(context, ref, e)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, Project project) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('目標',
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text('${project.targetAmount.toStringAsFixed(0)}万円',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('現在',
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text('${project.currentAmount.toStringAsFixed(0)}万円',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: project.achievementRate,
              backgroundColor: Colors.grey.shade100,
              valueColor:
                  const AlwaysStoppedAnimation(AppTheme.primary),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '達成率 ${(project.achievementRate * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(
      BuildContext context, WidgetRef ref, FundingEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.amount.toStringAsFixed(0)}万円',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                if (entry.memo != null)
                  Text(entry.memo!,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                Text(
                  '${entry.date.year}/${entry.date.month}/${entry.date.day}',
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 20),
            onPressed: () => _deleteEntry(ref, entry),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFunding(
      BuildContext context, WidgetRef ref, Project project) async {
    final amountController = TextEditingController();
    final memoController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Container(
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
              Text('積立を追加',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              const Text('金額（万円）',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '例：10',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('メモ（任意）',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: memoController,
                decoration: InputDecoration(
                  hintText: '例：ボーナスから',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(amountController.text) ?? 0;
                  if (amount <= 0) return;

                  final entry = FundingEntry(
                    id: const Uuid().v4(),
                    projectId: project.id,
                    amount: amount,
                    date: DateTime.now(),
                    memo: memoController.text.isEmpty
                        ? null
                        : memoController.text,
                  );

                  await ref.read(fundingProvider.notifier).add(entry);
                  project.currentAmount += amount;
                  await ref
                      .read(projectsProvider.notifier)
                      .update(project);

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('追加する'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEntry(WidgetRef ref, FundingEntry entry) async {
    final project = ref
        .read(projectsProvider)
        .firstWhere((p) => p.id == entry.projectId);
    project.currentAmount =
        (project.currentAmount - entry.amount).clamp(0, double.infinity);
    await ref.read(projectsProvider.notifier).update(project);
    await ref.read(fundingProvider.notifier).delete(entry.id);
  }
}
