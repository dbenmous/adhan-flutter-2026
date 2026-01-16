import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'kaaba_indicator.dart';

class QiblaCompass extends StatelessWidget {
  final double heading;
  final double qiblaDirection;
  final bool isAligned;

  const QiblaCompass({
    super.key,
    required this.heading,
    required this.qiblaDirection,
    required this.isAligned,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: -heading / 360, // Rotate the whole dial to match magnetic North
      duration: const Duration(milliseconds: 200), // Smooth out sensor jitter
      curve: Curves.easeOut,
      child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Compass Dial (Background)
            Image.asset(
              'assets/images/compass_bg.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildDefaultDial(context),
            ),

            // 2. Kaaba Indicator (Rotated to relative bearing)
            // The dial "N" is at 0 (Top).
            // We rotate an invisible container by 'qiblaDirection' 
            // and place the Kaaba at the top of that container.
            RotationTransition(
              turns: AlwaysStoppedAnimation(qiblaDirection / 360),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20), // Inset from edge
                  child: Transform.rotate(
                    angle: - (qiblaDirection * (math.pi / 180)), // Counter-rotate icon to keep it upright? 
                    // No, usually markers rotate with the dial. Let's keep it fixed to the ring.
                    // Actually, Kaaba icon usually stands upright relative to the screen?
                    // If I don't counter-rotate, the Kaaba icon will be upside down when facing South.
                    // Let's counter-rotate it so it's always "Up" relative to the view?
                    // But standard compass apps: markers rotate WITH the dial.
                    // I'll leave it rotating with the dial for realism.
                    child: KaabaIndicator(isAligned: isAligned),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultDial(BuildContext context) {
    // Custom painted dial if asset is missing
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2C2C2C),
        border: Border.all(color: isAligned ? Colors.amber : Colors.white24, width: 4),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.3),
             blurRadius: 20,
             spreadRadius: 5,
           )
        ],
      ),
      child: Stack(
        children: [
          // Cardinal Points
          _buildCardinalPoint('N', Alignment.topCenter, Colors.red),
          _buildCardinalPoint('S', Alignment.bottomCenter, Colors.white),
          _buildCardinalPoint('E', Alignment.centerRight, Colors.white),
          _buildCardinalPoint('W', Alignment.centerLeft, Colors.white),
          
          // Ticks (Simplified)
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardinalPoint(String text, Alignment alignment, Color color) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}
