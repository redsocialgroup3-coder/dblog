import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

/// Resultado de la obtención de ubicación.
class LocationResult {
  final double? latitude;
  final double? longitude;

  const LocationResult({this.latitude, this.longitude});

  bool get hasLocation => latitude != null && longitude != null;
}

/// Servicio para obtener la ubicación actual del dispositivo.
/// Falla gracefully si no hay permiso o GPS desactivado.
class LocationService {
  /// Obtiene la ubicación actual.
  /// Retorna [LocationResult] con valores null si no se pudo obtener.
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Verificar si el servicio de ubicación está habilitado.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: servicio de ubicación deshabilitado.');
        return const LocationResult();
      }

      // Verificar permisos.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: permiso de ubicación denegado.');
          return const LocationResult();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          'LocationService: permiso de ubicación denegado permanentemente.',
        );
        return const LocationResult();
      }

      // Obtener ubicación con timeout.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('LocationService: error obteniendo ubicación: $e');
      return const LocationResult();
    }
  }
}
