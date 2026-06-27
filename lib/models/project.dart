import 'package:hive/hive.dart';

part 'project.g.dart';

@HiveType(typeId: 1)
enum ProjectStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  achieved,
  @HiveField(2)
  frozen,
  @HiveField(3)
  abandoned,
}

@HiveType(typeId: 2)
class Project extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String emoji;

  @HiveField(2)
  String name;

  @HiveField(3)
  double targetAmount;

  @HiveField(4)
  double currentAmount;

  @HiveField(5)
  ProjectStatus status;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? completedAt;

  Project({
    required this.id,
    required this.emoji,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.status = ProjectStatus.active,
    required this.createdAt,
    this.completedAt,
  });

  double get achievementRate =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
}
