// Settings Model for Adhan App

/// Notification sound type for each prayer
enum NotificationType { silent, beep, adhan }

class SettingsModel {
  final String calculationMethodKey;
  final String madhab; // 'shafi', 'hanafi'
  final String highLatitudeRule; // 'middle_of_night', 'seventh_of_night', 'twilight_angle'
  final Map<String, int> manualCorrectionsMinutes; // { 'fajr': 0, ... }
  final int hijriAdjustmentDays;
  final bool isDstEnabled;
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;
  final bool isManualLocation;
  final String? manualLocationName;
  final String? countryCode; // NEW: To re-evaluate auto settings
  final String timezoneId; // 'UTC', 'America/New_York'

  final bool autoCalculationMethod;
  final bool autoMadhab;
  final bool areNotificationsEnabled;
  final String dstMode; // 'auto', 'manual'
  final int dstOffset; // minutes
  
  /// Per-prayer notification sound settings
  final Map<String, NotificationType> prayerNotificationSettings;

  SettingsModel({
    this.calculationMethodKey = 'muslim_world_league',
    this.madhab = 'shafi',
    this.highLatitudeRule = 'middle_of_night',
    this.manualCorrectionsMinutes = const {},
    this.hijriAdjustmentDays = 0,
    this.isDstEnabled = false,
    this.autoCalculationMethod = true,
    this.autoMadhab = true, // NEW
    this.dstMode = 'auto',
    this.dstOffset = 0,
    this.latitude,
    this.longitude,
    this.lastUpdated,
    this.isManualLocation = false,
    this.manualLocationName,
    this.countryCode, 
    this.areNotificationsEnabled = true,
    this.timezoneId = 'UTC',
    this.prayerNotificationSettings = const {
      'Fajr': NotificationType.adhan,
      'Dhuhr': NotificationType.adhan,
      'Asr': NotificationType.adhan,
      'Maghrib': NotificationType.adhan,
      'Isha': NotificationType.adhan,
    },
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      calculationMethodKey: json['calculationMethodKey'] ?? 'muslim_world_league',
      madhab: json['madhab'] ?? 'shafi',
      highLatitudeRule: json['highLatitudeRule'] ?? 'middle_of_night',
      manualCorrectionsMinutes: (json['manualCorrectionsMinutes'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          const {},
      hijriAdjustmentDays: json['hijriAdjustmentDays'] ?? 0,
      isDstEnabled: json['isDstEnabled'] ?? false,
      autoCalculationMethod: json['autoCalculationMethod'] ?? true,
      autoMadhab: json['autoMadhab'] ?? true,
      areNotificationsEnabled: json['areNotificationsEnabled'] ?? true, // NEW
      dstMode: json['dstMode'] ?? 'auto',
      dstOffset: json['dstOffset'] ?? 0,
      latitude: json['latitude'],
      longitude: json['longitude'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'])
          : null,
      isManualLocation: json['isManualLocation'] ?? false,
      manualLocationName: json['manualLocationName'],
      countryCode: json['countryCode'],
      timezoneId: json['timezoneId'] ?? 'UTC',
      prayerNotificationSettings: (json['prayerNotificationSettings'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, NotificationType.values.firstWhere(
              (e) => e.name == v,
              orElse: () => NotificationType.adhan))) ??
          const {
            'Fajr': NotificationType.adhan,
            'Dhuhr': NotificationType.adhan,
            'Asr': NotificationType.adhan,
            'Maghrib': NotificationType.adhan,
            'Isha': NotificationType.adhan,
          },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calculationMethodKey': calculationMethodKey,
      'madhab': madhab,
      'highLatitudeRule': highLatitudeRule,
      'manualCorrectionsMinutes': manualCorrectionsMinutes,
      'hijriAdjustmentDays': hijriAdjustmentDays,
      'isDstEnabled': isDstEnabled,
      'autoCalculationMethod': autoCalculationMethod,
      'autoMadhab': autoMadhab,
      'areNotificationsEnabled': areNotificationsEnabled, // NEW
      'dstMode': dstMode,
      'dstOffset': dstOffset,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
      'isManualLocation': isManualLocation,
      'manualLocationName': manualLocationName,
      'countryCode': countryCode,
      'timezoneId': timezoneId,
      'prayerNotificationSettings': prayerNotificationSettings.map((k, v) => MapEntry(k, v.name)),
    };
  }

  SettingsModel copyWith({
    String? calculationMethodKey,
    String? madhab,
    String? highLatitudeRule,
    Map<String, int>? manualCorrectionsMinutes,
    int? hijriAdjustmentDays,
    bool? isDstEnabled,
    bool? autoCalculationMethod,
    bool? autoMadhab,
    bool? areNotificationsEnabled, // NEW
    String? dstMode,
    int? dstOffset,
    double? latitude,
    double? longitude,
    DateTime? lastUpdated,
    bool? isManualLocation,
    String? manualLocationName,
    String? countryCode,
    String? timezoneId,
    Map<String, NotificationType>? prayerNotificationSettings,
  }) {
    return SettingsModel(
      calculationMethodKey: calculationMethodKey ?? this.calculationMethodKey,
      madhab: madhab ?? this.madhab,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      manualCorrectionsMinutes: manualCorrectionsMinutes ?? this.manualCorrectionsMinutes,
      hijriAdjustmentDays: hijriAdjustmentDays ?? this.hijriAdjustmentDays,
      isDstEnabled: isDstEnabled ?? this.isDstEnabled,
      autoCalculationMethod: autoCalculationMethod ?? this.autoCalculationMethod,
      autoMadhab: autoMadhab ?? this.autoMadhab,
      areNotificationsEnabled: areNotificationsEnabled ?? this.areNotificationsEnabled, // NEW
      dstMode: dstMode ?? this.dstMode,
      dstOffset: dstOffset ?? this.dstOffset,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isManualLocation: isManualLocation ?? this.isManualLocation,
      manualLocationName: manualLocationName ?? this.manualLocationName,
      countryCode: countryCode ?? this.countryCode,
      timezoneId: timezoneId ?? this.timezoneId,
      prayerNotificationSettings: prayerNotificationSettings ?? this.prayerNotificationSettings,
    );
  }
}
