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
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.arrow_upward_rounded,
              label: 'Máximo',
              value: maxDb > 0 ? '${maxDb.toStringAsFixed(1)} dB' : '-- dB',
              color: AppTheme.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.equalizer_rounded,
              label: 'Promedio (Leq)',
              value: leq > 0 ? '${leq.toStringAsFixed(1)} dB' : '-- dB',
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
