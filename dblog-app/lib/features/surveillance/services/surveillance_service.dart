import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:uuid/uuid.dart';

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
/// - Modo activo (recording): muestreo cada 100ms
class SurveillanceService {
  final NoiseMeterService _noiseMeterService;
  final RecordingService _recordingService;
  final CalibrationService _calibrationService;
  final NotificationService _notificationService;

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

  /// Timer para muestreo adaptativo.
  Timer? _sampleTimer;

  /// Intervalo de muestreo pasivo (500ms para ahorrar batería).
  static const int _passiveIntervalMs = 500;

  /// Intervalo de muestreo activo (100ms durante grabación).
  static const int _activeIntervalMs = 100;

  /// Última lectura cruda del noise meter.
  double _lastRawDb = 0.0;

  /// Callback para notificar cambios de estado.
  VoidCallback? onStateChanged;

  SurveillanceService({
    NoiseMeterService? noiseMeterService,
    RecordingService? recordingService,
    CalibrationService? calibrationService,
    NotificationService? notificationService,
  })  : _noiseMeterService = noiseMeterService ?? NoiseMeterService(),
        _recordingService = recordingService ?? RecordingService(),
        _calibrationService = calibrationService ?? CalibrationService(),
        _notificationService =
            notificationService ?? NotificationService.instance;

  /// Inicia la vigilancia con el umbral dado.
  Future<void> start({required double threshold}) async {
    if (_state != SurveillanceState.idle) return;

    _threshold = threshold;
    _sessionStart = DateTime.now();
    _events.clear();
    _buffer.clear();
    _belowThresholdMs = 0;

    // Iniciar escucha del micrófono.
    _noiseMeterService.start();
    _noiseSubscription = _noiseMeterService.noiseStream.listen(
      _onNoiseReading,
      onError: _onNoiseError,
    );

    _state = SurveillanceState.listening;

    // Iniciar muestreo pasivo.
    _startSampling(_passiveIntervalMs);

    onStateChanged?.call();
  }

  /// Detiene la vigilancia y retorna los eventos detectados.
  Future<List<SurveillanceEvent>> stop() async {
    if (_state == SurveillanceState.idle) return [];

    // Si estamos grabando, detener la grabación primero.
    if (_state == SurveillanceState.recording) {
      await _stopCurrentRecording();
    }

    _sampleTimer?.cancel();
    _sampleTimer = null;

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

  /// Inicia el timer de muestreo con el intervalo dado.
  void _startSampling(int intervalMs) {
    _sampleTimer?.cancel();
    _sampleTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => _processSample(),
    );
  }

  /// Procesa una muestra de dB según el estado actual.
  void _processSample() {
    _currentDb = _lastRawDb;
    if (_currentDb <= 0) return;

    final now = DateTime.now();

    // Agregar al buffer circular.
    _buffer.addLast(_DbSample(timestamp: now, db: _currentDb));
    while (_buffer.length > _bufferCapacity) {
      _buffer.removeFirst();
    }

    switch (_state) {
      case SurveillanceState.listening:
        _processListeningSample(now);
        break;
      case SurveillanceState.recording:
        _processRecordingSample(now);
        break;
      case SurveillanceState.idle:
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
  void _processRecordingSample(DateTime now) {
    // Acumular estadísticas del evento.
    _eventMaxDb = math.max(_eventMaxDb, _currentDb);
    _eventSumDb += _currentDb;
    _eventSampleCount++;

    if (_currentDb < _threshold) {
      // Por debajo del umbral: acumular tiempo.
      _belowThresholdMs += _activeIntervalMs;

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

      // Cambiar a muestreo activo (100ms).
      _startSampling(_activeIntervalMs);

      // Iniciar grabación de audio.
      final uuid = const Uuid().v4();
      _currentRecordingFileName = 'dblog_surveillance_$uuid.m4a';
      await _recordingService.startRecording(_currentRecordingFileName!);

      onStateChanged?.call();
    } catch (e) {
      debugPrint('SurveillanceService: error iniciando grabación: $e');
      // Volver a modo escucha si falla la grabación.
      _state = SurveillanceState.listening;
      _startSampling(_passiveIntervalMs);
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

    // Cambiar a muestreo pasivo (500ms).
    _startSampling(_passiveIntervalMs);

    onStateChanged?.call();
  }

  /// Libera recursos.
  void dispose() {
    _sampleTimer?.cancel();
    _noiseSubscription?.cancel();
    _noiseMeterService.dispose();
    _recordingService.dispose();
  }
}
