import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/recording/models/recording.dart';
import '../api/api_service.dart';

/// Servicio de sincronización de grabaciones con el servidor.
/// Gestiona la cola de uploads pendientes y la sincronización bidireccional.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final ApiService _api = ApiService.instance;

  static const String _pendingQueueKey = 'sync_pending_uploads';
  static const String _lastSyncKey = 'sync_last_sync_time';

  /// Obtiene la lista de IDs pendientes de subir.
  Future<List<String>> getPendingIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pendingQueueKey) ?? [];
  }

  /// Agrega un ID a la cola de pendientes.
  Future<void> addToPendingQueue(String recordingId) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingQueueKey) ?? [];
    if (!pending.contains(recordingId)) {
      pending.add(recordingId);
      await prefs.setStringList(_pendingQueueKey, pending);
    }
  }

  /// Elimina un ID de la cola de pendientes.
  Future<void> removeFromPendingQueue(String recordingId) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingQueueKey) ?? [];
    pending.remove(recordingId);
    await prefs.setStringList(_pendingQueueKey, pending);
  }

  /// Sube una grabación al servidor.
  Future<bool> uploadRecording(Recording recording) async {
    try {
      final audioFile = File(recording.filePath);
      if (!await audioFile.exists()) {
        debugPrint('SyncService: archivo no encontrado: ${recording.filePath}');
        return false;
      }

      await _api.uploadFile(
        '/recordings/upload',
        file: audioFile,
        fields: {
          'file_name': recording.fileName,
          'timestamp': recording.timestamp.toUtc().toIso8601String(),
          'local_id': recording.id,
          if (recording.latitude != null)
            'latitude': recording.latitude.toString(),
          if (recording.longitude != null)
            'longitude': recording.longitude.toString(),
          if (recording.avgDb != 0) 'avg_db': recording.avgDb.toString(),
          if (recording.maxDb != 0) 'max_db': recording.maxDb.toString(),
          if (recording.durationSeconds != 0)
            'duration_seconds': recording.durationSeconds.toString(),
        },
      );

      await removeFromPendingQueue(recording.id);
      debugPrint('SyncService: recording subida: ${recording.id}');
      return true;
    } catch (e) {
      debugPrint('SyncService: error subiendo ${recording.id}: $e');
      return false;
    }
  }

  /// Descarga la lista de grabaciones del servidor.
  Future<List<Recording>> downloadRecordings() async {
    try {
      final data = await _api.getList('/recordings/');
      return data.map((json) {
        final map = json as Map<String, dynamic>;
        return Recording(
          id: map['id'] as String,
          timestamp: DateTime.parse(map['timestamp'] as String),
          latitude: (map['latitude'] as num?)?.toDouble(),
          longitude: (map['longitude'] as num?)?.toDouble(),
          avgDb: (map['avg_db'] as num?)?.toDouble() ?? 0.0,
          maxDb: (map['max_db'] as num?)?.toDouble() ?? 0.0,
          durationSeconds: (map['duration_seconds'] as int?) ?? 0,
          filePath: map['file_path'] as String,
          fileName: map['file_name'] as String,
        );
      }).toList();
    } catch (e) {
      debugPrint('SyncService: error descargando recordings: $e');
      return [];
    }
  }

  /// Ejecuta sincronización bidireccional completa.
  /// Retorna true si la sincronización fue exitosa.
  Future<bool> syncAll() async {
    try {
      // 1. Obtener grabaciones locales.
      final localRecordings = await _loadLocalRecordings();
      final localIds = localRecordings.map((r) => r.id).toList();

      // 2. Consultar qué falta en cada lado.
      final syncResult = await _api.post(
        '/recordings/sync',
        body: {'local_ids': localIds},
      );

      // 3. Subir las que faltan en el servidor.
      final missingOnServer =
          (syncResult['missing_on_server'] as List<dynamic>?)
                  ?.cast<String>() ??
              [];

      for (final id in missingOnServer) {
        final recording = localRecordings.where((r) => r.id == id).firstOrNull;
        if (recording != null) {
          await uploadRecording(recording);
        }
      }

      // 4. Descargar las que faltan en el cliente (guardar metadatos localmente).
      final missingOnClient =
          (syncResult['missing_on_client'] as List<dynamic>?) ?? [];

      for (final json in missingOnClient) {
        final map = json as Map<String, dynamic>;
        await _saveRemoteRecordingLocally(map);
      }

      // 5. Subir pendientes restantes.
      final pendingIds = await getPendingIds();
      for (final id in pendingIds) {
        final recording =
            localRecordings.where((r) => r.id == id).firstOrNull;
        if (recording != null) {
          await uploadRecording(recording);
        }
      }

      // 6. Guardar timestamp de última sincronización.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      debugPrint('SyncService: sincronización completada');
      return true;
    } catch (e) {
      debugPrint('SyncService: error en syncAll: $e');
      return false;
    }
  }

  /// Obtiene el timestamp de la última sincronización.
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Carga las grabaciones locales desde el filesystem.
  Future<List<Recording>> _loadLocalRecordings() async {
    final appDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${appDir.path}/recordings');

    if (!await recordingsDir.exists()) return [];

    final jsonFiles = recordingsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    final List<Recording> recordings = [];
    for (final file in jsonFiles) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        recordings.add(Recording.fromJson(json));
      } catch (e) {
        debugPrint('SyncService: error leyendo ${file.path}: $e');
      }
    }
    return recordings;
  }

  /// Guarda metadatos de una grabación remota localmente.
  Future<void> _saveRemoteRecordingLocally(Map<String, dynamic> map) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final recording = Recording(
        id: map['id'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        avgDb: (map['avg_db'] as num?)?.toDouble() ?? 0.0,
        maxDb: (map['max_db'] as num?)?.toDouble() ?? 0.0,
        durationSeconds: (map['duration_seconds'] as int?) ?? 0,
        filePath: map['file_path'] as String,
        fileName: map['file_name'] as String,
      );

      final jsonPath = '${recordingsDir.path}/dblog_${recording.id}.json';
      final file = File(jsonPath);
      await file.writeAsString(recording.toJsonString());
      debugPrint('SyncService: recording remota guardada localmente: ${recording.id}');
    } catch (e) {
      debugPrint('SyncService: error guardando recording remota: $e');
    }
  }
}
