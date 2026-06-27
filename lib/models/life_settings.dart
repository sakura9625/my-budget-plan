import 'package:hive/hive.dart';

part 'life_settings.g.dart';

@HiveType(typeId: 0)
class LifeSettings extends HiveObject {
  @HiveField(0)
  double annualIncome;

  @HiveField(1)
  double fixedCost;

  @HiveField(2)
  double savingsGoal;

  LifeSettings({
    required this.annualIncome,
    required this.fixedCost,
    required this.savingsGoal,
  });

  double get freeAmount => annualIncome - fixedCost - savingsGoal;
}
