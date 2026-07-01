import 'package:hive/hive.dart';

part 'review.g.dart';

@HiveType(typeId: 7)
class Review extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int year;

  @HiveField(2)
  int month;

  @HiveField(3)
  DateTime reviewDate;

  @HiveField(4)
  double accountBalance;

  @HiveField(5)
  double effectiveBalance;

  @HiveField(6)
  double overallProgress;

  @HiveField(7)
  double planProgress;

  @HiveField(8)
  String overallStatus;

  @HiveField(9)
  String? comment;

  @HiveField(10)
  String? homeHeadline;

  Review({
    required this.id,
    required this.year,
    required this.month,
    required this.reviewDate,
    required this.accountBalance,
    required this.effectiveBalance,
    required this.overallProgress,
    required this.planProgress,
    required this.overallStatus,
    this.comment,
    this.homeHeadline,
  });
}
