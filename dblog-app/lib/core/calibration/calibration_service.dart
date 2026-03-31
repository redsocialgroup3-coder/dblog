import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de calibración del micrófono.
/// Gestiona un offset en dB que se aplica a todas las lecturas
/// y se persiste entre sesiones con shared_preferences.
class CalibrationService {
  static const String _offsetKey = 'calibration_offset_db';
  static const double defaultOffset = 0.0;
  static const double minOffset = -20.0;
  static const double maxOffset = 20.0;

  double _offset = defaultOffset;

  /// Offset actual de calibración en dB.
  double get offset => _offset;

  /// Carga el offset guardado desde shared_preferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _offset = prefs.getDouble(_offsetKey) ?? defaultOffset;
  }

  /// Establece un nuevo offset y lo persiste.
  Future<void> setOffset(double value) async {
    _offset = value.clamp(minOffset, maxOffset);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_offsetKey, _offset);
  }

  /// Reinicia el offset al valor por defecto.
  Future<void> reset() async {
    await setOffset(defaultOffset);
  }
}
