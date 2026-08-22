import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/user_progress.dart';

/// Local (cihaz içi) günlük hatırlatma. Sunucu / FCM değil.
class NotificationService {
  static const _notificationId = 12;
  static const _channelId = 'speak12_daily';
  static const _channelName = 'Günlük hatırlatma';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> syncFromProgress(UserProgress progress) async {
    await initialize();
    if (!progress.reminderEnabled) {
      await cancelDaily();
      return;
    }
    final granted = await requestPermission();
    if (!granted) return;
    await scheduleDaily(
      hour: progress.reminderHour,
      minute: progress.reminderMinute,
      streak: progress.currentStreak,
    );
  }

  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required int streak,
  }) async {
    await initialize();
    await cancelDaily();

    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Speak12 günlük pratik hatırlatması',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: android);

    try {
      await _plugin.zonedSchedule(
        id: _notificationId,
        title: 'Speak12',
        body: streak > 0
            ? 'Pratik zamanı! $streak günlük serin tehlikede olabilir.'
            : 'Bugün birkaç cümle pratik yapalım.',
        scheduledDate: _nextInstance(hour, minute),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Permission denied or OEM restriction — app must not crash.
    }
  }

  Future<void> showTest({required int streak}) async {
    await initialize();
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Speak12 günlük pratik hatırlatması',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    try {
      await _plugin.show(
        id: _notificationId + 1,
        title: 'Speak12',
        body: streak > 0
            ? 'Test: $streak günlük serin tehlikede olabilir.'
            : 'Test: Bugün birkaç cümle pratik yapalım.',
        notificationDetails: const NotificationDetails(android: android),
      );
    } catch (_) {
      // Permission denied — app must not crash.
    }
  }

  Future<void> cancelDaily() async {
    await initialize();
    await _plugin.cancel(id: _notificationId);
  }

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
