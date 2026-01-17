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
    return SizedBox(
      width: 340,
      height: 340,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Compass Dial (Rotates with heading)
          AnimatedRotation(
            turns: -heading / 360,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 280,
              height: 280,
              child: CustomPaint(
                painter: CompassDialPainter(isAligned: isAligned),
              ),
            ),
          ),

          // 2. Kaaba Indicator OUTSIDE the circle
          // Positioned relative to the widget, NOT rotating with dial
          AnimatedRotation(
            turns: (qiblaDirection - heading) / 360,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 340,
              height: 340,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: KaabaIndicator(isAligned: isAligned),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompassDialPainter extends CustomPainter {
  final bool isAligned;

  CompassDialPainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Outer ring
    final ringPaint = Paint()
      ..color = isAligned ? Colors.amber : Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius - 2, ringPaint);

    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final smallTickPaint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 360; i += 5) {
      final angle = (i - 90) * math.pi / 180;
      final isCardinal = i % 90 == 0;
      final isIntercardinal = i % 45 == 0 && !isCardinal;
      final isMajor = i % 30 == 0;
      
      double tickLength;
      Paint paint;
      
      if (isCardinal || isIntercardinal) {
        // Skip - we'll draw text here
        continue;
      } else if (isMajor) {
        tickLength = 15;
        paint = tickPaint;
      } else {
        tickLength = 8;
        paint = smallTickPaint;
      }
      
      final outerPoint = Offset(
        center.dx + (radius - 10) * math.cos(angle),
        center.dy + (radius - 10) * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 10 - tickLength) * math.cos(angle),
        center.dy + (radius - 10 - tickLength) * math.sin(angle),
      );
      
      canvas.drawLine(outerPoint, innerPoint, paint);
    }

    // Draw cardinal and intercardinal points
    _drawDirectionText(canvas, center, radius, 'N', 0, Colors.red);
    _drawDirectionText(canvas, center, radius, 'NE', 45, Colors.white70);
    _drawDirectionText(canvas, center, radius, 'E', 90, Colors.white);
    _drawDirectionText(canvas, center, radius, 'SE', 135, Colors.white70);
    _drawDirectionText(canvas, center, radius, 'S', 180, Colors.white);
    _drawDirectionText(canvas, center, radius, 'SW', 225, Colors.white70);
    _drawDirectionText(canvas, center, radius, 'W', 270, Colors.white);
    _drawDirectionText(canvas, center, radius, 'NW', 315, Colors.white70);

    // Inner decorative circle
    final innerRingPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius - 50, innerRingPaint);
  }

  void _drawDirectionText(Canvas canvas, Offset center, double radius, 
      String text, double degrees, Color color) {
    final angle = (degrees - 90) * math.pi / 180;
    final textRadius = radius - 30;
    final isIntercardinal = text.length == 2;
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: isIntercardinal ? 12 : 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final textOffset = Offset(
      center.dx + textRadius * math.cos(angle) - textPainter.width / 2,
      center.dy + textRadius * math.sin(angle) - textPainter.height / 2,
    );
    
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(CompassDialPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned;
  }
}
