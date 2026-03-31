import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../recording/models/recording.dart';
import '../../report/widgets/report_form_screen.dart';
import '../providers/history_provider.dart';

/// Pantalla de detalle de una grabación con reproducción de audio,
/// visualización de onda basada en los datos de dB y marcas de picos.
class RecordingDetailScreen extends StatefulWidget {
  final Recording recording;

  const RecordingDetailScreen({super.key, required this.recording});

  @override
  State<RecordingDetailScreen> createState() => _RecordingDetailScreenState();
}

class _RecordingDetailScreenState extends State<RecordingDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  /// Lecturas de dB por segundo para la visualización de onda.
  List<double> _dbSamples = [];

  /// Umbral para marcar picos de dB (percentil 90 de las lecturas).
  double _peakThreshold = 0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _loadDbSamples();
  }

  Future<void> _initPlayer() async {
    try {
      final file = File(widget.recording.filePath);
      if (await file.exists()) {
        await _player.setFilePath(widget.recording.filePath);
        _duration = _player.duration ?? Duration.zero;
        if (mounted) setState(() {});
      }

      _positionSub = _player.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });

      _stateSub = _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              _position = Duration.zero;
              _player.seek(Duration.zero);
              _player.pause();
            }
          });
        }
      });
    } catch (e) {
      debugPrint('RecordingDetailScreen: error inicializando player: $e');
    }
  }

  /// Intenta cargar las lecturas de dB desde el JSON de metadatos.
  /// Si no hay datos granulares, genera muestras simuladas basadas
  /// en avgDb y maxDb para la visualización.
  Future<void> _loadDbSamples() async {
    try {
      final jsonPath =
          widget.recording.filePath.replaceAll('.m4a', '.json');
      final file = File(jsonPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;

        // Verificar si existe campo dbReadings en el JSON.
        if (json.containsKey('dbReadings') && json['dbReadings'] is List) {
          _dbSamples = (json['dbReadings'] as List)
              .map((e) => (e as num).toDouble())
              .toList();
        }
      }
    } catch (e) {
      debugPrint('RecordingDetailScreen: error cargando dbSamples: $e');
    }

    // Si no hay muestras reales, generar basándose en los metadatos.
    if (_dbSamples.isEmpty) {
      _dbSamples = _generateSamples(
        widget.recording.durationSeconds,
        widget.recording.avgDb,
        widget.recording.maxDb,
      );
    }

    // Calcular umbral de picos (percentil 85).
    if (_dbSamples.isNotEmpty) {
      final sorted = List<double>.from(_dbSamples)..sort();
      final idx = (sorted.length * 0.85).floor().clamp(0, sorted.length - 1);
      _peakThreshold = sorted[idx];
    }

    if (mounted) setState(() {});
  }

  /// Genera muestras sintéticas para la visualización cuando no hay
  /// datos granulares disponibles.
  List<double> _generateSamples(int seconds, double avg, double max) {
    if (seconds <= 0) return [];
    final samples = <double>[];
    // Usar un patrón determinista basado en el id de la grabación.
    final seed = widget.recording.id.hashCode;
    for (int i = 0; i < seconds; i++) {
      // Generar variación determinista alrededor del promedio.
      final variation = ((seed + i * 7) % 20 - 10) / 10.0;
      final range = max - avg;
      final value = (avg + variation * range * 0.5).clamp(0.0, max);
      samples.add(value);
    }
    // Asegurar que el máximo aparezca al menos una vez.
    if (samples.isNotEmpty) {
      samples[samples.length ~/ 3] = max;
    }
    return samples;
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recording = widget.recording;
    final date = recording.timestamp.toLocal();
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grabación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Eliminar grabación',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fecha y hora.
              Text(
                '$dateStr  $timeStr',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Estadísticas principales.
              Row(
                children: [
                  _StatCard(
                    label: 'Máximo',
                    value: '${recording.maxDb.toStringAsFixed(1)} dB',
                    color: AppTheme.colorForDb(recording.maxDb),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Promedio',
                    value: '${recording.avgDb.toStringAsFixed(1)} dB',
                    color: AppTheme.colorForDb(recording.avgDb),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Duración',
                    value: _formatDuration(recording.durationSeconds),
                    color: AppTheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Visualización de onda con marcas de picos.
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: _dbSamples.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin datos de onda',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : CustomPaint(
                        size: Size.infinite,
                        painter: _WaveformPainter(
                          samples: _dbSamples,
                          peakThreshold: _peakThreshold,
                          maxDb: recording.maxDb,
                          progress: _duration.inMilliseconds > 0
                              ? _position.inMilliseconds /
                                  _duration.inMilliseconds
                              : 0.0,
                        ),
                      ),
              ),
              const SizedBox(height: 8),

              // Leyenda de picos.
              if (_dbSamples.isNotEmpty)
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pico de dB (>${_peakThreshold.toStringAsFixed(0)} dB)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Controles de reproducción.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Slider de posición.
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _duration.inMilliseconds > 0
                            ? _position.inMilliseconds
                                .toDouble()
                                .clamp(0, _duration.inMilliseconds.toDouble())
                            : 0,
                        max: _duration.inMilliseconds > 0
                            ? _duration.inMilliseconds.toDouble()
                            : 1,
                        activeColor: AppTheme.primary,
                        inactiveColor: Colors.grey.shade700,
                        onChanged: (value) {
                          _player
                              .seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                    // Tiempos.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDurationMs(_position),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          Text(
                            _formatDurationMs(_duration),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Botón play/pause.
                    IconButton.filled(
                      onPressed: _togglePlayPause,
                      iconSize: 36,
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                      ),
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ubicación si está disponible.
              if (recording.latitude != null && recording.longitude != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${recording.latitude!.toStringAsFixed(4)}, '
                        '${recording.longitude!.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Botón generar informe PDF.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportFormScreen(
                          preselectedRecording: recording,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Generar informe PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar grabación'),
        content: const Text(
          'Esta grabación se eliminará permanentemente. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<HistoryProvider>()
                  .deleteRecording(widget.recording);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _formatDurationMs(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

/// Card de estadística.
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter para la visualización de onda con marcas de picos de dB.
class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final double peakThreshold;
  final double maxDb;
  final double progress;

  _WaveformPainter({
    required this.samples,
    required this.peakThreshold,
    required this.maxDb,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final barWidth = size.width / samples.length;
    final maxHeight = size.height;

    for (int i = 0; i < samples.length; i++) {
      final db = samples[i];
      final normalizedHeight = maxDb > 0
          ? (db / maxDb * maxHeight * 0.9).clamp(4.0, maxHeight)
          : 4.0;

      final isPeak = db >= peakThreshold;
      final isPlayed = progress > 0 && (i / samples.length) <= progress;

      final Color barColor;
      if (isPeak) {
        barColor = Colors.red.withValues(alpha: isPlayed ? 0.9 : 0.6);
      } else if (isPlayed) {
        barColor = AppTheme.primary.withValues(alpha: 0.9);
      } else {
        barColor = AppTheme.primary.withValues(alpha: 0.4);
      }

      final paint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      final x = i * barWidth;
      final y = (maxHeight - normalizedHeight) / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 1, y, barWidth - 2, normalizedHeight),
          const Radius.circular(2),
        ),
        paint,
      );

      // Marca de pico: punto rojo encima de la barra.
      if (isPeak) {
        final dotPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(x + barWidth / 2, y - 4),
          3,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.samples != samples;
  }
}
