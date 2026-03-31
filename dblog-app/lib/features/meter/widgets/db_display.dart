import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

/// Muestra el valor numérico de dB en grande.
class DbDisplay extends StatelessWidget {
  final double db;

  const DbDisplay({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorForDb(db);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          db.toStringAsFixed(1),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w200,
                fontSize: 80,
              ),
        ),
        Text(
          'dB SPL',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
        ),
      ],
    );
  }
}
