/// Constantes de audio para la aplicación dBLog.
class AudioConstants {
  AudioConstants._();

  /// Frecuencia de muestreo objetivo (Hz).
  static const int sampleRate = 44100;

  /// Intervalo de actualización de la lectura (ms).
  static const int updateIntervalMs = 100;

  /// Duración de la ventana de la gráfica (segundos).
  static const int chartWindowSeconds = 60;

  /// Máximo de lecturas en el buffer circular (60s / 100ms).
  static const int maxReadings = 600;

  /// Rango mínimo del eje Y en la gráfica (dB).
  static const double minDb = 30.0;

  /// Rango máximo del eje Y en la gráfica (dB).
  static const double maxDb = 130.0;

  /// Umbrales de nivel de ruido (dB SPL).
  static const double thresholdQuiet = 50.0;
  static const double thresholdModerate = 70.0;
  static const double thresholdLoud = 85.0;
  static const double thresholdDangerous = 100.0;
}
