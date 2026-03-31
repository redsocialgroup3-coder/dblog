import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../recording/models/recording.dart';
import 'recording_detail_screen.dart';

/// Tile que muestra una grabación en la lista del historial.
/// Incluye fecha, duración, dB máximo e icono de play.
class RecordingTile extends StatelessWidget {
  final Recording recording;

  const RecordingTile({super.key, required this.recording});

  @override
  Widget build(BuildContext context) {
    final date = recording.timestamp.toLocal();
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final durationStr = _formatDuration(recording.durationSeconds);
    final dbColor = AppTheme.colorForDb(recording.maxDb);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: AppTheme.surface,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: dbColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              recording.maxDb.toStringAsFixed(0),
              style: TextStyle(
                color: dbColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          '$dateStr  $timeStr',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              durationStr,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 12),
            Icon(Icons.show_chart, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              'Prom: ${recording.avgDb.toStringAsFixed(1)} dB',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
        trailing: const Icon(Icons.play_arrow, color: AppTheme.primary),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecordingDetailScreen(recording: recording),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
