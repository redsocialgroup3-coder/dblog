import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/legal/legal_provider.dart';
import '../../../core/payments/payment_provider.dart';
import '../models/surveillance_event.dart';
import '../services/surveillance_service.dart';

/// Clave de shared_preferences para persistir el umbral de detección.
const String _thresholdPrefKey = 'surveillance_threshold';

/// ChangeNotifier que gestiona el estado de la vigilancia nocturna.
///
/// Verifica que el usuario sea suscriptor antes de activar la vigilancia.
/// Expone el estado actual, eventos detectados y estadísticas de sesión.
/// Persiste el umbral de detección configurado por el usuario.
class SurveillanceProvider extends ChangeNotifier {
  final SurveillanceService _service;
  final PaymentProvider _paymentProvider;
  final LegalProvider _legalProvider;

  /// Si la vigilancia está activa.
  bool get isActive => _service.state != SurveillanceState.idle;

  /// Si está grabando un pico en este momento.
  bool get isRecording => _service.state == SurveillanceState.recording;

  /// Nivel actual de dB.
  double get currentDb => _service.currentDb;

  /// Umbral configurado por el usuario (persistido).
  double _threshold = 65.0;
  double get threshold => _threshold;

  /// Límite legal actual del municipio.
  double get legalLimit => _legalProvider.currentLegalLimit ?? 65.0;

  /// Eventos detectados durante la sesión.
  List<SurveillanceEvent> get eventsDetected => _service.events;

  /// Duración total de la sesión en segundos.
  int get totalDurationSeconds => _service.totalDurationSeconds;

  /// Mensaje de error.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Timer para actualizar la duración cada segundo.
  Timer? _durationTimer;

  SurveillanceProvider({
    required PaymentProvider paymentProvider,
    required LegalProvider legalProvider,
    SurveillanceService? service,
  })  : _paymentProvider = paymentProvider,
        _legalProvider = legalProvider,
        _service = service ?? SurveillanceService() {
    _service.onStateChanged = _onServiceStateChanged;
    _loadThreshold();
  }

  /// Callback cuando el servicio cambia de estado.
  void _onServiceStateChanged() {
    notifyListeners();
  }

  /// Carga el umbral persistido o usa el límite legal como default.
  Future<void> _loadThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_thresholdPrefKey);
    _threshold = saved ?? legalLimit;
    notifyListeners();
  }

  /// Establece un nuevo umbral de detección.
  ///
  /// Persiste el valor en shared_preferences y notifica a los listeners.
  Future<void> setThreshold(double value) async {
    _threshold = value.clamp(20.0, 80.0);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_thresholdPrefKey, _threshold);
  }

  /// Resetea el umbral al límite legal del municipio.
  Future<void> resetThresholdToLegal() async {
    await setThreshold(legalLimit);
  }

  /// Inicia la vigilancia nocturna con el umbral configurado.
  ///
  /// Verifica que el usuario sea suscriptor antes de activar.
  /// Usa el [threshold] persistido o el proporcionado como parámetro.
  Future<void> start({double? threshold}) async {
    final effectiveThreshold = threshold ?? _threshold;
    // Verificar suscripción.
    if (!_paymentProvider.isSubscriber) {
      _errorMessage =
          'La vigilancia nocturna está disponible solo para suscriptores.';
      notifyListeners();
      return;
    }

    if (isActive) return;

    _errorMessage = null;

    try {
      await _service.start(threshold: effectiveThreshold);

      // Timer para actualizar duración en la UI.
      _durationTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => notifyListeners(),
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al iniciar la vigilancia: $e';
      debugPrint('SurveillanceProvider: error starting: $e');
      notifyListeners();
    }
  }

  /// Detiene la vigilancia y genera resumen.
  ///
  /// Retorna la lista de eventos detectados durante la sesión.
  Future<List<SurveillanceEvent>> stop() async {
    if (!isActive) return [];

    _durationTimer?.cancel();
    _durationTimer = null;

    final events = await _service.stop();
    notifyListeners();
    return events;
  }

  /// Limpia el mensaje de error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _service.dispose();
    super.dispose();
  }
}
