import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'settings_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null,
      [
        NotificationChannel(
          channelGroupKey: 'adhan_channel_group',
          channelKey: 'adhan_channel_v2', // CHANGED to force update
          channelName: 'Adhan Notifications',
          channelDescription: 'Notifications for Prayer Times',
          defaultColor: const Color(0xFF5B7FFF),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          playSound: true,
          soundSource: 'resource://raw/adhan', // android/app/src/main/res/raw/adhan.mp3
          criticalAlerts: true,
        )
      ],
      // Channel groups are only visual and are optional
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'adhan_channel_group',
          channelGroupName: 'Prayers',
        )
      ],
      debug: true,
    );
  }

  Future<void> requestPermissions() async {
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> cancelAllPrayerNotifications() async {
    await AwesomeNotifications().cancelAll();
  }


  Future<void> schedulePrayerTimes(PrayerTimes times, {int idOffset = 0}) async {
    // await cancelAllPrayerNotifications(); // Removed to allow multiple calls
    debugPrint('=== SCHEDULING PRAYER NOTIFICATIONS (${times.dateComponents.year}-${times.dateComponents.month}-${times.dateComponents.day}) ===');

    final settings = SettingsService().getSettings();
    if (!settings.areNotificationsEnabled) {
      debugPrint('Notifications are DISABLED in settings. Skipping.');
      return;
    }


    final now = DateTime.now();
    final prayers = [
      {'id': 101 + idOffset, 'name': 'Fajr', 'time': times.fajr},
      {'id': 102 + idOffset, 'name': 'Dhuhr', 'time': times.dhuhr},
      {'id': 103 + idOffset, 'name': 'Asr', 'time': times.asr},
      {'id': 104 + idOffset, 'name': 'Maghrib', 'time': times.maghrib},
      {'id': 105 + idOffset, 'name': 'Isha', 'time': times.isha},
    ];

    for (var prayer in prayers) {
      final time = prayer['time'] as DateTime;
      debugPrint('Prayer: ${prayer['name']} at $time (isAfter now: ${time.isAfter(now)})');
      if (time.isAfter(now)) {
        await _scheduleNotification(
          id: prayer['id'] as int,
          title: '${prayer['name']} Prayer',
          body: 'It is time for ${prayer['name']}',
          scheduledTime: time,
        );
        debugPrint('  -> SCHEDULED: ${prayer['name']} for $time');
      } else {
        debugPrint('  -> SKIPPED (past)');
      }
    }
    debugPrint('=== SCHEDULING COMPLETE ===');
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'adhan_channel_v2',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        backgroundColor: const Color(0xFF5B7FFF),
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledTime, preciseAlarm: true, allowWhileIdle: true),
    );
  }
}
