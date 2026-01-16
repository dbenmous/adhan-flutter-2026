import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'package:vibration/vibration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:adhan/adhan.dart'; // For Coordinates
import 'dart:async'; // For Timer

import '../../../core/services/location_service.dart';
import '../../qibla/services/qibla_service.dart';
import '../../qibla/widgets/qibla_compass.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  final _locationService = LocationService();
  final _qiblaService = QiblaService();

  double _qiblaDirection = 0.0;
  String _locationName = "Loading...";
  bool _isLoading = true;
  
  // Haptic State
  DateTime _lastHapticTime = DateTime.now();
  bool _wasAligned = false;     // To detect entry into alignment
  double? _lastHeading;         // To track rotation

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final coords = await _locationService.getCurrentLocation();
    final locationName = await _locationService.getLocationName(coords);
    final qibla = _qiblaService.calculateQiblaDirection(coords.latitude, coords.longitude);

    if (mounted) {
      setState(() {
        _qiblaDirection = qibla;
        _locationName = locationName;
        _isLoading = false;
      });
    }
  }

  /// Manages Haptics:
  /// - Rotation: Ticks max every ~350ms (User requested 1/3 sec)
  /// - Alignment: Single distinct vibration, then stop.
  void _updateHaptics(bool isAligned, double currentHeading) async {
    if (await Vibration.hasVibrator() != true) return;

    final now = DateTime.now();

    // 1. Success Event (Entering Qibla Zone)
    if (isAligned) {
      if (!_wasAligned) {
        // "Distinct vibration": Heavy, longer duration (500ms)
        Vibration.vibrate(duration: 500, amplitude: 255);
        _wasAligned = true; // Mark as aligned so it doesn't repeat
      }
      return; // Stop processing rotation ticks while aligned
    }

    // 2. Failure Event (Leaving Qibla Zone)
    if (!isAligned && _wasAligned) {
      _wasAligned = false; // Reset state
    }

    // 3. Rotation Feedback (While NOT aligned)
    // Only vibrate if enough time has passed (Throttle: 350ms)
    if (now.difference(_lastHapticTime).inMilliseconds > 350) {
      if (_lastHeading != null) {
        double diff = (currentHeading - _lastHeading!).abs();
        if (diff > 180) diff = 360 - diff; 

        // Sensitivity: If moved significantly (> 2 degrees)
        if (diff > 2) {
          // "Moderate" tick
          Vibration.vibrate(duration: 20, amplitude: 128); 
          
          _lastHapticTime = now;
          _lastHeading = currentHeading;
        }
      } else {
        _lastHeading = currentHeading;
      }
    }
  }

  @override
  void dispose() {
    // No timer to cancel anymore
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CompassEvent>(
      stream: _qiblaService.compassStream,
      builder: (context, snapshot) {
        // ... (Error handling remains same) ...
        
        final heading = snapshot.data?.heading;
        if (heading == null) return _buildErrorPage("Device does not support Compass");

        final isAligned = _qiblaService.isAligned(heading, _qiblaDirection);
        
        // Pass heading to haptic logic
        _updateHaptics(isAligned, heading);

        return Scaffold(
          // ... (Rest of UI) ...
          extendBodyBehindAppBar: true,
          appBar: AppBar(
             backgroundColor: Colors.transparent,
             elevation: 0,
          ),
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isAligned
                    ? [const Color(0xFF1B5E20), const Color(0xFF000000)] // Green-Goldish
                    : [const Color(0xFF5B4B9E), const Color(0xFF2E2E3E)], // Purple Theme
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                   // Header
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 20),
                     child: Column(
                       children: [
                         Text(
                           "Qibla Direction",
                           style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                         ),
                         const SizedBox(height: 5),
                         Text(
                           _locationName,
                           style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                         ),
                         if (!_isLoading)
                           Text(
                             "${_qiblaDirection.toStringAsFixed(1)}°",
                             style: GoogleFonts.outfit(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                           ),
                       ],
                     ),
                   ),

                   // Calibration Warning
                   if (snapshot.data?.accuracy != null && (snapshot.data!.accuracy! < 2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Low Accuracy: Wave phone in 8-figure",
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                   
                   const Spacer(),
                   
                   // Compass Widget
                   QiblaCompass(
                     heading: heading,
                     qiblaDirection: _qiblaDirection,
                     isAligned: isAligned,
                   ),
                   
                   const Spacer(),
                   
                   // Footer / Status
                   AnimatedOpacity(
                     duration: const Duration(milliseconds: 300),
                     opacity: 1.0,
                     child: Container(
                       margin: const EdgeInsets.only(bottom: 50),
                       padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                       decoration: BoxDecoration(
                         color: isAligned ? Colors.green.withOpacity(0.2) : Colors.white10,
                         borderRadius: BorderRadius.circular(30),
                         border: Border.all(color: isAligned ? Colors.greenAccent : Colors.white24),
                       ),
                       child: Text(
                         isAligned 
                           ? "✓ Facing Qibla" 
                           : "Align the Kaaba icon to the top",
                         style: GoogleFonts.outfit(
                           color: isAligned ? Colors.greenAccent : Colors.white,
                           fontSize: 16,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildLoadingPage() {
    return const Scaffold(
      backgroundColor: Color(0xFF5B4B9E),
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

   Widget _buildErrorPage(String error) {
    return Scaffold(
      backgroundColor: const Color(0xFF5B4B9E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
             error, 
             style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
             textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
