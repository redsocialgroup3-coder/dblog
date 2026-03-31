import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../history/widgets/history_screen.dart';

/// Resultado de la comparación con el límite legal.
enum VerdictType {
  /// El promedio supera el límite legal.
  exceeds,

  /// El promedio está cerca del límite (dentro de 5 dB).
  close,

  /// El promedio no supera el límite legal.
  safe,
}

/// Pantalla de veredicto post-grabación.
/// Muestra el resultado de la medición comparado con el límite legal.
class VerdictScreen extends StatelessWidget {
  final double avgDb;
  final double maxDb;
  final int durationSeconds;
  final double legalLimit;

  const VerdictScreen({
    super.key,
    required this.avgDb,
    required this.maxDb,
    required this.durationSeconds,
    this.legalLimit = 55.0,
  });

  VerdictType get _verdict {
    if (avgDb > legalLimit) return VerdictType.exceeds;
    if (avgDb >= legalLimit - 5) return VerdictType.close;
    return VerdictType.safe;
  }

  @override
  Widget build(BuildContext context) {
    final verdict = _verdict;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header.
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  const Text(
                    'Resultado',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance del icono de cierre.
                ],
              ),
              const Spacer(),
              // Veredicto principal.
              _VerdictBadge(verdict: verdict),
              const SizedBox(height: 32),
              // Comparación dB medido vs límite.
              _ComparisonCard(
                avgDb: avgDb,
                maxDb: maxDb,
                legalLimit: legalLimit,
                verdict: verdict,
              ),
              const SizedBox(height: 16),
              // Duración de la grabación.
              _InfoCard(
                icon: Icons.timer_outlined,
                label: 'Duración',
                value: _formatDuration(durationSeconds),
              ),
              const Spacer(),
              // Botones de acción.
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Generar informe PDF (deshabilitado).
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Generar informe PDF (próximamente)'),
          ),
        ),
        const SizedBox(height: 12),
        // Ver en historial.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded),
            label: const Text('Ver en historial'),
          ),
        ),
        const SizedBox(height: 12),
        // Nueva medición.
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Nueva medición'),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '$mins min ${secs}s';
    }
    return '${secs}s';
  }
}

class _VerdictBadge extends StatelessWidget {
  final VerdictType verdict;

  const _VerdictBadge({required this.verdict});

  @override
  Widget build(BuildContext context) {
    final (color, icon, title, subtitle) = switch (verdict) {
      VerdictType.exceeds => (
          AppTheme.danger,
          Icons.warning_rounded,
          'SUPERA EL LÍMITE',
          'El nivel de ruido medido supera el límite legal',
        ),
      VerdictType.close => (
          AppTheme.warning,
          Icons.error_outline_rounded,
          'CERCANO AL LÍMITE',
          'El nivel de ruido está cerca del límite legal',
        ),
      VerdictType.safe => (
          AppTheme.success,
          Icons.check_circle_outline_rounded,
          'NO SUPERA',
          'El nivel de ruido no supera el límite legal',
        ),
    };

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 3,
            ),
          ),
          child: Icon(icon, color: color, size: 48),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final double avgDb;
  final double maxDb;
  final double legalLimit;
  final VerdictType verdict;

  const _ComparisonCard({
    required this.avgDb,
    required this.maxDb,
    required this.legalLimit,
    required this.verdict,
  });

  @override
  Widget build(BuildContext context) {
    final verdictColor = switch (verdict) {
      VerdictType.exceeds => AppTheme.danger,
      VerdictType.close => AppTheme.warning,
      VerdictType.safe => AppTheme.success,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        border: Border.all(
          color: verdictColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Fila: Promedio medido vs Límite legal.
          Row(
            children: [
              Expanded(
                child: _DbValueColumn(
                  label: 'Promedio medido',
                  value: avgDb,
                  color: verdictColor,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppTheme.surfaceLight,
              ),
              Expanded(
                child: _DbValueColumn(
                  label: 'Límite legal',
                  value: legalLimit,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.surfaceLight, height: 1),
          const SizedBox(height: 16),
          // Máximo registrado.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                color: AppTheme.danger,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pico máximo: ',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                '${maxDb.toStringAsFixed(1)} dB',
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DbValueColumn extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _DbValueColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'dB',
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
