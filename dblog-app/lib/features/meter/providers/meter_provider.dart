import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:noise_meter/noise_meter.dart';

import '../../../core/audio/audio_permission_service.dart';
import '../../../core/audio/noise_meter_service.dart';
import '../../../core/calibration/calibration_service.dart';
import '../../../core/constants/audio_constants.dart';
import '../models/db_reading.dart';

/// Provider principal del medidor de decibelios.
/// Gestiona estado, buffer circular de lecturas y cálculos estadísticos.
class MeterProvider extends ChangeNotifier with WidgetsBindingObserver {
  final NoiseMeterService _noiseMeterService;
  final AudioPermissionService _permissionService;
  final CalibrationService _calibrationService;

  StreamSubscription<NoiseReading>? _subscription;

  // -- Estado público --
  bool _isListening = false;
  bool get isListening => _isListening;

  double _currentDb = 0.0;
  double get currentDb => _currentDb;

  double _maxDb = 0.0;
  double get maxDb => _maxDb;

  double _leq = 0.0;
  double get leq => _leq;

  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  bool _permissionDeniedPermanently = false;
  bool get permissionDeniedPermanently => _permissionDeniedPermanently;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get hasStarted => _sessionStart != null;

  /// Buffer circular de lecturas (últimos 60 segundos).
  final List<DbReading> _readings = [];
  List<DbReading> get readings => List.unmodifiable(_readings);

  // Para el cálculo incremental de Leq.
  double _sumLinearPower = 0.0;
  int _totalSamples = 0;

  // Momento de inicio de sesión para el eje X relativo.
  DateTime? _sessionStart;
  DateTime? get sessionStart => _sessionStart;

  // Guardamos si estaba escuchando antes de ir a background.
  bool _wasListeningBeforePause = false;

  /// Servicio de calibración expuesto para el diálogo.
  CalibrationService get calibrationService => _calibrationService;

  /// Offset de calibración actual en dB.
  double get calibrationOffset => _calibrationService.offset;

  MeterProvider({
    NoiseMeterService? noiseMeterService,
    AudioPermissionService? permissionService,
    CalibrationService? calibrationService,
  })  : _noiseMeterService = noiseMeterService ?? NoiseMeterService(),
        _permissionService = permissionService ?? AudioPermissionService(),
        _calibrationService = calibrationService ?? CalibrationService() {
    WidgetsBinding.instance.addObserver(this);
    _calibrationService.load();
  }

  // -- Lifecycle --

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasListeningBeforePause = _isListening;
      if (_isListening) stop();
    } else if (state == AppLifecycleState.resumed) {
      if (_wasListeningBeforePause) start();
    }
  }

  // -- Acciones --

  /// Solicita permiso y comienza a escuchar.
  Future<void> start() async {
    if (_isListening) return;

    _permissionGranted = await _permissionService.requestMicrophonePermission();
    if (!_permissionGranted) {
      _permissionDeniedPermanently =
          await _permissionService.isPermanentlyDenied();
      notifyListeners();
      return;
    }

    _sessionStart ??= DateTime.now();
    _noiseMeterService.start();

    _subscription = _noiseMeterService.noiseStream.listen(
      _onNoiseReading,
      onError: _onNoiseError,
    );

    _isListening = true;
    notifyListeners();
  }

  /// Detiene la escucha.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _noiseMeterService.stop();
    _isListening = false;
    notifyListeners();
  }

  /// Reinicia todos los valores y el buffer.
  void reset() {
    stop();
    _currentDb = 0.0;
    _maxDb = 0.0;
    _leq = 0.0;
    _readings.clear();
    _sumLinearPower = 0.0;
    _totalSamples = 0;
    _sessionStart = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Abre la configuración del sistema para conceder permisos.
  Future<void> openAppSettings() async {
    await _permissionService.openSettings();
  }

  // -- Callbacks internos --

  /// Notifica cambios tras modificar la calibración desde el diálogo.
  void onCalibrationChanged() {
    notifyListeners();
  }

  void _onNoiseReading(NoiseReading reading) {
    final now = DateTime.now();
    final offset = _calibrationService.offset;
    // noise_meter reporta meanDecibel y maxDecibel; se aplica offset de calibración.
    final meanDb = (reading.meanDecibel + offset).clamp(
      AudioConstants.minDb,
      AudioConstants.maxDb,
    );
    final peakDb = (reading.maxDecibel + offset).clamp(
      AudioConstants.minDb,
      AudioConstants.maxDb,
    );

    _currentDb = meanDb;

    if (peakDb > _maxDb) {
      _maxDb = peakDb;
    }

    // Acumular para Leq (todos los samples de la sesión).
    _sumLinearPower += math.pow(10.0, meanDb / 10.0);
    _totalSamples++;
    _leq = 10.0 * math.log(_sumLinearPower / _totalSamples) / math.ln10;

    // Agregar al buffer y recortar.
    _readings.add(DbReading(timestamp: now, db: meanDb, peakDb: peakDb));
    _trimReadings();

    notifyListeners();
  }

  void _onNoiseError(Object error) {
    debugPrint('NoiseMeter error: $error');
    _errorMessage = 'Error al acceder al micrófono. Verifica los permisos.';
    stop();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Mantiene solo las últimas [AudioConstants.maxReadings] lecturas.
  void _trimReadings() {
    if (_readings.length > AudioConstants.maxReadings) {
      _readings.removeRange(
        0,
        _readings.length - AudioConstants.maxReadings,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _noiseMeterService.dispose();
    super.dispose();
  }
}
