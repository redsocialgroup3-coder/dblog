import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/widgets.dart';

import '../constants/audio_constants.dart';

/// Modo de muestreo adaptativo para optimizar batería.
enum SamplingMode {
  /// Muestreo cada 500ms, solo último sample.
  passive,

  /// Muestreo cada 100ms, dB cercano al umbral.
  alert,

  /// Muestreo cada 100ms, grabación activa.
  recording,
}

/// Listener de audio con muestreo adaptativo para optimizar consumo de batería.
///
/// Gestiona tres modos de muestreo:
/// - **Pasivo**: 500ms entre lecturas, no procesa buffer completo.
/// - **Alerta**: 100ms entre lecturas, dB está cerca del umbral.
/// - **Grabando**: 100ms constante durante grabación activa.
///
/// Incluye auto-pause cuando la batería baja del 15%.
class BatteryOptimizedListener {
  final Battery _battery;

  /// Modo de muestreo actual.
  SamplingMode _mode = SamplingMode.passive;
  SamplingMode get mode => _mode;

  /// Nivel de batería actual (0-100).
  int _batteryLevel = 100;
  int get batteryLevel => _batteryLevel;

  /// Si la batería está por debajo del umbral.
  bool _isLowBattery = false;
  bool get isLowBattery => _isLowBattery;

  /// Si se pausó automáticamente por batería baja.
  bool _autoPaused = false;
  bool get isAutoPaused => _autoPaused;

  /// Timer para monitoreo de batería.
  Timer? _batteryTimer;

  /// Timer para muestreo adaptativo.
  Timer? _sampleTimer;

  /// Umbral de dB configurado.
  double _threshold = 65.0;

  /// Tiempo consecutivo por debajo del umbral de alerta (ms).
  int _belowAlertMs = 0;

  /// Duración requerida por debajo del umbral para volver a pasivo (10s).
  static const int _returnToPassiveMs = 10000;

  /// Callback ejecutado en cada tick de muestreo.
  void Function(int intervalMs)? onSampleTick;

  /// Callback cuando la batería baja del umbral.
  void Function()? onLowBattery;

  /// Callback cuando se auto-pausa por batería baja.
  void Function()? onAutoPause;

  BatteryOptimizedListener({Battery? battery})
      : _battery = battery ?? Battery();

  /// Inicia el listener con el umbral dado.
  Future<void> start({required double threshold}) async {
    _threshold = threshold;
    _mode = SamplingMode.passive;
    _belowAlertMs = 0;
    _autoPaused = false;

    // Lectura inicial de batería.
    await _checkBattery();

    // Monitoreo de batería cada 60 segundos.
    _batteryTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkBattery(),
    );

    // Iniciar muestreo pasivo.
    _startSamplingTimer(AudioConstants.passiveIntervalMs);
  }

  /// Detiene el listener.
  void stop() {
    _sampleTimer?.cancel();
    _sampleTimer = null;
    _batteryTimer?.cancel();
    _batteryTimer = null;
    _mode = SamplingMode.passive;
    _autoPaused = false;
  }

  /// Actualiza el umbral (sin reiniciar).
  void updateThreshold(double threshold) {
    _threshold = threshold;
  }

  /// Notifica una lectura de dB actual para decidir transiciones.
  ///
  /// Debe llamarse desde el servicio de vigilancia con cada sample procesado.
  void onDbReading(double currentDb) {
    if (_autoPaused) return;

    switch (_mode) {
      case SamplingMode.passive:
        _handlePassiveReading(currentDb);
        break;
      case SamplingMode.alert:
        _handleAlertReading(currentDb);
        break;
      case SamplingMode.recording:
        // En modo recording no se hacen transiciones automáticas;
        // el servicio de vigilancia controla cuándo sale de recording.
        break;
    }
  }

  /// Transiciona a modo grabando (llamado externamente al iniciar grabación).
  void enterRecordingMode() {
    if (_mode == SamplingMode.recording) return;
    _mode = SamplingMode.recording;
    _startSamplingTimer(AudioConstants.activeIntervalMs);
  }

  /// Sale de modo grabando, vuelve a pasivo (llamado al detener grabación).
  void exitRecordingMode() {
    _mode = SamplingMode.passive;
    _belowAlertMs = 0;
    _startSamplingTimer(AudioConstants.passiveIntervalMs);
  }

  /// Verifica nivel de batería y auto-pausa si es necesario.
  Future<void> _checkBattery() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      _isLowBattery = _batteryLevel <= AudioConstants.lowBatteryThreshold;

      if (_isLowBattery && !_autoPaused) {
        _autoPaused = true;
        onLowBattery?.call();
        onAutoPause?.call();
        _sampleTimer?.cancel();
        _sampleTimer = null;
      }
    } catch (e) {
      debugPrint('BatteryOptimizedListener: error leyendo batería: $e');
    }
  }

  /// Maneja lectura en modo pasivo.
  void _handlePassiveReading(double currentDb) {
    final alertThreshold =
        _threshold - AudioConstants.alertThresholdOffset;

    if (currentDb >= alertThreshold) {
      // dB cerca del umbral: subir a modo alerta.
      _mode = SamplingMode.alert;
      _belowAlertMs = 0;
      _startSamplingTimer(AudioConstants.activeIntervalMs);
    }
  }

  /// Maneja lectura en modo alerta.
  void _handleAlertReading(double currentDb) {
    final alertThreshold =
        _threshold - AudioConstants.alertThresholdOffset;

    if (currentDb < alertThreshold) {
      _belowAlertMs += AudioConstants.activeIntervalMs;

      if (_belowAlertMs >= _returnToPassiveMs) {
        // 10s por debajo del umbral de alerta: volver a pasivo.
        _mode = SamplingMode.passive;
        _belowAlertMs = 0;
        _startSamplingTimer(AudioConstants.passiveIntervalMs);
      }
    } else {
      _belowAlertMs = 0;
    }
  }

  /// Inicia el timer de muestreo con el intervalo dado.
  void _startSamplingTimer(int intervalMs) {
    _sampleTimer?.cancel();
    _sampleTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => onSampleTick?.call(intervalMs),
    );
  }

  /// Intervalo actual de muestreo basado en el modo.
  int get currentIntervalMs {
    switch (_mode) {
      case SamplingMode.passive:
        return AudioConstants.passiveIntervalMs;
      case SamplingMode.alert:
      case SamplingMode.recording:
        return AudioConstants.activeIntervalMs;
    }
  }

  /// Libera recursos.
  void dispose() {
    stop();
  }
}
