import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/project.dart';
import '../theme.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/project/${project.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(project.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  )),
                      Text(
                          '目標 ${project.targetAmount.toStringAsFixed(0)}万円',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  '${(project.achievementRate * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _rateColor(project.achievementRate),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: project.achievementRate,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(
                    _rateColor(project.achievementRate)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${project.currentAmount.toStringAsFixed(0)}万円 / ${project.targetAmount.toStringAsFixed(0)}万円',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _rateColor(double rate) {
    if (rate >= 1.0) return AppTheme.success;
    if (rate >= 0.7) return AppTheme.primary;
    if (rate >= 0.4) return AppTheme.accent;
    return Colors.grey.shade400;
  }
}
