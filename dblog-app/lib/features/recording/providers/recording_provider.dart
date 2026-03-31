import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import '../../meter/providers/meter_provider.dart';
import '../models/recording.dart';
import '../services/location_service.dart';
import '../services/recording_service.dart';

/// Estados posibles de la grabación.
enum RecordingState {
  /// Sin actividad.
  idle,

  /// Grabando audio.
  recording,

  /// Guardando metadatos.
  saving,
}

/// Provider que gestiona el estado de la grabación de audio.
/// Observa las lecturas del [MeterProvider] durante la grabación
/// para calcular dB promedio y máximo.
class RecordingProvider extends ChangeNotifier {
  final RecordingService _recordingService;
  final LocationService _locationService;
  final MeterProvider _meterProvider;

  /// Duración máxima en tier gratuito (segundos).
  static const int maxDurationFree = 60;

  RecordingState _state = RecordingState.idle;
  RecordingState get state => _state;

  /// Segundos restantes del timer.
  int _remainingSeconds = maxDurationFree;
  int get remainingSeconds => _remainingSeconds;

  /// Segundos transcurridos de grabación.
  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  /// Último recording guardado.
  Recording? _lastRecording;
  Recording? get lastRecording => _lastRecording;

  /// Mensaje de error.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Timer para countdown.
  Timer? _countdownTimer;

  // Acumuladores de dB durante la grabación.
  final List<double> _dbReadings = [];
  double _recordingMaxDb = 0.0;

  // Listener del meter provider.
  VoidCallback? _meterListener;

  // Datos de la grabación en curso.
  String? _currentFileName;
  String? _currentFilePath;
  DateTime? _recordingStartTime;

  RecordingProvider({
    required MeterProvider meterProvider,
    RecordingService? recordingService,
    LocationService? locationService,
  })  : _meterProvider = meterProvider,
        _recordingService = recordingService ?? RecordingService(),
        _locationService = locationService ?? LocationService();

  /// Indica si se está grabando.
  bool get isRecording => _state == RecordingState.recording;

  /// Indica si se está guardando.
  bool get isSaving => _state == RecordingState.saving;

  /// dB actual durante grabación (del meter provider).
  double get currentDb => _meterProvider.currentDb;

  /// Inicia la grabación de audio.
  Future<void> startRecording() async {
    if (_state != RecordingState.idle) return;

    // Verificar que el medidor esté activo.
    if (!_meterProvider.isListening) {
      _errorMessage = 'Inicia el medidor antes de grabar.';
      notifyListeners();
      return;
    }

    try {
      _errorMessage = null;
      _state = RecordingState.recording;
      _elapsedSeconds = 0;
      _remainingSeconds = maxDurationFree;
      _dbReadings.clear();
      _recordingMaxDb = 0.0;
      _recordingStartTime = DateTime.now().toUtc();

      // Generar nombre de archivo único.
      final uuid = const Uuid().v4();
      _currentFileName = 'dblog_$uuid.m4a';

      // Iniciar grabación de audio.
      _currentFilePath = await _recordingService.startRecording(
        _currentFileName!,
      );

      // Observar lecturas del medidor.
      _meterListener = _onMeterReading;
      _meterProvider.addListener(_meterListener!);

      // Iniciar countdown timer.
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        _onTimerTick,
      );

      notifyListeners();
    } catch (e) {
      _state = RecordingState.idle;
      _errorMessage = 'Error al iniciar grabación: $e';
      debugPrint('RecordingProvider: error starting recording: $e');
      notifyListeners();
    }
  }

  /// Detiene la grabación y guarda los metadatos.
  Future<void> stopRecording() async {
    if (_state != RecordingState.recording) return;

    _state = RecordingState.saving;
    notifyListeners();

    try {
      // Detener timer y listener.
      _countdownTimer?.cancel();
      _countdownTimer = null;

      if (_meterListener != null) {
        _meterProvider.removeListener(_meterListener!);
        _meterListener = null;
      }

      // Detener grabación de audio.
      await _recordingService.stopRecording();

      // Obtener ubicación (graceful failure).
      final location = await _locationService.getCurrentLocation();

      // Calcular estadísticas de dB.
      final avgDb = _dbReadings.isEmpty
          ? 0.0
          : _dbReadings.reduce((a, b) => a + b) / _dbReadings.length;

      // Crear modelo de grabación.
      final recording = Recording(
        id: _currentFileName!.replaceAll('.m4a', '').replaceAll('dblog_', ''),
        timestamp: _recordingStartTime!,
        latitude: location.latitude,
        longitude: location.longitude,
        avgDb: avgDb,
        maxDb: _recordingMaxDb,
        durationSeconds: _elapsedSeconds,
        filePath: _currentFilePath!,
        fileName: _currentFileName!,
      );

      // Guardar metadatos en JSON.
      await _saveMetadata(recording);

      _lastRecording = recording;
      _state = RecordingState.idle;
      notifyListeners();
    } catch (e) {
      _state = RecordingState.idle;
      _errorMessage = 'Error al guardar grabación: $e';
      debugPrint('RecordingProvider: error stopping recording: $e');
      notifyListeners();
    }
  }

  /// Callback del timer cada segundo.
  void _onTimerTick(Timer timer) {
    _elapsedSeconds++;
    _remainingSeconds = maxDurationFree - _elapsedSeconds;

    if (_remainingSeconds <= 0) {
      // Límite alcanzado en tier gratuito.
      stopRecording();
      return;
    }

    notifyListeners();
  }

  /// Callback cuando el meter provider notifica nuevas lecturas.
  void _onMeterReading() {
    final db = _meterProvider.currentDb;
    if (db > 0) {
      _dbReadings.add(db);
      _recordingMaxDb = math.max(_recordingMaxDb, db);
    }
  }

  /// Guarda los metadatos de la grabación en un archivo JSON.
  Future<void> _saveMetadata(Recording recording) async {
    final jsonPath = recording.filePath.replaceAll('.m4a', '.json');
    final file = File(jsonPath);
    await file.writeAsString(recording.toJsonString());
    debugPrint('RecordingProvider: metadatos guardados en $jsonPath');
  }

  /// Limpia el mensaje de error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    if (_meterListener != null) {
      _meterProvider.removeListener(_meterListener!);
    }
    _recordingService.dispose();
    super.dispose();
  }
}
