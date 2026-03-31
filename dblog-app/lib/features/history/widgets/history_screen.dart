import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import 'recording_tile.dart';

/// Pantalla con el historial de grabaciones.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar grabaciones al entrar a la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadRecordings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          Consumer<HistoryProvider>(
            builder: (context, provider, _) {
              if (provider.recordings.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Eliminar todas',
                onPressed: () => _confirmDeleteAll(context, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, _) {
          // Mostrar errores.
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

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.recordings.isEmpty) {
            return const _EmptyHistoryView();
          }

          final visible = provider.visibleRecordings;
          final hiddenCount = provider.hiddenCount;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    return RecordingTile(
                      recording: visible[index],
                    );
                  },
                ),
              ),
              if (hiddenCount > 0)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.orange.withValues(alpha: 0.15),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$hiddenCount grabaciones ocultas. '
                          'Suscribete para acceso ilimitado.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar todas'),
        content: Text(
          'Se eliminarán ${provider.totalCount} grabaciones permanentemente. '
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
              provider.deleteAllRecordings();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar todas'),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              'Sin grabaciones',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Las grabaciones que realices aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
