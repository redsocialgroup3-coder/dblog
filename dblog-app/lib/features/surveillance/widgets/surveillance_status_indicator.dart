import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

/// Widget animado que indica el estado de la vigilancia nocturna.
///
/// - Escucha pasiva: punto verde pulsante + "Escuchando..."
/// - Grabando evento: punto rojo pulsante + "Grabando evento..."
/// - Muestra el dB actual con tamaño de fuente grande.
class SurveillanceStatusIndicator extends StatefulWidget {
  /// Si está grabando un evento (true) o en escucha pasiva (false).
  final bool isRecording;

  /// Nivel de dB actual.
  final double currentDb;

  /// Umbral configurado como referencia.
  final double threshold;

  /// Duración de la sesión activa en segundos.
  final int sessionDurationSeconds;

  const SurveillanceStatusIndicator({
    super.key,
    required this.isRecording,
    required this.currentDb,
    required this.threshold,
    required this.sessionDurationSeconds,
  });

  @override
  State<SurveillanceStatusIndicator> createState() =>
      _SurveillanceStatusIndicatorState();
}

class _SurveillanceStatusIndicatorState
    extends State<SurveillanceStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isRecording ? AppTheme.danger : AppTheme.success;
    final statusText =
        widget.isRecording ? 'Grabando evento...' : 'Escuchando...';
    final dbColor = AppTheme.colorForDb(widget.currentDb);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Indicador de estado con punto pulsante.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: _pulseAnimation.value),
                      boxShadow: [
                        BoxShadow(
                          color:
                              color.withValues(alpha: _pulseAnimation.value * 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Text(
                statusText,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // dB actual grande.
          Text(
            widget.currentDb.toStringAsFixed(1),
            style: TextStyle(
              color: dbColor,
              fontSize: 56,
              fontWeight: FontWeight.w300,
              letterSpacing: -1.5,
            ),
          ),
          Text(
            'dB',
            style: TextStyle(
              color: dbColor.withValues(alpha: 0.7),
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),

          // Umbral de referencia y duración.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoChip(
                icon: Icons.tune_rounded,
                label: 'Umbral',
                value: '${widget.threshold.round()} dB',
              ),
              _InfoChip(
                icon: Icons.timer_outlined,
                label: 'Sesión',
                value: _formatDuration(widget.sessionDurationSeconds),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
