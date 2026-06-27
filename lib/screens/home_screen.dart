import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import '../widgets/project_card.dart';
import '../widgets/add_project_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final settings = ref.watch(settingsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🏆 My Budget Plan'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '🚧 進行中'),
              Tab(text: '✅ 実現済み'),
              Tab(text: '❄️ 凍結'),
              Tab(text: '💀 断念'),
            ],
            isScrollable: true,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primary,
          ),
        ),
        body: Column(
          children: [
            if (settings != null)
              _buildSummaryCard(context, settings, projects),
            _buildReviewBanner(context),
            Expanded(
              child: TabBarView(
                children: [
                  _buildProjectList(context, projects, ProjectStatus.active),
                  _buildProjectList(context, projects, ProjectStatus.achieved),
                  _buildProjectList(context, projects, ProjectStatus.frozen),
                  _buildProjectList(context, projects, ProjectStatus.abandoned),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddProject(context),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, dynamic settings, List<Project> projects) {
    final activeProjects =
        projects.where((p) => p.status == ProjectStatus.active);
    final totalFunded =
        activeProjects.fold(0.0, (sum, p) => sum + p.currentAmount);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF7B8AF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('年間自由資金',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  )),
          const SizedBox(height: 4),
          Text('${settings.freeAmount.toStringAsFixed(0)}万円',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryItem(context, '進行中プロジェクト',
                  '${activeProjects.length}件'),
              const SizedBox(width: 24),
              _summaryItem(
                  context, '総積立額', '${totalFunded.toStringAsFixed(0)}万円'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildReviewBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/monthly-review'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text('📅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('今月の月次レビューを記録する',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      )),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList(
      BuildContext context, List<Project> projects, ProjectStatus status) {
    final filtered = projects.where((p) => p.status == status).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Text('プロジェクトはありません',
            style: TextStyle(color: Colors.grey.shade400)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) =>
          ProjectCard(project: filtered[index]),
    );
  }

  void _showAddProject(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddProjectSheet(),
    );
  }
}
