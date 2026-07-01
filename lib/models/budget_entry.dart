import 'package:hive/hive.dart';

part 'budget_entry.g.dart';

@HiveType(typeId: 5)
class BudgetEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String budgetId;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? memo;

  BudgetEntry({
    required this.id,
    required this.budgetId,
    required this.amount,
    required this.date,
    this.memo,
  });
}
