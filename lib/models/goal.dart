import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 0)
enum GoalType {
  @HiveField(0)
  saving,
  @HiveField(1)
  project,
}

@HiveType(typeId: 1)
enum GoalStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  frozen,
  @HiveField(3)
  abandoned,
}

@HiveType(typeId: 2)
class Goal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  GoalType type;

  @HiveField(2)
  String name;

  @HiveField(3)
  double targetAmount;

  @HiveField(4)
  int startYear;

  @HiveField(5)
  int startMonth;

  @HiveField(6)
  int endYear;

  @HiveField(7)
  int endMonth;

  @HiveField(8)
  double manualAmount;

  @HiveField(9)
  GoalStatus status;

  @HiveField(10)
  String? emoji;

  @HiveField(11)
  String? memo;

  @HiveField(12)
  DateTime createdAt;

  Goal({
    required this.id,
    required this.type,
    required this.name,
    required this.targetAmount,
    required this.startYear,
    required this.startMonth,
    required this.endYear,
    required this.endMonth,
    this.manualAmount = 0,
    this.status = GoalStatus.active,
    this.emoji,
    this.memo,
    required this.createdAt,
  });

  double get remainingAmount => (targetAmount - manualAmount).clamp(0, double.infinity);
}
