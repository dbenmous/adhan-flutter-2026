import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:adhan/adhan.dart'; // For Coordinates class if handy, or just use doubles

class QiblaService {
  static final QiblaService _instance = QiblaService._internal();
  factory QiblaService() => _instance;
  QiblaService._internal();

  /// Constants for Kaaba Location (Mecca)
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  /// Returns a stream of compass heading events.
  Stream<CompassEvent>? get compassStream => FlutterCompass.events;

  /// Calculates the Qibla direction (bearing) from the given coordinates.
  /// Returns degree [0-360].
  double calculateQiblaDirection(double latitude, double longitude) {
    // Convert to radians
    final double latRad = latitude * (pi / 180);
    final double lngRad = longitude * (pi / 180);
    final double kaabaLatRad = kaabaLat * (pi / 180);
    final double kaabaLngRad = kaabaLng * (pi / 180);

    // Formula
    final double y = sin(kaabaLngRad - lngRad);
    final double x = cos(latRad) * tan(kaabaLatRad) - 
                     sin(latRad) * cos(kaabaLngRad - lngRad);

    double qibla = atan2(y, x) * (180 / pi);
    return (qibla + 360) % 360; // Normalize to 0-360
  }

  /// Checks if the device heading is aligned with Qibla within tolerance.
  bool isAligned(double currentHeading, double qiblaBearing, {double tolerance = 5.0}) {
    double diff = (currentHeading - qiblaBearing).abs();
    // Handle wrap-around (e.g. 359 vs 1)
    if (diff > 180) diff = 360 - diff;
    return diff <= tolerance;
  }
}
