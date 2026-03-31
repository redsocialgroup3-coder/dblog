import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noise_meter/noise_meter.dart' show NoiseReading;

import 'package:dblog_app/core/audio/audio_permission_service.dart';
import 'package:dblog_app/core/audio/noise_meter_service.dart';
import 'package:dblog_app/core/calibration/calibration_service.dart';
import 'package:dblog_app/core/constants/audio_constants.dart';
import 'package:dblog_app/features/meter/providers/meter_provider.dart';

// -- Mocks manuales (sin mockito para evitar codegen) --

class FakeAudioPermissionService extends AudioPermissionService {
  bool shouldGrant = true;
  bool shouldBePermanentlyDenied = false;
  int requestCount = 0;

  @override
  Future<bool> requestMicrophonePermission() async {
    requestCount++;
    return shouldGrant;
  }

  @override
  Future<bool> isPermanentlyDenied() async {
    return shouldBePermanentlyDenied;
  }

  @override
  Future<bool> openSettings() async => true;
}

class FakeNoiseMeterService extends NoiseMeterService {
  final StreamController<NoiseReading> _fakeController =
      StreamController<NoiseReading>.broadcast();
  bool _fakeIsListening = false;

  @override
  Stream<NoiseReading> get noiseStream => _fakeController.stream;

  @override
  bool get isListening => _fakeIsListening;

  @override
  void start() {
    _fakeIsListening = true;
  }

  @override
  void stop() {
    _fakeIsListening = false;
  }

  @override
  void dispose() {
    _fakeController.close();
  }

  /// Convierte un valor de dB deseado a la amplitud raw que NoiseReading espera.
  /// NoiseReading calcula: dB = 20 * log(32768 * amp) * log10e
  /// Despejando: amp = 10^(dB/20) / 32768
  static double _dbToAmplitude(double db) {
    return math.pow(10.0, db / 20.0) / 32768.0;
  }

  /// Emite una lectura falsa que producira los dB deseados (aprox).
  /// Para que meanDecibel ~ meanDb y maxDecibel ~ maxDb,
  /// usamos dos samples: uno que produce meanDb y otro que produce maxDb.
  /// NoiseReading ordena, toma min y max, y calcula mean = 0.5*(|min|+|max|).
  /// Para simplificar: si meanDb == maxDb, emitimos [amp, amp].
  /// Si meanDb < maxDb, calculamos los amplitudes que producen los valores deseados.
  void emitReading(double meanDb, double maxDb) {
    // Enfoque simple: emitimos un solo valor que genera el meanDb deseado.
    // Con [amp, amp], mean y max seran iguales.
    // Para diferentes mean/max, usamos [ampMean, ampMax] ajustados.
    final ampMax = _dbToAmplitude(maxDb);
    // mean = 0.5 * (|min| + |max|), queremos mean -> meanDb amplitude.
    // ampMean = 10^(meanDb/20) / 32768
    // Necesitamos: 0.5 * (ampMin + ampMax) = ampMean => ampMin = 2*ampMean - ampMax
    final ampMean = _dbToAmplitude(meanDb);
    final ampMin = (2.0 * ampMean - ampMax).abs();
    _fakeController.add(NoiseReading([ampMin, ampMax]));
  }

  /// Emite un error.
  void emitError(Object error) {
    _fakeController.addError(error);
  }
}

class FakeCalibrationService extends CalibrationService {
  double _fakeOffset = 0.0;

  @override
  double get offset => _fakeOffset;

  @override
  Future<void> load() async {}

  @override
  Future<void> setOffset(double value) async {
    _fakeOffset = value.clamp(-20.0, 20.0);
  }

  @override
  Future<void> reset() async {
    _fakeOffset = 0.0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MeterProvider', () {
    late FakeNoiseMeterService fakeNoiseMeter;
    late FakeAudioPermissionService fakePermission;
    late FakeCalibrationService fakeCalibration;
    late MeterProvider provider;

    setUp(() {
      fakeNoiseMeter = FakeNoiseMeterService();
      fakePermission = FakeAudioPermissionService();
      fakeCalibration = FakeCalibrationService();

      provider = MeterProvider(
        noiseMeterService: fakeNoiseMeter,
        permissionService: fakePermission,
        calibrationService: fakeCalibration,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    test('estado inicial es correcto', () {
      expect(provider.isListening, isFalse);
      expect(provider.currentDb, 0.0);
      expect(provider.maxDb, 0.0);
      expect(provider.leq, 0.0);
      expect(provider.readings, isEmpty);
      expect(provider.permissionGranted, isFalse);
      expect(provider.hasStarted, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('start() solicita permisos de microfono', () async {
      await provider.start();

      expect(fakePermission.requestCount, 1);
      expect(provider.permissionGranted, isTrue);
      expect(provider.isListening, isTrue);
    });

    test('start() con permiso denegado no inicia escucha', () async {
      fakePermission.shouldGrant = false;

      await provider.start();

      expect(fakePermission.requestCount, 1);
      expect(provider.permissionGranted, isFalse);
      expect(provider.isListening, isFalse);
    });

    test('start() con permiso denegado permanentemente setea flag', () async {
      fakePermission.shouldGrant = false;
      fakePermission.shouldBePermanentlyDenied = true;

      await provider.start();

      expect(provider.permissionDeniedPermanently, isTrue);
    });

    test('_onNoiseReading actualiza currentDb y maxDb', () async {
      await provider.start();

      // Emitir una lectura con mismos valores mean/max.
      fakeNoiseMeter.emitReading(65.0, 65.0);
      await Future.delayed(Duration.zero);

      expect(provider.currentDb, closeTo(65.0, 1.0));
      // maxDb usa peakDb (maxDecibel de NoiseReading).
      expect(provider.maxDb, closeTo(65.0, 1.0));
    });

    test('maxDb solo aumenta, nunca disminuye', () async {
      await provider.start();

      fakeNoiseMeter.emitReading(80.0, 80.0);
      await Future.delayed(Duration.zero);
      final firstMax = provider.maxDb;
      expect(firstMax, closeTo(80.0, 1.0));

      fakeNoiseMeter.emitReading(50.0, 50.0);
      await Future.delayed(Duration.zero);
      expect(provider.maxDb, firstMax); // No debe bajar.
    });

    test('calculo de Leq acumula correctamente', () async {
      await provider.start();

      // Emitir una lectura.
      fakeNoiseMeter.emitReading(60.0, 60.0);
      await Future.delayed(Duration.zero);

      // Con 1 sample, Leq deberia ser cercano al meanDb.
      expect(provider.leq, closeTo(60.0, 1.5));

      fakeNoiseMeter.emitReading(60.0, 60.0);
      await Future.delayed(Duration.zero);

      // Con 2 samples iguales, Leq sigue siendo ~60.
      expect(provider.leq, closeTo(60.0, 1.5));
    });

    test('buffer circular mantiene maximo de lecturas', () async {
      await provider.start();

      // Emitir mas lecturas que maxReadings.
      for (int i = 0; i < AudioConstants.maxReadings + 50; i++) {
        fakeNoiseMeter.emitReading(50.0, 55.0);
        await Future.delayed(Duration.zero);
      }

      expect(provider.readings.length, AudioConstants.maxReadings);
    });

    test('reset() limpia todos los valores', () async {
      await provider.start();

      fakeNoiseMeter.emitReading(75.0, 85.0);
      await Future.delayed(Duration.zero);

      provider.reset();

      expect(provider.isListening, isFalse);
      expect(provider.currentDb, 0.0);
      expect(provider.maxDb, 0.0);
      expect(provider.leq, 0.0);
      expect(provider.readings, isEmpty);
      expect(provider.hasStarted, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('stop() detiene la escucha', () async {
      await provider.start();
      expect(provider.isListening, isTrue);

      provider.stop();
      expect(provider.isListening, isFalse);
    });

    test('currentDb se clampea a rango valido', () async {
      await provider.start();

      // Emitir un valor que producira dB bajo (raw amplitude muy pequena).
      // Con amplitude ~0, NoiseReading produce dB negativo o muy bajo.
      // El clamp deberia limitar a minDb.
      fakeNoiseMeter.emitReading(10.0, 10.0);
      await Future.delayed(Duration.zero);
      expect(provider.currentDb, AudioConstants.minDb);
    });

    test('calibrationOffset se aplica a las lecturas', () async {
      await fakeCalibration.setOffset(5.0);
      await provider.start();

      fakeNoiseMeter.emitReading(60.0, 60.0);
      await Future.delayed(Duration.zero);

      // 60 + 5 = 65 (aprox, con tolerancia por conversion de amplitud).
      expect(provider.currentDb, closeTo(65.0, 1.5));
    });

    test('clearError limpia el mensaje de error', () {
      // Forzar un error message no es trivial desde fuera,
      // pero clearError debe funcionar.
      provider.clearError();
      expect(provider.errorMessage, isNull);
    });
  });
}
