import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_service.dart';
import '../models/settings_model.dart';

/// Alarm Callback - MUST be a top-level or static function
/// This runs in a separate isolate when the alarm fires
@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  debugPrint('=== ALARM CALLBACK FIRED WITH ID: $id ===');
  
  // 1. Initialize AwesomeNotifications in this isolate (minimal config)
  await AwesomeNotifications().initialize(
    'resource://mipmap/launcher_icon',
    [
      // Adhan Channel
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
      // Beep Channel
      NotificationChannel(
        channelGroupKey: 'adhan_channel_group',
        channelKey: 'channel_beep',
        channelName: 'Beep Sound',
        channelDescription: 'Prayer notifications with system beep',
        defaultColor: const Color(0xFF5B7FFF),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        playSound: true,
        criticalAlerts: true,
      ),
      // Silent Channel
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
      // Dynamic Adhan Channels
      NotificationChannel(
        channelGroupKey: 'adhan_channel_group',
        channelKey: 'channel_adhan_mishary',
        channelName: 'Adhan Mishary',
        channelDescription: 'Prayer notifications with Mishary audio',
        defaultColor: const Color(0xFF5B7FFF),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        playSound: true,
        soundSource: 'resource://raw/adhan_mishary',
        criticalAlerts: true,
      ),
      NotificationChannel(
        channelGroupKey: 'adhan_channel_group',
        channelKey: 'channel_adhan_abdulbasit',
        channelName: 'Adhan Abdulbasit',
        channelDescription: 'Prayer notifications with Abdulbasit audio',
        defaultColor: const Color(0xFF5B7FFF),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        playSound: true,
        soundSource: 'resource://raw/adhan_abdulbasit',
        criticalAlerts: true,
      ),
      NotificationChannel(
        channelGroupKey: 'adhan_channel_group',
        channelKey: 'channel_adhan_ahmed_kourdi',
        channelName: 'Adhan Ahmed Kourdi',
        channelDescription: 'Prayer notifications with Ahmed Kourdi audio',
        defaultColor: const Color(0xFF5B7FFF),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        playSound: true,
        soundSource: 'resource://raw/adhan_ahmed_kourdi',
        criticalAlerts: true,
      ),
      NotificationChannel(
        channelGroupKey: 'adhan_channel_group',
        channelKey: 'channel_adhan_assem_bukhari',
        channelName: 'Adhan Assem Bukhari',
        channelDescription: 'Prayer notifications with Assem Bukhari audio',
        defaultColor: const Color(0xFF5B7FFF),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        playSound: true,
        soundSource: 'resource://raw/adhan_assem_bukhari',
        criticalAlerts: true,
      ),
      NotificationChannel(
        channelGroupKey: 'adhan_channel_group',
        channelKey: 'channel_adhan_algeria',
        channelName: 'Adhan Algeria',
        channelDescription: 'Prayer notifications with Algeria audio',
        defaultColor: const Color(0xFF5B7FFF),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        playSound: true,
        soundSource: 'resource://raw/adhan_algeria',
        criticalAlerts: true,
      ),
    ],
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: 'adhan_channel_group',
        channelGroupName: 'Prayers',
      )
    ],
    debug: false,
  );

  // 2. Determine prayer name from ID
  // ID Mapping: 100 = Fajr, 101 = Sunrise, 102 = Dhuhr, 103 = Asr, 104 = Maghrib, 105 = Isha
  // With offset: (id % 10) gives the prayer index, id ~/ 10 gives the day offset
  final prayerIndex = id % 10;
  String prayerName;
  switch (prayerIndex) {
    case 0:
      prayerName = 'Fajr';
      break;
    case 1:
      prayerName = 'Sunrise';
      break;
    case 2:
      prayerName = 'Dhuhr';
      break;
    case 3:
      prayerName = 'Asr';
      break;
    case 4:
      prayerName = 'Maghrib';
      break;
    case 5:
      prayerName = 'Isha';
      break;
    case 9:
      prayerName = 'Test Alarm';
      break;
    default:
      prayerName = 'Prayer';
  }

  // 3. Get channel key from shared preferences (since we can't access SettingsService directly)
  final prefs = await SharedPreferences.getInstance();
  final adhanSound = prefs.getString('adhan_sound') ?? 'adhan_mishary';
  final channelKey = 'channel_$adhanSound';

  debugPrint('Triggering notification for $prayerName using channel $channelKey');

  // 4. Trigger the notification immediately
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: id,
      channelKey: channelKey,
      title: '$prayerName Prayer',
      body: 'It is time for $prayerName',
      category: NotificationCategory.Alarm,
      wakeUpScreen: true,
      fullScreenIntent: true,
      autoDismissible: false,
      criticalAlert: true,
      backgroundColor: const Color(0xFF5B7FFF),
    ),
  );

  debugPrint('=== NOTIFICATION TRIGGERED FOR $prayerName ===');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      'resource://mipmap/launcher_icon',
      [
        // Adhan Channel
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
        // Beep Channel
        NotificationChannel(
          channelGroupKey: 'adhan_channel_group',
          channelKey: 'channel_beep',
          channelName: 'Beep Sound',
          channelDescription: 'Prayer notifications with system beep',
          defaultColor: const Color(0xFF5B7FFF),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          playSound: true,
          criticalAlerts: true,
        ),
        // Silent Channel
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
        // Dynamic Adhan Channels
        _createAdhanChannel('mishary', 'Adhan Mishary'),
        _createAdhanChannel('abdulbasit', 'Adhan Abdulbasit'),
        _createAdhanChannel('ahmed_kourdi', 'Adhan Ahmed Kourdi'),
        _createAdhanChannel('assem_bukhari', 'Adhan Assem Bukhari'),
        _createAdhanChannel('algeria', 'Adhan Algeria'),
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

  NotificationChannel _createAdhanChannel(String idSuffix, String name) {
    return NotificationChannel(
      channelGroupKey: 'adhan_channel_group',
      channelKey: 'channel_adhan_$idSuffix',
      channelName: name,
      channelDescription: 'Prayer notifications with $name audio',
      defaultColor: const Color(0xFF5B7FFF),
      ledColor: Colors.white,
      importance: NotificationImportance.Max,
      playSound: true,
      soundSource: 'resource://raw/adhan_$idSuffix',
      criticalAlerts: true,
    );
  }

  Future<void> requestPermissions() async {
    await AwesomeNotifications().requestPermissionToSendNotifications(
      channelKey: 'channel_adhan',
      permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light,
        NotificationPermission.PreciseAlarms,
        NotificationPermission.FullScreenIntent,
      ],
    );
  }

  Future<void> cancelAllPrayerNotifications() async {
    // Cancel all AndroidAlarmManager alarms
    for (int i = 0; i < 300; i++) {
      await AndroidAlarmManager.cancel(i);
    }
    // Also cancel any existing AwesomeNotifications
    await AwesomeNotifications().cancelAll();
  }

  /// Schedule prayer times using AndroidAlarmManager with alarmClock for Doze bypass
  Future<void> schedulePrayerTimes(PrayerTimes times, {int idOffset = 0}) async {
    debugPrint('=== SCHEDULING PRAYER ALARMS (${times.dateComponents.year}-${times.dateComponents.month}-${times.dateComponents.day}) ===');

    final settings = SettingsService().getSettings();
    if (!settings.areNotificationsEnabled) {
      debugPrint('Notifications are DISABLED in settings. Skipping.');
      return;
    }

    final now = DateTime.now();
    
    // ID Mapping: base + prayer index
    // Fajr=0, Sunrise=1, Dhuhr=2, Asr=3, Maghrib=4, Isha=5
    final prayers = [
      {'id': idOffset * 10 + 0, 'name': 'Fajr', 'time': times.fajr},
      // Sunrise is typically not scheduled as a prayer notification
      {'id': idOffset * 10 + 2, 'name': 'Dhuhr', 'time': times.dhuhr},
      {'id': idOffset * 10 + 3, 'name': 'Asr', 'time': times.asr},
      {'id': idOffset * 10 + 4, 'name': 'Maghrib', 'time': times.maghrib},
      {'id': idOffset * 10 + 5, 'name': 'Isha', 'time': times.isha},
    ];

    for (var prayer in prayers) {
      final time = prayer['time'] as DateTime;
      final prayerName = prayer['name'] as String;
      final id = prayer['id'] as int;
      
      debugPrint('Prayer: $prayerName at $time (isAfter now: ${time.isAfter(now)})');

      if (time.isAfter(now)) {
        // Check if this prayer is enabled (not silent/off)
        final notifType = settings.prayerNotificationSettings[prayerName] ?? NotificationType.adhan;
        if (notifType == NotificationType.silent) {
          debugPrint('  -> SKIPPED (silent/off)');
          continue;
        }

        // Schedule using AndroidAlarmManager with alarmClock (Nuclear Option)
        final success = await AndroidAlarmManager.oneShotAt(
          time,
          id,
          alarmCallback,
          alarmClock: true,     // Uses setAlarmClock - bypasses all restrictions
          wakeup: true,          // Wake device from sleep
          exact: true,           // Fire at exact time
          rescheduleOnReboot: true, // Reschedule after device reboot
        );

        if (success) {
          debugPrint('  -> SCHEDULED: $prayerName (ID: $id) for $time using AlarmClock API');
        } else {
          debugPrint('  -> FAILED to schedule $prayerName');
        }
      } else {
        debugPrint('  -> SKIPPED (past)');
      }
    }
    debugPrint('=== SCHEDULING COMPLETE ===');
  }

  /// Schedule a test alarm for debugging
  Future<void> scheduleTestAlarm({required int seconds}) async {
    debugPrint('=== SCHEDULING TEST ALARM IN $seconds SECONDS ===');

    final scheduledTime = DateTime.now().add(Duration(seconds: seconds));
    const testId = 999; // Special ID for test alarm (ends in 9)

    final success = await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      testId,
      alarmCallback,
      alarmClock: true,
      wakeup: true,
      exact: true,
      rescheduleOnReboot: false, // Don't reschedule test alarms after reboot
    );

    if (success) {
      debugPrint('=== TEST ALARM SCHEDULED FOR $scheduledTime (ID: $testId) ===');
    } else {
      debugPrint('=== FAILED TO SCHEDULE TEST ALARM ===');
    }
  }
}
