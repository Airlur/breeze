import 'package:flutter/material.dart';

class ScanLineAnimation extends StatefulWidget {
  const ScanLineAnimation({super.key});

  @override
  State<ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 256).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        );
      },
    );
  }
}
