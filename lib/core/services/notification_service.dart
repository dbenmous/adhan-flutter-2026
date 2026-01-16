import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'settings_service.dart';
import '../models/settings_model.dart';

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
        // Channel for Adhan sound (Full audio file)
        NotificationChannel(
          channelGroupKey: 'adhan_channel_group',
          channelKey: 'channel_adhan',
          channelName: 'Adhan Sound',
          channelDescription: 'Prayer notifications with Adhan audio',
          defaultColor: const Color(0xFF5B7FFF),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          playSound: true,
          soundSource: 'resource://raw/adhan',
          criticalAlerts: true,
        ),
        // Channel for system beep sound
        NotificationChannel(
          channelGroupKey: 'adhan_channel_group',
          channelKey: 'channel_beep',
          channelName: 'Beep Sound',
          channelDescription: 'Prayer notifications with system beep',
          defaultColor: const Color(0xFF5B7FFF),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          playSound: true,
          // null = system default sound
          criticalAlerts: true,
        ),
        // Channel for silent (visual only)
        NotificationChannel(
          channelGroupKey: 'adhan_channel_group',
          channelKey: 'channel_silent',
          channelName: 'Silent',
          channelDescription: 'Prayer notifications (visual only)',
          defaultColor: const Color(0xFF5B7FFF),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: false,
          criticalAlerts: false,
        ),
      ],
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
    // We request the specific "dangerous" permissions needed for an Alarm Clock app.
    // Note: We do NOT check 'isNotificationAllowed()' first, because a user might 
    // have banners allowed but "Alarms & Reminders" blocked.
    
    await AwesomeNotifications().requestPermissionToSendNotifications(
      channelKey: 'channel_adhan',
      permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light,
        // CRITICAL: Rings exactly at 07:05 (Fixes the delay bug)
        NotificationPermission.PreciseAlarms, 
        // CRITICAL: Wakes up the screen (Fixes the black screen bug)
        NotificationPermission.FullScreenIntent, 
      ],
    );
  }

  Future<void> cancelAllPrayerNotifications() async {
    await AwesomeNotifications().cancelAll();
  }


  Future<void> schedulePrayerTimes(PrayerTimes times, {int idOffset = 0}) async {
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
      final prayerName = prayer['name'] as String;
      debugPrint('Prayer: $prayerName at $time (isAfter now: ${time.isAfter(now)})');
      
      if (time.isAfter(now)) {
        // Get channel based on user's per-prayer setting
        final notifType = settings.prayerNotificationSettings[prayerName] ?? NotificationType.adhan;
        final channelKey = _getChannelKey(notifType);
        
        await _scheduleNotification(
          id: prayer['id'] as int,
          title: '$prayerName Prayer',
          body: 'It is time for $prayerName',
          scheduledTime: time,
          channelKey: channelKey,
        );
        debugPrint('  -> SCHEDULED: $prayerName for $time using $channelKey');
      } else {
        debugPrint('  -> SKIPPED (past)');
      }
    }
    debugPrint('=== SCHEDULING COMPLETE ===');
  }

  /// Maps NotificationType to channel key
  String _getChannelKey(NotificationType type) {
    switch (type) {
      case NotificationType.silent:
        return 'channel_silent';
      case NotificationType.beep:
        return 'channel_beep';
      case NotificationType.adhan:
        return 'channel_adhan';
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelKey,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
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
