import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'settings_service.dart';
import 'package:geocoding/geocoding.dart';
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

  /// Forces a fresh GPS location fetch, ignoring cache and manual settings.
  Future<Coordinates> getGpsLocation() async {
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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );
      
      return Coordinates(position.latitude, position.longitude);
    } catch (e) {
      return _getSavedLocationOrMecca();
    }
  }

  /// Gets current location with timeout and fallback to saved settings.
  Future<Coordinates> getCurrentLocation() async {
    try {
      final settings = _settingsService.getSettings();
      
      // If manual location is set, use it directly
      if (settings.isManualLocation && settings.latitude != null) {
        return Coordinates(settings.latitude!, settings.longitude!);
      }

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

  Future<String> getLocationName(Coordinates coords) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coords.latitude,
        coords.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.locality ?? ''}, ${place.country ?? ''}";
      }
      return "Unknown Location";
    } catch (e) {
      return "Unknown Location";
    }
  }
}
