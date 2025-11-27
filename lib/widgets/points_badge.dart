import 'package:flutter/material.dart';

class PointsBadge extends StatelessWidget {
  final int points;
  final bool isLarge;

  const PointsBadge({
    super.key,
    required this.points,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 20 : 16,
        vertical: isLarge ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.tertiary,
        borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.tertiary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars,
            color: colorScheme.onTertiary,
            size: isLarge ? 28 : 20,
          ),
          SizedBox(width: isLarge ? 10 : 8),
          Text(
            '$points',
            style: TextStyle(
              color: colorScheme.onTertiary,
              fontSize: isLarge ? 24 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: isLarge ? 6 : 4),
          Text(
            'puntos',
            style: TextStyle(
              color: colorScheme.onTertiary,
              fontSize: isLarge ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
