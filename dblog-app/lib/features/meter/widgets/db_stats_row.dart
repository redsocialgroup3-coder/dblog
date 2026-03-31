import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

/// Fila con estadísticas: máximo dB y Leq.
class DbStatsRow extends StatelessWidget {
  final double maxDb;
  final double leq;

  const DbStatsRow({
    super.key,
    required this.maxDb,
    required this.leq,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatCard(
            label: 'Máximo',
            value: maxDb > 0 ? '${maxDb.toStringAsFixed(1)} dB' : '-- dB',
            color: AppTheme.levelDangerous,
          ),
          _StatCard(
            label: 'Promedio (Leq)',
            value: leq > 0 ? '${leq.toStringAsFixed(1)} dB' : '-- dB',
            color: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
