import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../recording/providers/recording_provider.dart';
import '../../recording/widgets/recording_overlay.dart';
import '../models/db_reading.dart';
import '../providers/meter_provider.dart';
import 'calibration_dialog.dart';
import 'db_chart.dart';
import 'db_display.dart';
import 'db_level_bar.dart';
import 'db_stats_row.dart';

/// Pantalla principal del medidor de decibelios.
class MeterScreen extends StatelessWidget {
  const MeterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dBLog'),
        actions: [
          Consumer<MeterProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Calibración',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CalibrationDialog(
                      calibrationService: provider.calibrationService,
                      onChanged: provider.onCalibrationChanged,
                    ),
                  );
                },
              );
            },
          ),
          Consumer<MeterProvider>(
            builder: (context, provider, _) {
              if (!provider.isListening) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reiniciar',
                onPressed: provider.reset,
              );
            },
          ),
        ],
      ),
      body: Consumer<MeterProvider>(
        builder: (context, provider, _) {
          // Si el permiso fue denegado permanentemente.
          if (provider.permissionDeniedPermanently) {
            return _PermissionDeniedView(
              onOpenSettings: provider.openAppSettings,
            );
          }

          // Mostrar error si lo hay.
          if (provider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage!),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: provider.clearError,
                  ),
                ),
              );
              provider.clearError();
            });
          }

          // Mostrar error de grabación si lo hay.
          final recordingProvider = context.read<RecordingProvider>();
          if (recordingProvider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(recordingProvider.errorMessage!),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: recordingProvider.clearError,
                  ),
                ),
              );
              recordingProvider.clearError();
            });
          }

          // Estado inicial: no se ha iniciado ninguna medición.
          if (!provider.hasStarted && !provider.isListening) {
            return const _EmptyStateView();
          }

          return SafeArea(
            child: Column(
              children: [
                // Overlay de grabación.
                const RecordingOverlay(),
                // Disclaimer de medición orientativa.
                const _DisclaimerBanner(),
                const SizedBox(height: 24),
                // Valor numérico de dB.
                DbDisplay(db: provider.currentDb),
                const SizedBox(height: 24),
                // Barra de nivel.
                DbLevelBar(db: provider.currentDb),
                const SizedBox(height: 24),
                // Estadísticas: max y Leq.
                DbStatsRow(
                  maxDb: provider.maxDb,
                  leq: provider.leq,
                ),
                const SizedBox(height: 24),
                // Gráfica de 60 segundos.
                Expanded(
                  child: Selector<MeterProvider,
                      ({List<DbReading> readings, DateTime? start})>(
                    selector: (_, p) =>
                        (readings: p.readings, start: p.sessionStart),
                    builder: (_, data, _) => DbChart(
                      readings: data.readings,
                      sessionStart: data.start,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildFabs(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFabs(BuildContext context) {
    return Consumer2<MeterProvider, RecordingProvider>(
      builder: (context, meterProvider, recordingProvider, _) {
        final listening = meterProvider.isListening;
        final isRecording = recordingProvider.isRecording;
        final isSaving = recordingProvider.isSaving;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón principal: start/stop medidor.
              FloatingActionButton.large(
                heroTag: 'meter_fab',
                onPressed:
                    isRecording ? null : (listening ? meterProvider.stop : meterProvider.start),
                backgroundColor: isRecording
                    ? Colors.grey
                    : (listening ? Colors.red : Colors.green),
                child: Icon(
                  listening ? Icons.stop : Icons.mic,
                  size: 36,
                ),
              ),
              // Botón secundario: grabar audio (solo visible cuando el medidor está activo).
              if (listening) ...[
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: 'record_fab',
                  onPressed: isSaving
                      ? null
                      : (isRecording
                          ? recordingProvider.stopRecording
                          : recordingProvider.startRecording),
                  backgroundColor: isSaving
                      ? Colors.grey
                      : (isRecording ? Colors.red.shade800 : Colors.orange),
                  child: isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isRecording ? Icons.stop : Icons.fiber_manual_record,
                          size: 28,
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_none, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              'Medidor de ruido',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Pulsa el botón para comenzar a medir el nivel de ruido en decibelios.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _PermissionDeniedView({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Permiso de micrófono denegado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'dBLog necesita acceso al micrófono para medir el nivel de ruido. '
              'Abre la configuración para conceder el permiso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Abrir configuración'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.orange.withValues(alpha: 0.15),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Medición orientativa - no sustituye sonómetro homologado',
              style: TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}
