import 'package:flutter/material.dart';

class KaabaIndicator extends StatefulWidget {
  final bool isAligned;

  const KaabaIndicator({
    super.key, 
    required this.isAligned,
  });

  @override
  State<KaabaIndicator> createState() => _KaabaIndicatorState();
}

class _KaabaIndicatorState extends State<KaabaIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1, milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Initial check
    if (widget.isAligned) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(KaabaIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAligned != oldWidget.isAligned) {
      if (widget.isAligned) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.isAligned
                ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.6),
                      blurRadius: _pulseAnimation.value * 2,
                      spreadRadius: _pulseAnimation.value / 2,
                    ),
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/kaaba_icon.png',
        width: 50,
        height: 50,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if asset is missing
          return const Icon(
            Icons.mosque, 
            color: Colors.amber, 
            size: 40,
            shadows: [
              BoxShadow(color: Colors.amber, blurRadius: 10, spreadRadius: 2),
            ],
          );
        },
      ),
    );
  }
}
