import 'dart:convert';

/// Modelo que representa una grabación de audio con sus metadatos.
class Recording {
  /// Identificador único de la grabación.
  final String id;

  /// Timestamp UTC en formato ISO 8601.
  final DateTime timestamp;

  /// Latitud de la ubicación donde se grabó (null si no disponible).
  final double? latitude;

  /// Longitud de la ubicación donde se grabó (null si no disponible).
  final double? longitude;

  /// Nivel de decibelios promedio durante la grabación.
  final double avgDb;

  /// Nivel de decibelios máximo durante la grabación.
  final double maxDb;

  /// Duración de la grabación en segundos.
  final int durationSeconds;

  /// Ruta absoluta del archivo de audio.
  final String filePath;

  /// Nombre del archivo de audio.
  final String fileName;

  const Recording({
    required this.id,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.avgDb,
    required this.maxDb,
    required this.durationSeconds,
    required this.filePath,
    required this.fileName,
  });

  /// Convierte la grabación a un mapa JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'avgDb': double.parse(avgDb.toStringAsFixed(1)),
        'maxDb': double.parse(maxDb.toStringAsFixed(1)),
        'durationSeconds': durationSeconds,
        'filePath': filePath,
        'fileName': fileName,
      };

  /// Crea una grabación desde un mapa JSON.
  factory Recording.fromJson(Map<String, dynamic> json) => Recording(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        latitude: json['latitude'] as double?,
        longitude: json['longitude'] as double?,
        avgDb: (json['avgDb'] as num).toDouble(),
        maxDb: (json['maxDb'] as num).toDouble(),
        durationSeconds: json['durationSeconds'] as int,
        filePath: json['filePath'] as String,
        fileName: json['fileName'] as String,
      );

  /// Serializa a JSON string.
  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());
}
