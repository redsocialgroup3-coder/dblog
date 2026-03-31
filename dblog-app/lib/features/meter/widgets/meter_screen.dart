import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/db_reading.dart';
import '../providers/meter_provider.dart';
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

          return SafeArea(
            child: Column(
              children: [
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
      floatingActionButton: Consumer<MeterProvider>(
        builder: (context, provider, _) {
          final listening = provider.isListening;
          return FloatingActionButton.large(
            onPressed: listening ? provider.stop : provider.start,
            backgroundColor: listening ? Colors.red : Colors.green,
            child: Icon(
              listening ? Icons.stop : Icons.mic,
              size: 36,
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
