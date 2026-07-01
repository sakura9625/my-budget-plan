import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 3)
class Budget extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double monthlyAmount;

  @HiveField(3)
  int startYear;

  @HiveField(4)
  int startMonth;

  @HiveField(5)
  int endYear;

  @HiveField(6)
  int endMonth;

  @HiveField(7)
  double usedAmount;

  @HiveField(8)
  String? emoji;

  @HiveField(9)
  String? memo;

  @HiveField(10)
  DateTime createdAt;

  Budget({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.startYear,
    required this.startMonth,
    required this.endYear,
    required this.endMonth,
    this.usedAmount = 0,
    this.emoji,
    this.memo,
    required this.createdAt,
  });

  int get targetMonths {
    return (endYear * 12 + endMonth) - (startYear * 12 + startMonth) + 1;
  }

  double get plannedAmount => monthlyAmount * targetMonths;

  double get usageRate => plannedAmount > 0 ? usedAmount / plannedAmount : 0;
}
