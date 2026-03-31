import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/surveillance_event.dart';

/// Widget que muestra un evento de ruido detectado en la lista de vigilancia.
///
/// Muestra hora de inicio, duración, dB máximo con color e icono de grabación.
/// Al hacer tap navega al detalle de la grabación.
class SurveillanceEventTile extends StatelessWidget {
  /// Evento de vigilancia a mostrar.
  final SurveillanceEvent event;

  /// Callback al hacer tap en el tile.
  final VoidCallback? onTap;

  const SurveillanceEventTile({
    super.key,
    required this.event,
    this.onTap,
  });

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min}m ${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    final dbColor = AppTheme.colorForDb(event.maxDb);
    final hasRecording = event.recordingId != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
          border: Border.all(
            color: AppTheme.surfaceLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icono de grabación.
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasRecording
                    ? dbColor.withValues(alpha: 0.15)
                    : AppTheme.surfaceLight,
              ),
              child: Icon(
                hasRecording
                    ? Icons.fiber_manual_record_rounded
                    : Icons.hearing_rounded,
                color: hasRecording ? dbColor : AppTheme.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Hora y duración.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(event.startTime),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Duración: ${_formatDuration(event.durationSeconds)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // dB máximo con color.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: dbColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
              ),
              child: Text(
                '${event.maxDb.toStringAsFixed(1)} dB',
                style: TextStyle(
                  color: dbColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Flecha para ver detalle.
            if (hasRecording) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
