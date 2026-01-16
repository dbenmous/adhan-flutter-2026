import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart'; // For debugPrint and DateUtils
import '../models/settings_model.dart';
import 'custom_calculation_methods.dart';

class PrayerTimeService {
  static final PrayerTimeService _instance = PrayerTimeService._internal();

  factory PrayerTimeService() {
    return _instance;
  }

  PrayerTimeService._internal();

  /// Calculates prayer times based on settings.
  Future<PrayerTimes> calculatePrayerTimes(
      Coordinates coordinates, SettingsModel settings, {DateTime? date}) async {
    
    final calculationDate = DateComponents.from(date ?? DateTime.now());
    final params = getCalculationParameters(settings);

    // 1. Madhab
    params.madhab = settings.madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;

    // 2. High Latitude Rule
    switch (settings.highLatitudeRule) {
      case 'seventh_of_night':
        params.highLatitudeRule = HighLatitudeRule.seventh_of_the_night;
        break;
      case 'twilight_angle':
        params.highLatitudeRule = HighLatitudeRule.twilight_angle;
        break;
      case 'middle_of_night':
      default:
        params.highLatitudeRule = HighLatitudeRule.middle_of_the_night;
    }

    // 3. Manual Corrections
    if (settings.manualCorrectionsMinutes.isNotEmpty) {
      params.adjustments = PrayerAdjustments(
        fajr: settings.manualCorrectionsMinutes['fajr'] ?? 0,
        sunrise: settings.manualCorrectionsMinutes['sunrise'] ?? 0,
        dhuhr: settings.manualCorrectionsMinutes['dhuhr'] ?? 0,
        asr: settings.manualCorrectionsMinutes['asr'] ?? 0,
        maghrib: settings.manualCorrectionsMinutes['maghrib'] ?? 0,
        isha: settings.manualCorrectionsMinutes['isha'] ?? 0,
      );
    }

    var prayerTimes = PrayerTimes(coordinates, calculationDate, params);

    // 4. DST Adjustment (Post-Calculation)
    // If DST is enabled manually, we shift times by +60 minutes.
    // Note: adhan package usually calculates based on standard time or provided date components.
    // If we want to strictly apply a manual DST offset on top of what system/adhan does:
    if (settings.isDstEnabled) {
       // We can't modify PrayerTimes fields directly freely as they are final or computed.
       // However, typical usage is: stored times are UTC or local. 
       // If the user wants an explicit +1h shift on displayed times:
       // We might need to return a wrapper or handle it in UI/Notification.
       // BUT, cleaner is to adjust the date components or Timezone? No.
       // Let's implement a wrapper or just rely on 'nextPrayer' logic observing this?
       // Actually, adhan returns DateTime in Local system time. 
       // If manual DST is ON, we add 1 hour.
       // Since we return PrayerTimes object, we can't easily mutation it.
       // WORKAROUND: We will assume the caller handles the display offset OR
       // we create a new PrayerTimes object with shifted parameters? No.
       // Proper way: We can't change PrayerTimes object content easily. 
       // But the requirement says "if settings.isDstEnabled == true, add +60 minutes to all prayer times".
       // Since we return `PrayerTimes` object, we are limited.
       // HOWEVER, `PrayerTimes` has specific getters.
       // Recommendation: We'll implement a 'ShiftedPrayerTimes' logic if possible, 
       // OR we accept that we return standard times and the helper 'getNextPrayer' applies the shift.
       // Wait, the params.adjustments might be cleaner? Adjustments are minute-based.
       // YES! We can add 60 minutes to ALL adjustments!
       
       params.adjustments = PrayerAdjustments(
         fajr: (params.adjustments.fajr) + 60,
         sunrise: (params.adjustments.sunrise) + 60,
         dhuhr: (params.adjustments.dhuhr) + 60,
         asr: (params.adjustments.asr) + 60,
         maghrib: (params.adjustments.maghrib) + 60,
         isha: (params.adjustments.isha) + 60,
       );
       
       // Re-calculate with new adjustments
       prayerTimes = PrayerTimes(coordinates, calculationDate, params);
    }

    return prayerTimes;
  }

  CalculationParameters getCalculationParameters(SettingsModel settings) {
    if (settings.calculationMethodKey == 'morocco_custom') {
       return CustomCalculationMethods.morocco;
    }
    
    if (settings.calculationMethodKey == 'london_unified') {
       return CustomCalculationMethods.londonUnified;
    }

    switch (settings.calculationMethodKey.toLowerCase()) {
      case 'karachi':
        return CalculationMethod.karachi.getParameters();
      case 'egyptian':
        return CalculationMethod.egyptian.getParameters();
      case 'umm_al_qura':
        return CalculationMethod.umm_al_qura.getParameters();
      case 'dubai':
        return CalculationMethod.dubai.getParameters();
      case 'moonsighting_committee':
        return CalculationMethod.moon_sighting_committee.getParameters();
      case 'north_america':
        return CalculationMethod.north_america.getParameters();
      case 'kuwait':
        return CalculationMethod.kuwait.getParameters();
      case 'qatar':
        return CalculationMethod.qatar.getParameters();
      case 'singapore':
        return CalculationMethod.singapore.getParameters();
      case 'tehran':
        return CalculationMethod.tehran.getParameters();
      case 'turkey':
        return CalculationMethod.turkey.getParameters();
      case 'morocco':
         // Morocco: Actually aligns closer to MWL (18°) for Fajr in many apps.
         // Ministry also adds +5 min to Maghrib constant.
         final params = CalculationMethod.muslim_world_league.getParameters();
         params.fajrAngle = 18.0;
         params.ishaAngle = 17.0;
         params.adjustments.maghrib = 5; // Crucial for Morocco
         return params;
      case 'muslim_world_league':
      default:
        return CalculationMethod.muslim_world_league.getParameters();
    }
  }

  /// Returns the next prayer with its name and time.
  Future<Map<String, dynamic>> getNextPrayer(PrayerTimes times) async {
    final next = times.nextPrayer();
    final nextTime = times.timeForPrayer(next);
    
    if (next == Prayer.none) {
      return {
        'name': 'Fajr',
        'time': times.fajr.add(const Duration(days: 1)), // Approximation
      };
    }

    return {
      'name': _prayerName(next),
      'time': nextTime,
    };
  }

  String _prayerName(Prayer p) {
    if (p == Prayer.none) return "None";
    return p.name[0].toUpperCase() + p.name.substring(1);
  }

  /// Calculates distance between two coordinates in Kilometers.
  double calculateDistance(Coordinates coord1, Coordinates coord2) {
    return Geolocator.distanceBetween(
      coord1.latitude,
      coord1.longitude,
      coord2.latitude,
      coord2.longitude,
    ) / 1000;
  }

  // Cache to store monthly calculations: "Year|Month|Lat|Lng|Method..." -> List<PrayerTimes>
  final Map<String, List<PrayerTimes>> _monthlyCache = {};

  /// Returns cached or calculated prayer times for the entire month.
  Future<List<PrayerTimes>> getMonthlyPrayerTimes(
      Coordinates coordinates, SettingsModel settings, DateTime monthDate) async {
    
    // Create a unique cache key based on parameters that affect calculation
    final key = "${monthDate.year}|${monthDate.month}|"
        "${coordinates.latitude.toStringAsFixed(4)}|${coordinates.longitude.toStringAsFixed(4)}|"
        "${settings.calculationMethodKey}|${settings.madhab}|${settings.highLatitudeRule}|"
        "${settings.manualCorrectionsMinutes.toString()}|${settings.isDstEnabled}";

    if (_monthlyCache.containsKey(key)) {
      debugPrint("[PrayerTimeService] Cache HIT for $key");
      return _monthlyCache[key]!;
    }

    debugPrint("[PrayerTimeService] Cache MISS. Calculating for $key");
    final daysInMonth = DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
    List<PrayerTimes> monthTimes = [];

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(monthDate.year, monthDate.month, i);
      final times = await calculatePrayerTimes(coordinates, settings, date: date);
      monthTimes.add(times);
    }

    _monthlyCache[key] = monthTimes;
    return monthTimes;
  }

  /// Hijri Date Helper
  HijriCalendar getHijriDate(DateTime date, int adjustmentDays) {
    // ... existing logic ...
    return HijriCalendar.fromDate(date.add(Duration(days: adjustmentDays))); 
  }
}
