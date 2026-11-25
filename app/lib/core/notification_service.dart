import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Lightweight item model passed to [NotificationService.scheduleDailySummaries].
class ReminderItem {
  final String name;
  final DateTime expiryDate;

  const ReminderItem({
    required this.name,
    required this.expiryDate,
  });
}

/// Manages local expiry-reminder notifications for Stockora on Android.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  factory NotificationService() => instance;

  static const int _baseId = 1000;
  static const int _dayCount = 7;
  static const int _testId = 1007;

  static const String _channelId = 'expiry_reminders';
  static const String _channelName = 'Expiry reminders';

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initializes timezone data, local timezone, and the notifications plugin.
  /// Safe to call multiple times; no-op on web.
  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(initSettings);

      _initialized = true;
    } catch (_) {
      // Never throw from notification setup.
    }
  }

  /// Requests Android 13+ notification permission and returns whether granted.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Schedules up to 7 daily 9:00 AM summary notifications (IDs 1000..1006).
  Future<void> scheduleDailySummaries(List<ReminderItem> activeItems) async {
    if (kIsWeb) return;
    try {
      await cancelAll();

      final now = tz.TZDateTime.now(tz.local);
      for (int offset = 0; offset < _dayCount; offset++) {
        final targetDate = DateTime(now.year, now.month, now.day + offset);
        final scheduledTime = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          9,
        );
        if (!scheduledTime.isAfter(now)) continue;

        final windowEnd = targetDate.add(const Duration(days: 3));
        final expiring = <ReminderItem>[];
        int expiredCount = 0;

        for (final item in activeItems) {
          final expiryDay = DateTime(
            item.expiryDate.year,
            item.expiryDate.month,
            item.expiryDate.day,
          );
          if (expiryDay.isBefore(targetDate)) {
            expiredCount++;
          } else if (!expiryDay.isAfter(windowEnd)) {
            expiring.add(item);
          }
        }

        if (expiring.isEmpty && expiredCount == 0) continue;

        final body = _buildSummaryBody(expiring, expiredCount);
        await _plugin.zonedSchedule(
          _baseId + offset,
          'Use these first',
          body,
          scheduledTime,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {
      // Never throw from notification scheduling.
    }
  }

  /// Cancels all scheduled daily summary notifications (IDs 1000..1006).
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      for (int offset = 0; offset < _dayCount; offset++) {
        await _plugin.cancel(_baseId + offset);
      }
    } catch (_) {
      // Never throw on cancel.
    }
  }

  /// Displays an immediate test notification to verify permission and channel.
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    try {
      await _plugin.show(
        _testId,
        'Stockora test',
        'Reminders are working',
        _notificationDetails,
      );
    } catch (_) {
      // Never throw on test notification.
    }
  }

  String _buildSummaryBody(List<ReminderItem> expiring, int expiredCount) {
    final parts = <String>[];

    if (expiring.length == 1) {
      parts.add('${expiring[0].name} expires within 3 days');
    } else if (expiring.length == 2) {
      parts.add('${expiring[0].name}, ${expiring[1].name} expire within 3 days');
    } else if (expiring.length > 2) {
      parts.add(
        '${expiring[0].name}, ${expiring[1].name} and ${expiring.length - 2} more expire within 3 days',
      );
    }

    if (expiredCount == 1) {
      parts.add('1 item has already expired');
    } else if (expiredCount > 1) {
      parts.add('$expiredCount items have already expired');
    }

    return parts.join(' ');
  }
}
