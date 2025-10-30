
import 'package:flutter/material.dart';

class CustomMacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final Color color;

  const CustomMacroBar({
    super.key,
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress = goal <= 0 ? 0 : (current / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text('${current.toStringAsFixed(0)}/${goal.toStringAsFixed(0)}g', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.7), color],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
