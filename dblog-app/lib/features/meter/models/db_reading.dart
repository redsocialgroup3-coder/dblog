/// Modelo que representa una lectura de decibelios en un momento dado.
class DbReading {
  /// Momento en que se tomó la lectura.
  final DateTime timestamp;

  /// Nivel de decibelios promedio (dB SPL).
  final double db;

  /// Nivel de decibelios máximo en esta muestra.
  final double peakDb;

  const DbReading({
    required this.timestamp,
    required this.db,
    required this.peakDb,
  });
}
