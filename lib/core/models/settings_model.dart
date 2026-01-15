import 'dart:convert';

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

  SettingsModel({
    this.calculationMethodKey = 'muslim_world_league',
    this.madhab = 'shafi',
    this.highLatitudeRule = 'middle_of_night',
    this.manualCorrectionsMinutes = const {},
    this.hijriAdjustmentDays = 0,
    this.isDstEnabled = false,
    this.latitude,
    this.longitude,
    this.lastUpdated,
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
      latitude: json['latitude'],
      longitude: json['longitude'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'])
          : null,
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
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }

  SettingsModel copyWith({
    String? calculationMethodKey,
    String? madhab,
    String? highLatitudeRule,
    Map<String, int>? manualCorrectionsMinutes,
    int? hijriAdjustmentDays,
    bool? isDstEnabled,
    double? latitude,
    double? longitude,
    DateTime? lastUpdated,
  }) {
    return SettingsModel(
      calculationMethodKey: calculationMethodKey ?? this.calculationMethodKey,
      madhab: madhab ?? this.madhab,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      manualCorrectionsMinutes: manualCorrectionsMinutes ?? this.manualCorrectionsMinutes,
      hijriAdjustmentDays: hijriAdjustmentDays ?? this.hijriAdjustmentDays,
      isDstEnabled: isDstEnabled ?? this.isDstEnabled,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
