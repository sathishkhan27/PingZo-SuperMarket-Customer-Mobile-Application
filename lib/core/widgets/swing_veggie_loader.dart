import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/bento_theme.dart';

class SwingVeggieLoader extends StatelessWidget {
  final String label;

  const SwingVeggieLoader({Key? key, this.label = "Fetching Fresh Produce..."}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("🥦", style: TextStyle(fontSize: 36))
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .rotate(begin: -0.15, end: 0.15, duration: 600.ms, curve: Curves.easeInOut),
              const SizedBox(width: 12),
              const Text("🍅", style: TextStyle(fontSize: 42))
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15), duration: 500.ms),
              const SizedBox(width: 12),
              const Text("🥕", style: TextStyle(fontSize: 36))
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .rotate(begin: 0.15, end: -0.15, duration: 650.ms, curve: Curves.easeInOut),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: BentoTheme.bodyStyle(size: 14, color: BentoTheme.pingzoGreen),
          ),
        ],
      ),
    );
  }
}
