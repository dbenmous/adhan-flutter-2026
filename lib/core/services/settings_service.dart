import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';
import 'calculation_method_resolver.dart';
import 'madhab_resolver.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() {
    return _instance;
  }

  SettingsService._internal();

  late SharedPreferences _prefs;
  final _settingsController = StreamController<SettingsModel>.broadcast();
  static const String _prefsKey = 'app_settings';

  Stream<SettingsModel> get settingsStream => _settingsController.stream;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SettingsModel getSettings() {
    final jsonString = _prefs.getString(_prefsKey);
    if (jsonString != null) {
      try {
        return SettingsModel.fromJson(jsonDecode(jsonString));
      } catch (e) {
        print("Error decoding settings: $e");
        return SettingsModel(); // Fallback to default
      }
    }
    
    // Migration: Check for legacy keys if new key doesn't exist
    // (This ensures smooth transition from Phase 1)
    if (_prefs.containsKey('calculation_method')) {
        return SettingsModel(
            calculationMethodKey: _prefs.getString('calculation_method') ?? 'muslim_world_league',
            latitude: _prefs.getDouble('latitude'),
            longitude: _prefs.getDouble('longitude'),
            lastUpdated: _prefs.getInt('last_updated') != null 
                ? DateTime.fromMillisecondsSinceEpoch(_prefs.getInt('last_updated')!) 
                : null,
        );
    }

    return SettingsModel();
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await _prefs.setString(_prefsKey, jsonEncode(settings.toJson()));
    _settingsController.add(settings);
  }

  // Convenience methods to partial updates
  Future<void> setCalculationMethod(String methodKey) async {
    final current = getSettings();
    await saveSettings(current.copyWith(calculationMethodKey: methodKey));
  }

  Future<void> setLocation(double lat, double lng, String timezoneId) async {
    final current = getSettings();
    await saveSettings(current.copyWith(
      latitude: lat,
      longitude: lng,
      lastUpdated: DateTime.now(),
      timezoneId: timezoneId,
    ));
  }

  Future<void> setMadhab(String madhab) async {
    final current = getSettings();
    await saveSettings(current.copyWith(madhab: madhab));
  }
  
  Future<void> setMadhabOptions({required String madhab, required bool auto}) async {
    final current = getSettings();
    String newMadhab = madhab;

    if (auto && current.countryCode != null) {
      newMadhab = MadhabResolver.resolveToKey(current.countryCode);
    }
    
    await saveSettings(current.copyWith(
      madhab: newMadhab,
      autoMadhab: auto,
    ));
  }
  
  Future<void> setHighLatitudeRule(String rule) async {
    final current = getSettings();
    await saveSettings(current.copyWith(highLatitudeRule: rule));
  }

  Future<void> setManualCorrections(Map<String, int> corrections) async {
    final current = getSettings();
    await saveSettings(current.copyWith(manualCorrectionsMinutes: corrections));
  }

  Future<void> setDstSettings({required String mode, required int offset}) async {
    final current = getSettings();
    await saveSettings(current.copyWith(dstMode: mode, dstOffset: offset));
  }
  
  Future<void> setNotificationsEnabled(bool enabled) async {
    final current = getSettings();
    await saveSettings(current.copyWith(areNotificationsEnabled: enabled));
  }
  
  Future<void> setCalculationMethodOptions({required String methodKey, required bool auto}) async {
    final current = getSettings();
    String newMethodKey = methodKey;

    if (auto && current.countryCode != null) {
      newMethodKey = CalculationMethodResolver.resolve(current.countryCode);
    }
    
    await saveSettings(current.copyWith(
        calculationMethodKey: newMethodKey,
        autoCalculationMethod: auto
    ));
  }

  Future<void> setManualLocation(double lat, double lng, String name, String timezoneId, String? countryCode) async {
    final current = getSettings();
    
    // If auto-calculation is enabled, update the method based on country code
    String methodKey = current.calculationMethodKey;
    if (current.autoCalculationMethod) {
       methodKey = CalculationMethodResolver.resolve(countryCode);
    }
    
    // If auto-madhab is enabled, update madhab
    String madhab = current.madhab;
    if (current.autoMadhab) {
       madhab = MadhabResolver.resolveToKey(countryCode);
    }
    
    final nextSettings = current.copyWith(
      latitude: lat,
      longitude: lng,
      isManualLocation: true,
      manualLocationName: name,
      lastUpdated: DateTime.now(),
      timezoneId: timezoneId,
      countryCode: countryCode, // Store it
      calculationMethodKey: methodKey,
      madhab: madhab,
    );
    
    await saveSettings(nextSettings);
  }

  Future<void> clearManualLocation() async {
    final current = getSettings();
    await saveSettings(current.copyWith(
      isManualLocation: false,
      manualLocationName: null,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(0), // Force cache invalidation
    ));
  }

  Future<void> onLocationChanged({
    required double latitude,
    required double longitude,
    required String? newCountryCode,
    required String timezoneId,
  }) async {
    final current = getSettings();
    var nextSettings = current.copyWith(
      latitude: latitude,
      longitude: longitude,
      timezoneId: timezoneId,
      lastUpdated: DateTime.now(),
      countryCode: newCountryCode, // Store it
    );

    if (current.autoCalculationMethod) {
      final method = CalculationMethodResolver.resolve(newCountryCode);
      if (method != current.calculationMethodKey) {
        nextSettings = nextSettings.copyWith(calculationMethodKey: method);
      }
    }
    
    if (current.autoMadhab) {
      final madhab = MadhabResolver.resolveToKey(newCountryCode);
      if (madhab != current.madhab) {
        nextSettings = nextSettings.copyWith(madhab: madhab);
      }
    }

    await saveSettings(nextSettings);
  }
}
