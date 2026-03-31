import 'dart:convert';

/// Modelo que representa un evento de ruido detectado durante la vigilancia nocturna.
class SurveillanceEvent {
  /// Identificador único del evento.
  final String id;

  /// Momento en que se detectó el pico (inicio del evento).
  final DateTime startTime;

  /// Momento en que el ruido bajó del umbral (fin del evento).
  final DateTime? endTime;

  /// Duración del evento en segundos.
  int get durationSeconds {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inSeconds;
  }

  /// Nivel máximo de dB registrado durante el evento.
  final double maxDb;

  /// Nivel promedio de dB durante el evento.
  final double avgDb;

  /// ID de la grabación asociada a este evento.
  final String? recordingId;

  const SurveillanceEvent({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.maxDb,
    required this.avgDb,
    this.recordingId,
  });

  /// Crea una copia con valores opcionales modificados.
  SurveillanceEvent copyWith({
    DateTime? endTime,
    double? maxDb,
    double? avgDb,
    String? recordingId,
  }) {
    return SurveillanceEvent(
      id: id,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      maxDb: maxDb ?? this.maxDb,
      avgDb: avgDb ?? this.avgDb,
      recordingId: recordingId ?? this.recordingId,
    );
  }

  /// Convierte el evento a un mapa JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime?.toUtc().toIso8601String(),
        'durationSeconds': durationSeconds,
        'maxDb': double.parse(maxDb.toStringAsFixed(1)),
        'avgDb': double.parse(avgDb.toStringAsFixed(1)),
        'recordingId': recordingId,
      };

  /// Crea un evento desde un mapa JSON.
  factory SurveillanceEvent.fromJson(Map<String, dynamic> json) =>
      SurveillanceEvent(
        id: json['id'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        maxDb: (json['maxDb'] as num).toDouble(),
        avgDb: (json['avgDb'] as num).toDouble(),
        recordingId: json['recordingId'] as String?,
      );

  /// Serializa a JSON string.
  String toJsonString() =>
      const JsonEncoder.withIndent('  ').convert(toJson());
}
