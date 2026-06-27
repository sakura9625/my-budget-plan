import 'package:hive/hive.dart';

part 'funding_entry.g.dart';

@HiveType(typeId: 3)
class FundingEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? memo;

  FundingEntry({
    required this.id,
    required this.projectId,
    required this.amount,
    required this.date,
    this.memo,
  });
}
