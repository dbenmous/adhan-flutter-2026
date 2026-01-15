import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

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

  Future<void> setLocation(double lat, double lng) async {
    final current = getSettings();
    await saveSettings(current.copyWith(
      latitude: lat,
      longitude: lng,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> setMadhab(String madhab) async {
    final current = getSettings();
    await saveSettings(current.copyWith(madhab: madhab));
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
  
  Future<void> setCalculationMethodOptions({required String methodKey, required bool auto}) async {
    final current = getSettings();
    await saveSettings(current.copyWith(
        calculationMethodKey: methodKey,
        autoCalculationMethod: auto
    ));
  }

  Future<void> setManualLocation(double lat, double lng, String name) async {
    final current = getSettings();
    await saveSettings(current.copyWith(
      latitude: lat,
      longitude: lng,
      isManualLocation: true,
      manualLocationName: name,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> clearManualLocation() async {
    final current = getSettings();
    await saveSettings(current.copyWith(
      isManualLocation: false,
      manualLocationName: null,
    ));
  }
}
