import 'dart:developer';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'data/spain_regulations.dart';
import 'models/verdict_result.dart';

/// Servicio que gestiona la logica de deteccion de ubicacion,
/// franja horaria y calculo de veredicto legal.
class LegalService {
  LegalService._();
  static final LegalService instance = LegalService._();

  /// Obtiene el municipio actual via reverse geocoding.
  /// Retorna null si no se puede determinar.
  Future<String?> detectMunicipality() async {
    try {
      // Verificar permisos de ubicacion.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      // Obtener posicion actual.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Reverse geocoding.
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        // locality es el municipio/ciudad.
        return placemark.locality;
      }
    } catch (e) {
      log('Error detectando municipio: $e');
    }
    return null;
  }

  /// Determina la franja horaria segun la hora local.
  /// - Diurno: 07:00 - 19:00
  /// - Evening: 19:00 - 23:00
  /// - Nocturno: 23:00 - 07:00
  String detectTimePeriod({DateTime? now}) {
    final time = now ?? DateTime.now();
    final hour = time.hour;

    if (hour >= 7 && hour < 19) return 'diurno';
    if (hour >= 19 && hour < 23) return 'evening';
    return 'nocturno';
  }

  /// Etiqueta legible para la franja horaria.
  String timePeriodLabel(String timePeriod) {
    switch (timePeriod) {
      case 'diurno':
        return 'Diurno (7:00 - 19:00)';
      case 'evening':
        return 'Evening (19:00 - 23:00)';
      case 'nocturno':
        return 'Nocturno (23:00 - 7:00)';
      default:
        return timePeriod;
    }
  }

  /// Calcula el veredicto legal offline usando datos embebidos.
  VerdictResult? computeVerdictOffline({
    required String municipality,
    required String zoneType,
    required String timePeriod,
    required String noiseType,
    required double measuredDb,
  }) {
    final limitDb = SpainRegulations.getLimit(
      zoneType: zoneType,
      timePeriod: timePeriod,
      noiseType: noiseType,
    );

    if (limitDb == null) return null;

    final difference = measuredDb - limitDb;
    VerdictType verdict;
    if (measuredDb > limitDb) {
      verdict = VerdictType.supera;
    } else if (measuredDb >= limitDb - 5.0) {
      verdict = VerdictType.cercano;
    } else {
      verdict = VerdictType.noSupera;
    }

    return VerdictResult(
      limitDb: limitDb,
      measuredDb: measuredDb,
      differenceDb: double.parse(difference.toStringAsFixed(1)),
      verdict: verdict,
      regulationName: SpainRegulations.regulationName,
      article: SpainRegulations.article,
      timePeriod: timePeriod,
      municipality: municipality,
    );
  }
}
