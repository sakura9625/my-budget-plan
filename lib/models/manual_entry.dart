import 'package:hive/hive.dart';

part 'manual_entry.g.dart';

@HiveType(typeId: 4)
class ManualEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String goalId;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? memo;

  ManualEntry({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.memo,
  });
}
