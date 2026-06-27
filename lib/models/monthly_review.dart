import 'package:hive/hive.dart';

part 'monthly_review.g.dart';

@HiveType(typeId: 4)
class MonthlyReview extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int year;

  @HiveField(2)
  int month;

  @HiveField(3)
  double totalAssets;

  @HiveField(4)
  double cashAmount;

  @HiveField(5)
  double? prevTotalAssets;

  @HiveField(6)
  double? prevCashAmount;

  @HiveField(7)
  String? comment;

  @HiveField(8)
  DateTime createdAt;

  MonthlyReview({
    required this.id,
    required this.year,
    required this.month,
    required this.totalAssets,
    required this.cashAmount,
    this.prevTotalAssets,
    this.prevCashAmount,
    this.comment,
    required this.createdAt,
  });

  double? get totalAssetsDiff =>
      prevTotalAssets != null ? totalAssets - prevTotalAssets! : null;

  double? get cashDiff =>
      prevCashAmount != null ? cashAmount - prevCashAmount! : null;
}
