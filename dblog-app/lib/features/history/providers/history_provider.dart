import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/sync/sync_service.dart';
import '../../recording/models/recording.dart';

/// Provider que gestiona el historial de grabaciones.
/// Carga las grabaciones del filesystem leyendo los JSON de metadatos,
/// las ordena por fecha descendente y limita a 5 en tier gratuito.
class HistoryProvider extends ChangeNotifier {
  List<Recording> _recordings = [];

  /// Todas las grabaciones disponibles (ya ordenadas por fecha descendente).
  List<Recording> get recordings => _recordings;

  /// Grabaciones visibles según el tier del usuario.
  /// Tier gratuito: últimas 5. Suscripción: todas.
  List<Recording> get visibleRecordings {
    if (_isSubscribed) return _recordings;
    return _recordings.take(5).toList();
  }

  /// Número total de grabaciones almacenadas.
  int get totalCount => _recordings.length;

  /// Indica si hay grabaciones ocultas por límite del tier gratuito.
  int get hiddenCount {
    if (_isSubscribed) return 0;
    return (_recordings.length > 5) ? _recordings.length - 5 : 0;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // TODO: integrar con RevenueCat cuando esté disponible.
  final bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  /// Carga las grabaciones desde el directorio de la app.
  Future<void> loadRecordings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${appDir.path}/recordings');

      if (!await recordingsDir.exists()) {
        _recordings = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final jsonFiles = recordingsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      final List<Recording> loaded = [];
      for (final file in jsonFiles) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          loaded.add(Recording.fromJson(json));
        } catch (e) {
          debugPrint('HistoryProvider: error leyendo ${file.path}: $e');
        }
      }

      // Intentar mergear con grabaciones remotas.
      try {
        final remoteRecordings = await SyncService.instance.downloadRecordings();
        final localIds = loaded.map((r) => r.id).toSet();
        for (final remote in remoteRecordings) {
          if (!localIds.contains(remote.id)) {
            loaded.add(remote);
          }
        }
      } catch (e) {
        debugPrint('HistoryProvider: no se pudo cargar remotas: $e');
      }

      // Ordenar por fecha descendente (más reciente primero).
      loaded.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _recordings = loaded;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar grabaciones: $e';
      debugPrint('HistoryProvider: $e');
      notifyListeners();
    }
  }

  /// Elimina una grabación individual (archivo de audio + JSON).
  Future<void> deleteRecording(Recording recording) async {
    try {
      // Eliminar archivo de audio.
      final audioFile = File(recording.filePath);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }

      // Eliminar archivo JSON de metadatos.
      final jsonPath = recording.filePath.replaceAll('.m4a', '.json');
      final jsonFile = File(jsonPath);
      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }

      _recordings.removeWhere((r) => r.id == recording.id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al eliminar grabación: $e';
      debugPrint('HistoryProvider: error eliminando: $e');
      notifyListeners();
    }
  }

  /// Elimina todas las grabaciones.
  Future<void> deleteAllRecordings() async {
    try {
      final toDelete = List<Recording>.from(_recordings);
      for (final recording in toDelete) {
        final audioFile = File(recording.filePath);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
        final jsonPath = recording.filePath.replaceAll('.m4a', '.json');
        final jsonFile = File(jsonPath);
        if (await jsonFile.exists()) {
          await jsonFile.delete();
        }
      }

      _recordings.clear();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al eliminar grabaciones: $e';
      debugPrint('HistoryProvider: error eliminando todas: $e');
      notifyListeners();
    }
  }

  /// Limpia el mensaje de error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
