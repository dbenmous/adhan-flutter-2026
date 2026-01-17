import 'package:adhan/adhan.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';
import 'settings_service.dart';

// Top-level function for background execution
@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  debugPrint('=== ALARM CALLBACK FIRED WITH ID: $id ===');
  
  // 1. Initialize Awesome Notifications (required for background)
  await AwesomeNotifications().initialize(
    'resource://mipmap/launcher_icon',
    [
      // Basic Channel
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
      // Dynamic Channels from saved preference will be used via key
      NotificationChannel(
        channelGroupKey: 'adhan_channel_group',
        channelKey: 'channel_adhan_mishary',
        channelName: 'Adhan Mishary', 
        channelDescription: 'Prayer notifications',
        defaultColor: const Color(0xFF5B7FFF),
        importance: NotificationImportance.Max,
        playSound: true,
        soundSource: 'resource://raw/adhan_mishary',
        criticalAlerts: true,
      ),
      // Add other channels as fallback/static definitions if needed
    ],
    debug: false,
  );

  String prayerName = '';
  
  // Suhoor Alarm (ID 999)
  if (id == 999) {
    prayerName = 'Suhoor';
  } else if (id == 9) {
    prayerName = 'Test Alarm';
  } else {
    // 2. Determine prayer name from ID
    // ID Mapping: 100 = Fajr, 101 = Sunrise, 102 = Dhuhr, 103 = Asr, 104 = Maghrib, 105 = Isha
    // With offset: (id % 10) gives the prayer index, id ~/ 10 gives the day offset
    final prayerIndex = id % 10;
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
      default:
        prayerName = 'Prayer';
    }
  }

  // 3. Get channel key from shared preferences
  final prefs = await SharedPreferences.getInstance();
  final adhanSound = prefs.getString('adhan_sound') ?? 'adhan_mishary';
  
  // Suhoor uses a generic alarm channel or the default one
  final channelKey = id == 999 ? 'channel_adhan_mishary' : 'channel_$adhanSound';

  debugPrint('Triggering notification for $prayerName using channel $channelKey');
  
  String body = 'It is time for $prayerName';
  if (id == 999) {
    body = 'Wake up for Suhoor 🌙';
  }

  // 4. Trigger the notification immediately
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: id,
      channelKey: channelKey,
      title: '$prayerName Time',
      body: body,
      category: NotificationCategory.Alarm,
      wakeUpScreen: true,
      fullScreenIntent: true,
      autoDismissible: false,
      criticalAlert: true,
      backgroundColor: const Color(0xFF5B7FFF),
    ),
    actionButtons: [
      NotificationActionButton(
        key: 'DISMISS',
        label: 'Dismiss',
        actionType: ActionType.DismissAction,
      ),
    ],
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
        // Beep Channel (System Default Sound)
        NotificationChannel(
          channelGroupKey: 'adhan_channel_group',
          channelKey: 'channel_beep',
          channelName: 'Beep (Default)',
          channelDescription: 'Prayer notifications with system default sound',
          defaultColor: const Color(0xFF5B7FFF),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          playSound: true,
          soundSource: null, // Uses system default notification sound
          criticalAlerts: true,
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
      debug: false,
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
    // Check if permissions are already granted to avoid opening settings every time
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (isAllowed) {
      debugPrint('[NotificationService] Permissions already granted, skipping request.');
      return;
    }
    
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
    // Cancel all AndroidAlarmManager alarms in parallel for speed
    final futures = <Future>[];
    for (int i = 0; i < 300; i++) {
        futures.add(AndroidAlarmManager.cancel(i));
    }
    futures.add(AndroidAlarmManager.cancel(999)); // Suhoor
    
    await Future.wait(futures);
    
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

        // Schedule using AndroidAlarmManager with alarmClock (Doze bypass)
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

  /// Schedule Suhoor Alarm 45 minutes before Fajr
  Future<void> scheduleSuhoorAlarm(DateTime fajrTime) async {
    // 45 minutes before Fajr
    final suhoorTime = fajrTime.subtract(const Duration(minutes: 45));
    const suhoorId = 999;
    
    debugPrint('=== SCHEDULING SUHOOR ALARM FOR $suhoorTime ===');

    if (suhoorTime.isBefore(DateTime.now())) {
      debugPrint('  -> SKIPPED (past)');
      return;
    }

    final success = await AndroidAlarmManager.oneShotAt(
      suhoorTime,
      suhoorId,
      alarmCallback,
      alarmClock: true,
      wakeup: true,
      exact: true,
      rescheduleOnReboot: true,
    );

    if (success) {
      debugPrint('  -> SUHOOR SCHEDULED (ID: $suhoorId)');
    } else {
      debugPrint('  -> SUHOOR FAILED to schedule');
    }
  }

  /// Cancel Suhoor Alarm
  Future<void> cancelSuhoorAlarm() async {
    const suhoorId = 999;
    await AndroidAlarmManager.cancel(suhoorId);
    debugPrint('=== CANCELLED SUHOOR ALARM (ID: $suhoorId) ===');
  }

  /// Schedule a test alarm for debugging
  Future<void> scheduleTestAlarm({required int seconds}) async {
    debugPrint('=== SCHEDULING TEST ALARM IN $seconds SECONDS ===');

    final scheduledTime = DateTime.now().add(Duration(seconds: seconds));
    const testId = 9; // Special ID for test alarm

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
