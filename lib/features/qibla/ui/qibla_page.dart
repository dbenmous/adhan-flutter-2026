import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Qibla Direction', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder(
        future: FlutterQiblah.androidDeviceSensorSupport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error checking device support: ${snapshot.error}'));
          }
          if (snapshot.data == true) {
            return const QiblaCompass();
          } else {
            return const Center(child: Text('Your device does not support Qibla sensors'));
          }
        },
      ),
    );
  }
}

class QiblaCompass extends StatelessWidget {
  const QiblaCompass({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }
        
        final qiblaDirection = snapshot.data;
        if (qiblaDirection == null) {
           return const Center(child: Text('Waiting for location...'));
        }

        // qiblaDirection.qibla is the angle to Mecca (0-360)
        // qiblaDirection.direction is the device's heading (0-360)
        
        // We want the needle to point to Qibla relative to device heading.
        // Rotation = (Qibla Angle - Device Heading)
        final double direction = qiblaDirection.direction;
        final double qiblah = qiblaDirection.qiblah;
        final double rotation = (qiblah - direction) * (math.pi / 180);

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text(
                "${qiblah.toStringAsFixed(1)}°", 
                style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text("Qibla Angle", style: GoogleFonts.outfit(color: Colors.grey)),
              const SizedBox(height: 50),
              Stack(
                alignment: Alignment.center,
                children: [
                   // Decorative Compass Dial (Static)
                   Container(
                     width: 300,
                     height: 300,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.grey.shade300, width: 2),
                       color: Colors.white,
                       boxShadow: [
                         BoxShadow(color: Colors.black12, blurRadius: 20),
                       ],
                     ),
                   ),
                   // Needle (Rotates)
                   Transform.rotate(
                     angle: rotation,
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Icon(Icons.navigation, size: 50, color: Colors.green), // Points to Qibla
                         const SizedBox(height: 60), // Offset from center
                       ],
                     ),
                   ),
                   // Center Dot
                   Container(
                     width: 10,
                     height: 10,
                     decoration: const BoxDecoration(
                       color: Colors.black,
                       shape: BoxShape.circle,
                     ),
                   )
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
