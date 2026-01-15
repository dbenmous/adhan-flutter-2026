import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'settings_service.dart';
import 'prayer_time_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  final SettingsService _settingsService = SettingsService();

  Future<void> init() async {
    // nothing to init for now
  }

  /// Gets current location with timeout and fallback to saved settings.
  Future<Coordinates> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _getSavedLocationOrMecca();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _getSavedLocationOrMecca();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _getSavedLocationOrMecca();
      }

      // Check cache validity (1 hour)
      final settings = _settingsService.getSettings();
      if (settings.lastUpdated != null &&
          DateTime.now().difference(settings.lastUpdated!).inHours < 1 &&
          settings.latitude != null) {
         return Coordinates(settings.latitude!, settings.longitude!);
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 30),
        );
        
        // Check if location changed significantly (>50km)
        if (settings.latitude != null) {
           final dist = PrayerTimeService().calculateDistance(
             Coordinates(settings.latitude!, settings.longitude!),
             Coordinates(position.latitude, position.longitude)
           );
           if (dist > 50) {
              // Location changed significantly
              // Logic to update settings is handled by caller or implicit save
           }
        }
        
        // Update cache
        await _settingsService.setLocation(position.latitude, position.longitude);
        return Coordinates(position.latitude, position.longitude);

      } catch (e) {
        print("GPS Timeout or Error: $e");
        return _getSavedLocationOrMecca();
      }

    } catch (e) {
      return _getSavedLocationOrMecca();
    }
  }

  Coordinates _getSavedLocationOrMecca() {
    final settings = _settingsService.getSettings();
    if (settings.latitude != null && settings.longitude != null) {
      return Coordinates(settings.latitude!, settings.longitude!);
    }
    return Coordinates(21.4225, 39.8262); // Mecca
  }
}
