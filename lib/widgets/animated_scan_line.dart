import 'package:flutter/material.dart';

class AnimatedScanLine extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final Duration duration;

  const AnimatedScanLine({
    super.key,
    required this.width,
    required this.height,
    this.color = const Color(0xFF2DD4BF), // Default to theme primary
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedScanLine> createState() => _AnimatedScanLineState();
}

class _AnimatedScanLineState extends State<AnimatedScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true); // Make it go back and forth

    _animation = Tween<double>(begin: 0.0, end: widget.height).animate(
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value - 2, // Adjust position slightly based on line height
          left: 0,
          right: 0,
          child: Container(
            height: 4, // Thickness of the scan line
            decoration: BoxDecoration(
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
               borderRadius: BorderRadius.circular(2), // Optional: rounded ends
            ),
          ),
        );
      },
    );
  }
}