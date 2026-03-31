/// Datos offline de la Ley 37/2003 (Real Decreto 1367/2007) de Espana.
/// Limites de ruido por zona, franja horaria y tipo (exterior/interior).
/// Se usa como fallback cuando no hay conexion al API.
class SpainRegulations {
  SpainRegulations._();

  static const String regulationName =
      'Ley 37/2003 - Real Decreto 1367/2007';
  static const String article = 'Anexo II - Tabla A/B';
  static const String fallbackMunicipality = 'Espana (Ley 37/2003)';

  /// Municipios disponibles offline.
  static const List<String> municipalities = [
    'Espana (Ley 37/2003)',
    'Madrid',
    'Barcelona',
    'Valencia',
    'Sevilla',
    'Zaragoza',
    'Malaga',
    'Bilbao',
  ];

  /// Limites de ruido exterior en dB por zona y franja.
  /// Estructura: zone_type -> time_period -> db_limit
  static const Map<String, Map<String, double>> exteriorLimits = {
    'residencial': {
      'diurno': 65.0,
      'evening': 65.0,
      'nocturno': 55.0,
    },
    'comercial': {
      'diurno': 70.0,
      'evening': 70.0,
      'nocturno': 60.0,
    },
    'industrial': {
      'diurno': 75.0,
      'evening': 75.0,
      'nocturno': 65.0,
    },
  };

  /// Limites de ruido interior en dB por zona y franja.
  static const Map<String, Map<String, double>> interiorLimits = {
    'residencial': {
      'diurno': 35.0,
      'evening': 35.0,
      'nocturno': 30.0,
    },
    'comercial': {
      'diurno': 45.0,
      'evening': 45.0,
      'nocturno': 35.0,
    },
    'industrial': {
      'diurno': 50.0,
      'evening': 50.0,
      'nocturno': 40.0,
    },
  };

  /// Obtiene el limite de dB para los parametros dados.
  /// Retorna null si no se encuentra la combinacion.
  static double? getLimit({
    required String zoneType,
    required String timePeriod,
    required String noiseType,
  }) {
    final limits =
        noiseType == 'interior' ? interiorLimits : exteriorLimits;
    return limits[zoneType]?[timePeriod];
  }
}
