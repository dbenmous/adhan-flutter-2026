import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hijri/hijri_calendar.dart';
import 'notification_service.dart';

class FastingService {
  static final FastingService _instance = FastingService._internal();

  factory FastingService() {
    return _instance;
  }

  FastingService._internal();

  static const String _intentionKey = 'fasting_intention_date';
  static const String _shawwalKey = 'shawwal_fasted_days';

  /// Check if a date is a Sunnah fasting day (Mon, Thu, or White Days 13,14,15)
  /// Now delegates to getFastType logic
  bool isSunnahFast(DateTime date) {
    return getFastType(date) != FastType.none;
  }
  
  /// Returns the type of fast for a given date
  FastType getFastType(DateTime date) {
    final hijriDate = HijriCalendar.fromDate(date);
    
    // Priority 1: Ramadan (Month 9)
    if (hijriDate.hMonth == 9) {
      return FastType.ramadan;
    }
    
    // Priority 2: Arafah (Month 12, Day 9)
    if (hijriDate.hMonth == 12 && hijriDate.hDay == 9) {
      return FastType.arafah;
    }
    
    // Priority 3: Ashura (Month 1, Day 10)
    if (hijriDate.hMonth == 1 && hijriDate.hDay == 10) {
      return FastType.ashura;
    }
    
    // Priority 4: Shawwal (Month 10)
    if (hijriDate.hMonth == 10) {
      return FastType.shawwal;
    }
    
    // Priority 5: White Days (13, 14, 15)
    if (hijriDate.hDay == 13 || hijriDate.hDay == 14 || hijriDate.hDay == 15) {
      return FastType.whiteDays;
    }
    
    // Priority 6: Monday / Thursday
    if (date.weekday == DateTime.monday || date.weekday == DateTime.thursday) {
      return FastType.mondayThursday;
    }
    
    return FastType.none;
  }
  
  String getFastTitle(FastType type) {
    switch (type) {
      case FastType.ramadan: return 'Ramadan';
      case FastType.arafah: return 'Day of Arafah';
      case FastType.ashura: return 'Ashura';
      case FastType.shawwal: return 'Shawwal';
      case FastType.whiteDays: return 'White Days';
      case FastType.mondayThursday: return 'Sunnah Fast';
      case FastType.none: return '';
    }
  }

  /// Returns the next upcoming efficient fasting date (Sunnah or Special)
  DateTime getNextSunnahFast() {
    DateTime date = DateTime.now();
    
    // Check next 30 days (extended for Ramadan/Shawwal)
    for (int i = 0; i < 30; i++) {
        final type = getFastType(date);
        
        // Return if it's a recommended fast
        // For Shawwal, we treat it as valid but we might want to prioritize specific days?
        // For now, getting the next immediate valid fasting day is correct.
        if (type != FastType.none && type != FastType.shawwal) {
             return date;
        }
        
        // Special handling for Shawwal: It's valid effectively every day, but we don't want to 
        // say "Next Fast: Tomorrow" indefinitely if the user isn't actively fasting.
        // So we only return it if it's also a Mon/Thu/WhiteDay OR user specifically wants to tracked?
        // Let's rely on standard logic: If it is Shawwal, we might want to suggest Mon/Thu?
        // Request said: "Priority 4: If Month == 10 -> FastType.shawwal". 
        // So technically every day of Shawwal is returned as FastType.shawwal.
        // We should probably filter this for "Next Fast" to only return Mon/Thu/White in Shawwal context
        // OR return the very next day if we want to encourage the 6 days.
        // Let's stick to Mon/Thu logic inside Shawwal for the "Planner" unless the user is already "in" the streak.
        
        if (type == FastType.shawwal) {
            // Is it also Mon/Thu or White Day?
            if (date.weekday == DateTime.monday || date.weekday == DateTime.thursday || 
               [13, 14, 15].contains(HijriCalendar.fromDate(date).hDay)) {
                return date;
            }
        }
        
        date = date.add(const Duration(days: 1));
    }
    
    return date;
  }

  /// Sets or clears the intention to fast on a specific date
  Future<void> setIntention(bool active, DateTime date, DateTime? fajrTime) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _formatDate(date);
    
    if (active) {
      // Save date as YYYY-MM-DD string
      await prefs.setString(_intentionKey, dateKey);
      
      // Also handle Shawwal tracking if applicable
      if (getFastType(date) == FastType.shawwal) {
         await _addShawwalDay(dateKey);
      }
      
      // Schedule Suhoor Alarm if Fajr time is provided
      if (fajrTime != null) {
        await NotificationService().scheduleSuhoorAlarm(fajrTime);
      }
    } else {
      await prefs.remove(_intentionKey);
      await NotificationService().cancelSuhoorAlarm();
      
      // If unwinding Shawwal? Maybe remove from list?
      // Generally once "fasted" or "intended", we might keep it, but for toggling "Intention"
      // we usually just toggle alarms. The "I fasted today" checkbox usually confirms completion.
      // But let's support removing intention removing the day from the "Intention" slot.
    }
  }

  /// Checks if the user has set an intention for TODAY
  Future<bool> isFastingToday() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_intentionKey);
    if (savedDate == null) return false;
    
    final today = _formatDate(DateTime.now());
    return savedDate == today;
  }
  
  /// Checks if validation is set for a specific future date
  Future<bool> isIntentionSetFor(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_intentionKey);
    return savedDate == _formatDate(date);
  }
  
  // Shawwal Persistence
  Future<List<String>> getShawwalFastedDays() async {
     final prefs = await SharedPreferences.getInstance();
     return prefs.getStringList(_shawwalKey) ?? [];
  }
  
  Future<void> _addShawwalDay(String dateStr) async {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_shawwalKey) ?? [];
      if (!list.contains(dateStr)) {
          list.add(dateStr);
          await prefs.setStringList(_shawwalKey, list);
      }
  }

  Future<void> toggleShawwalDay(String dateStr) async {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_shawwalKey) ?? [];
      if (list.contains(dateStr)) {
          list.remove(dateStr);
      } else {
          list.add(dateStr);
      }
      await prefs.setStringList(_shawwalKey, list);
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // MARK: - Helpers for UI
  
  String getHijriDateString(DateTime date, {int adjustment = 0}) {
    // Apply adjustment
    final adjustedDate = date.add(Duration(days: adjustment));
    final hijri = HijriCalendar.fromDate(adjustedDate);
    return "${hijri.hDay} ${hijri.longMonthName}";
  }

  Duration getFastDuration(DateTime fajr, DateTime maghrib) {
    return maghrib.difference(fajr);
  }
}

enum FastType {
  ramadan,
  arafah,
  ashura,
  whiteDays,
  mondayThursday,
  shawwal,
  none
  }
