import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedSun extends StatefulWidget {
  const AnimatedSun({super.key});

  @override
  State<AnimatedSun> createState() => _AnimatedSunState();
}

class _AnimatedSunState extends State<AnimatedSun> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(
          Icons.wb_sunny_rounded,
          color: Colors.amber,
          size: 80,
        ),
      ),
    );
  }
}

class AnimatedMoon extends StatefulWidget {
  const AnimatedMoon({super.key});

  @override
  State<AnimatedMoon> createState() => _AnimatedMoonState();
}

class _AnimatedMoonState extends State<AnimatedMoon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. The Moon (Marine Blue Gradient)
          Positioned(
            top: 10,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue[900]!.withOpacity(0.5), // Deep Navy Glow
                      blurRadius: 35,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1), // Subtle white rim
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE3F2FD),   // Very Pale Blue (Top Left Highlight)
                        Color(0xFF2196F3),   // Marine Blue (Center)
                        Color(0xFF0D47A1),   // Deep Blue (Bottom Right)
                      ],
                      stops: [0.1, 0.5, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: const Icon(
                    Icons.nightlight_round,
                    color: Colors.white, 
                    size: 70, 
                  ),
                ),
              ),
            ),
          ),

          // 2. Night Cloud Cluster (Grey/BlueGrey) - Even More Transparent
          // Cloud 1 (Bottom Left - Darker)
          Positioned(
            bottom: 25,
            left: 20,
            child: Icon(Icons.cloud, color: Colors.blueGrey[700]!.withOpacity(0.60), size: 45), // Reduced from 0.65
          ),
          // Cloud 2 (Bottom Right - Lighter)
          Positioned(
            bottom: 25,
            right: 20,
            child: Icon(Icons.cloud, color: Colors.blueGrey[400]!.withOpacity(0.50), size: 45), // Reduced from 0.55
          ),
          // Cloud 3 (Bottom Center - Main - Medium)
          Positioned(
            bottom: 15,
            child: Icon(Icons.cloud, color: Colors.grey[400]!.withOpacity(0.70), size: 55), // Reduced from 0.75
          ),
        ],
      ),
    );
  }
}

class AnimatedSunset extends StatefulWidget {
  const AnimatedSunset({super.key});

  @override
  State<AnimatedSunset> createState() => _AnimatedSunsetState();
}

class _AnimatedSunsetState extends State<AnimatedSunset> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(seconds: 40), 
        vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none, // Allow glow/clouds to spill out
        children: [
          // 1. The Sun (Light Yellow, Rotating)
          Positioned(
            top: 10,
            child: RotationTransition(
              turns: _controller,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellowAccent.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.wb_sunny_rounded, 
                  color: Colors.yellow[200], // Light Yellow
                  size: 70, // Slightly smaller to fit better
                ),
              ),
            ),
          ),

          // 2. Organic Cloud Cluster (Overlapping icons)
          // Cloud 1 (Bottom Left)
          Positioned(
            bottom: 25,
            left: 20,
            child: Icon(Icons.cloud, color: Colors.white.withOpacity(0.7), size: 45),
          ),
          // Cloud 2 (Bottom Right)
          Positioned(
            bottom: 25,
            right: 20,
            child: Icon(Icons.cloud, color: Colors.white.withOpacity(0.7), size: 45),
          ),
          // Cloud 3 (Bottom Center - Main)
          Positioned(
            bottom: 15,
            child: Icon(Icons.cloud, color: Colors.white.withOpacity(0.85), size: 55),
          ),
        ],
      ),
    );
  }
}

class AnimatedAdhan extends StatefulWidget {
  const AnimatedAdhan({super.key});

  @override
  State<AnimatedAdhan> createState() => _AnimatedAdhanState();
}

class _AnimatedAdhanState extends State<AnimatedAdhan> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple 1
          _buildRipple(0),
          // Ripple 2 (delayed)
          _buildRipple(0.5),
          
          // Main Icon
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3), // Blue Glow
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: const Icon(
              Icons.mosque,
              color: Colors.blue, // Blue Icon
              size: 50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRipple(double delay) {
    return _Ripple(controller: _controller, delay: delay);
  }
}

class _Ripple extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _Ripple({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = (controller.value + delay) % 1.0;
        final scale = 1.0 + (value * 0.8); // Scale from 1.0 to 1.8
        final opacity = 1.0 - value; // Fade out

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.cyanAccent.withOpacity(opacity * 0.6), // Cyan Ripple
                width: 4 * opacity,
              ),
            ),
          ),
        );
      },
    );
  }
}
