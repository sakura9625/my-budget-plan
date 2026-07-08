import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(iOS: ios),
    );
  }

  static Future<void> scheduleMonthlyReviewReminder(int reviewDay) async {
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    int year = now.year;
    int month = now.month;

    var scheduled = tz.TZDateTime(tz.local, year, month, reviewDay, 9);

    if (scheduled.isBefore(now)) {
      month++;
      if (month > 12) { month = 1; year++; }
      scheduled = tz.TZDateTime(tz.local, year, month, reviewDay, 9);
    }

    await _plugin.zonedSchedule(
      0,
      '📅 今月のレビュー日です',
      '残高を入力して、今月あといくら使えるか確認しましょう。',
      scheduled,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  static Future<void> cancel() async {
    await _plugin.cancelAll();
  }
}
