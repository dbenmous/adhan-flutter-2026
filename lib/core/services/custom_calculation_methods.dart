import 'package:adhan/adhan.dart';

class CustomCalculationMethods {
  /// Morocco - Ministry of Habous and Islamic Affairs
  /// Fajr: 19°, Isha: 17°
  static CalculationParameters get morocco {
    return CalculationParameters(
      fajrAngle: 19.0,
      ishaAngle: 17.0,
    );
  }

  /// London Unified Prayer Timetable
  /// Used by London Central Mosque and most UK mosques
  /// Fajr: 18°, Isha: 18° (with seasonal adjustments)
  static CalculationParameters get londonUnified {
    return CalculationParameters(
      fajrAngle: 18.0,
      ishaAngle: 18.0,
    );
  }
}
