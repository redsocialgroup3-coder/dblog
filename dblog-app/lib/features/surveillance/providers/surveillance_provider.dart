import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/payments/payment_provider.dart';
import '../models/surveillance_event.dart';
import '../services/surveillance_service.dart';

/// ChangeNotifier que gestiona el estado de la vigilancia nocturna.
///
/// Verifica que el usuario sea suscriptor antes de activar la vigilancia.
/// Expone el estado actual, eventos detectados y estadísticas de sesión.
class SurveillanceProvider extends ChangeNotifier {
  final SurveillanceService _service;
  final PaymentProvider _paymentProvider;

  /// Si la vigilancia está activa.
  bool get isActive => _service.state != SurveillanceState.idle;

  /// Si está grabando un pico en este momento.
  bool get isRecording => _service.state == SurveillanceState.recording;

  /// Nivel actual de dB.
  double get currentDb => _service.currentDb;

  /// Umbral configurado.
  double get threshold => _service.threshold;

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
    SurveillanceService? service,
  })  : _paymentProvider = paymentProvider,
        _service = service ?? SurveillanceService() {
    _service.onStateChanged = _onServiceStateChanged;
  }

  /// Callback cuando el servicio cambia de estado.
  void _onServiceStateChanged() {
    notifyListeners();
  }

  /// Inicia la vigilancia nocturna con el umbral dado.
  ///
  /// Verifica que el usuario sea suscriptor antes de activar.
  /// El [threshold] es el nivel de dB a partir del cual se detecta un pico.
  Future<void> start({required double threshold}) async {
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
      await _service.start(threshold: threshold);

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
