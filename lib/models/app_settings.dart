import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 6)
class AppSettings extends HiveObject {
  @HiveField(0)
  double annualIncome;

  @HiveField(1)
  double annualFixedCost;

  @HiveField(2)
  int reviewDay;

  @HiveField(3)
  bool notificationEnabled;

  @HiveField(4)
  int notificationHour;

  @HiveField(5)
  int notificationMinute;

  @HiveField(6)
  bool initialSetupCompleted;

  @HiveField(7)
  double totalBalance;

  AppSettings({
    required this.annualIncome,
    required this.annualFixedCost,
    this.reviewDay = 28,
    this.notificationEnabled = true,
    this.notificationHour = 9,
    this.notificationMinute = 0,
    this.initialSetupCompleted = false,
    this.totalBalance = 0,
  });

  double get annualFreeMoney => annualIncome - annualFixedCost;
  double get monthlyFreeMoney => annualFreeMoney / 12;
}
