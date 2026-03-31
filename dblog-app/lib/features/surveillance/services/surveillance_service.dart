import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/audio/battery_optimized_listener.dart';
import '../../../core/audio/noise_meter_service.dart';
import '../../../core/calibration/calibration_service.dart';
import '../../../core/constants/audio_constants.dart';
import '../../../core/notifications/notification_service.dart';
import '../../recording/services/recording_service.dart';
import '../models/surveillance_event.dart';

/// Estado del servicio de vigilancia.
enum SurveillanceState {
  /// Inactivo, no escuchando.
  idle,

  /// Escuchando en modo pasivo (muestreo cada 500ms).
  listening,

  /// Detectó pico, grabando audio (muestreo cada 100ms).
  recording,

  /// Auto-pausado por batería baja.
  pausedLowBattery,
}

/// Lectura de dB con timestamp para el buffer circular.
class _DbSample {
  final DateTime timestamp;
  final double db;

  const _DbSample({required this.timestamp, required this.db});
}

/// Servicio core de vigilancia nocturna.
///
/// Escucha continuamente el nivel de dB y detecta picos que superan
/// un umbral configurable. Al detectar un pico, inicia una grabación
/// automática. Detiene la grabación tras 10 segundos consecutivos
/// por debajo del umbral.
///
/// Optimización de batería:
/// - Modo pasivo (listening): muestreo cada 500ms
/// - Modo alerta: cuando dB > (umbral - 10dB), sube a 100ms
/// - Modo activo (recording): muestreo cada 100ms
/// - Auto-pause cuando batería < 15%
class SurveillanceService {
  final NoiseMeterService _noiseMeterService;
  final RecordingService _recordingService;
  final CalibrationService _calibrationService;
  final NotificationService _notificationService;
  final BatteryOptimizedListener _batteryListener;

  StreamSubscription<NoiseReading>? _noiseSubscription;

  /// Estado actual del servicio.
  SurveillanceState _state = SurveillanceState.idle;
  SurveillanceState get state => _state;

  /// Umbral de dB para detección de picos.
  double _threshold = 65.0;
  double get threshold => _threshold;

  /// Nivel actual de dB.
  double _currentDb = 0.0;
  double get currentDb => _currentDb;

  /// Nivel de batería actual (0-100).
  int get batteryLevel => _batteryListener.batteryLevel;

  /// Si la batería está baja.
  bool get isLowBattery => _batteryListener.isLowBattery;

  /// Si se auto-pausó por batería baja.
  bool get isAutoPaused => _batteryListener.isAutoPaused;

  /// Modo de muestreo actual del listener optimizado.
  SamplingMode get samplingMode => _batteryListener.mode;

  /// Buffer circular de 5 segundos (50 samples a 100ms o 10 a 500ms).
  /// Se mantiene siempre con las últimas lecturas.
  static const int _bufferCapacity = 50;
  final Queue<_DbSample> _buffer = Queue<_DbSample>();

  /// Eventos detectados durante la sesión actual.
  final List<SurveillanceEvent> _events = [];
  List<SurveillanceEvent> get events => List.unmodifiable(_events);

  /// Timestamp de inicio de la sesión.
  DateTime? _sessionStart;
  DateTime? get sessionStart => _sessionStart;

  /// Duración total de la sesión en segundos.
  int get totalDurationSeconds {
    if (_sessionStart == null) return 0;
    return DateTime.now().difference(_sessionStart!).inSeconds;
  }

  // -- Estado interno para detección --

  /// Contador de tiempo consecutivo por debajo del umbral (en ms).
  int _belowThresholdMs = 0;

  /// Duración requerida por debajo del umbral para detener (10 segundos).
  static const int _belowThresholdStopMs = 10000;

  /// Datos acumulados del evento actual.
  double _eventMaxDb = 0.0;
  double _eventSumDb = 0.0;
  int _eventSampleCount = 0;
  DateTime? _eventStartTime;
  String? _currentRecordingFileName;

  /// Última lectura cruda del noise meter.
  double _lastRawDb = 0.0;

  /// Contador para throttle de notifyListeners en modo pasivo.
  int _passiveSampleCount = 0;

  /// Callback para notificar cambios de estado.
  VoidCallback? onStateChanged;

  /// Callback cuando se auto-pausa por batería baja.
  VoidCallback? onAutoPausedByBattery;

  SurveillanceService({
    NoiseMeterService? noiseMeterService,
    RecordingService? recordingService,
    CalibrationService? calibrationService,
    NotificationService? notificationService,
    BatteryOptimizedListener? batteryListener,
  })  : _noiseMeterService = noiseMeterService ?? NoiseMeterService(),
        _recordingService = recordingService ?? RecordingService(),
        _calibrationService = calibrationService ?? CalibrationService(),
        _notificationService =
            notificationService ?? NotificationService.instance,
        _batteryListener =
            batteryListener ?? BatteryOptimizedListener();

  /// Inicia la vigilancia con el umbral dado.
  Future<void> start({required double threshold}) async {
    if (_state != SurveillanceState.idle) return;

    _threshold = threshold;
    _sessionStart = DateTime.now();
    _events.clear();
    _buffer.clear();
    _belowThresholdMs = 0;
    _passiveSampleCount = 0;

    // Configurar battery listener.
    _batteryListener.onSampleTick = _onSampleTick;
    _batteryListener.onAutoPause = _onAutoPause;

    // Iniciar escucha del micrófono.
    _noiseMeterService.start();
    _noiseSubscription = _noiseMeterService.noiseStream.listen(
      _onNoiseReading,
      onError: _onNoiseError,
    );

    _state = SurveillanceState.listening;

    // Iniciar muestreo adaptativo via battery listener.
    await _batteryListener.start(threshold: threshold);

    onStateChanged?.call();
  }

  /// Detiene la vigilancia y retorna los eventos detectados.
  Future<List<SurveillanceEvent>> stop() async {
    if (_state == SurveillanceState.idle) return [];

    // Si estamos grabando, detener la grabación primero.
    if (_state == SurveillanceState.recording) {
      await _stopCurrentRecording();
    }

    _batteryListener.stop();

    _noiseSubscription?.cancel();
    _noiseSubscription = null;
    _noiseMeterService.stop();

    _state = SurveillanceState.idle;
    onStateChanged?.call();

    return List.unmodifiable(_events);
  }

  /// Callback de lectura del noise meter.
  void _onNoiseReading(NoiseReading reading) {
    final offset = _calibrationService.offset;
    _lastRawDb = (reading.meanDecibel + offset).clamp(
      AudioConstants.minDb,
      AudioConstants.maxDb,
    );
  }

  /// Callback de error del noise meter.
  void _onNoiseError(Object error) {
    debugPrint('SurveillanceService: NoiseMeter error: $error');
  }

  /// Callback del timer de muestreo adaptativo.
  void _onSampleTick(int intervalMs) {
    _processSample(intervalMs);
  }

  /// Callback de auto-pause por batería baja.
  void _onAutoPause() {
    if (_state == SurveillanceState.recording) {
      _stopCurrentRecording();
    }
    _state = SurveillanceState.pausedLowBattery;
    onAutoPausedByBattery?.call();
    onStateChanged?.call();
  }

  /// Procesa una muestra de dB según el estado actual.
  void _processSample(int intervalMs) {
    _currentDb = _lastRawDb;
    if (_currentDb <= 0) return;

    final now = DateTime.now();

    // En modo pasivo, solo procesar último sample (no buffer completo).
    if (_batteryListener.mode == SamplingMode.passive) {
      _passiveSampleCount++;
      // Solo notificar cada 2 samples en pasivo (cada 1s en vez de 500ms).
      final shouldNotify = _passiveSampleCount % 2 == 0;

      // Notificar al battery listener para transiciones.
      _batteryListener.onDbReading(_currentDb);

      if (_currentDb >= _threshold) {
        _startRecording(now);
        return;
      }

      if (shouldNotify) {
        onStateChanged?.call();
      }
      return;
    }

    // En modo alerta o recording, procesar normalmente con buffer.
    _buffer.addLast(_DbSample(timestamp: now, db: _currentDb));
    while (_buffer.length > _bufferCapacity) {
      _buffer.removeFirst();
    }

    // Notificar al battery listener para transiciones.
    _batteryListener.onDbReading(_currentDb);

    switch (_state) {
      case SurveillanceState.listening:
        _processListeningSample(now);
        break;
      case SurveillanceState.recording:
        _processRecordingSample(now, intervalMs);
        break;
      case SurveillanceState.idle:
      case SurveillanceState.pausedLowBattery:
        break;
    }

    onStateChanged?.call();
  }

  /// Procesa muestra en modo escucha pasiva.
  void _processListeningSample(DateTime now) {
    if (_currentDb >= _threshold) {
      // Pico detectado: iniciar grabación.
      _startRecording(now);
    }
  }

  /// Procesa muestra en modo grabación activa.
  void _processRecordingSample(DateTime now, int intervalMs) {
    // Acumular estadísticas del evento.
    _eventMaxDb = math.max(_eventMaxDb, _currentDb);
    _eventSumDb += _currentDb;
    _eventSampleCount++;

    if (_currentDb < _threshold) {
      // Por debajo del umbral: acumular tiempo.
      _belowThresholdMs += intervalMs;

      if (_belowThresholdMs >= _belowThresholdStopMs) {
        // 10 segundos consecutivos por debajo: detener.
        _stopCurrentRecording();
      }
    } else {
      // Vuelve a superar umbral: resetear contador.
      _belowThresholdMs = 0;
    }
  }

  /// Inicia una grabación automática por pico detectado.
  Future<void> _startRecording(DateTime triggerTime) async {
    try {
      _state = SurveillanceState.recording;
      _belowThresholdMs = 0;
      _eventMaxDb = _currentDb;
      _eventSumDb = _currentDb;
      _eventSampleCount = 1;
      _eventStartTime = triggerTime;
      _passiveSampleCount = 0;

      // Cambiar a muestreo activo via battery listener.
      _batteryListener.enterRecordingMode();

      // Iniciar grabación de audio.
      final uuid = const Uuid().v4();
      _currentRecordingFileName = 'dblog_surveillance_$uuid.m4a';
      await _recordingService.startRecording(_currentRecordingFileName!);

      onStateChanged?.call();
    } catch (e) {
      debugPrint('SurveillanceService: error iniciando grabación: $e');
      // Volver a modo escucha si falla la grabación.
      _state = SurveillanceState.listening;
      _batteryListener.exitRecordingMode();
    }
  }

  /// Detiene la grabación actual y crea el evento.
  Future<void> _stopCurrentRecording() async {
    try {
      await _recordingService.stopRecording();

      final avgDb = _eventSampleCount > 0
          ? _eventSumDb / _eventSampleCount
          : _currentDb;

      final recordingId = _currentRecordingFileName
          ?.replaceAll('.m4a', '')
          .replaceAll('dblog_surveillance_', '');

      final event = SurveillanceEvent(
        id: const Uuid().v4(),
        startTime: _eventStartTime ?? DateTime.now(),
        endTime: DateTime.now(),
        maxDb: _eventMaxDb,
        avgDb: avgDb,
        recordingId: recordingId,
      );

      _events.add(event);

      // Enviar notificación local del evento detectado.
      _notificationService.showNoiseEventNotification(event);
    } catch (e) {
      debugPrint('SurveillanceService: error deteniendo grabación: $e');
    }

    // Volver a modo escucha pasiva.
    _state = SurveillanceState.listening;
    _belowThresholdMs = 0;
    _eventMaxDb = 0.0;
    _eventSumDb = 0.0;
    _eventSampleCount = 0;
    _eventStartTime = null;
    _currentRecordingFileName = null;
    _passiveSampleCount = 0;

    // Volver a muestreo adaptativo via battery listener.
    _batteryListener.exitRecordingMode();

    onStateChanged?.call();
  }

  /// Libera recursos.
  void dispose() {
    _batteryListener.dispose();
    _noiseSubscription?.cancel();
    _noiseMeterService.dispose();
    _recordingService.dispose();
  }
}
