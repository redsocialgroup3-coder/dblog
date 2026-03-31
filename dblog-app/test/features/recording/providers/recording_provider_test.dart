import 'package:flutter_test/flutter_test.dart';

import 'package:dblog_app/features/meter/providers/meter_provider.dart';
import 'package:dblog_app/features/recording/providers/recording_provider.dart';
import 'package:dblog_app/core/audio/audio_permission_service.dart';
import 'package:dblog_app/core/audio/noise_meter_service.dart';
import 'package:dblog_app/core/calibration/calibration_service.dart';

// -- Fakes reutilizados --

class _FakeAudioPermissionService extends AudioPermissionService {
  @override
  Future<bool> requestMicrophonePermission() async => true;

  @override
  Future<bool> isPermanentlyDenied() async => false;

  @override
  Future<bool> openSettings() async => true;
}

class _FakeNoiseMeterService extends NoiseMeterService {
  @override
  void start() {}

  @override
  void stop() {}

  @override
  void dispose() {}
}

class _FakeCalibrationService extends CalibrationService {
  @override
  double get offset => 0.0;

  @override
  Future<void> load() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecordingProvider', () {
    late MeterProvider meterProvider;
    late RecordingProvider recordingProvider;

    setUp(() {
      meterProvider = MeterProvider(
        noiseMeterService: _FakeNoiseMeterService(),
        permissionService: _FakeAudioPermissionService(),
        calibrationService: _FakeCalibrationService(),
      );

      recordingProvider = RecordingProvider(
        meterProvider: meterProvider,
      );
    });

    tearDown(() {
      recordingProvider.dispose();
      meterProvider.dispose();
    });

    test('estado inicial es idle', () {
      expect(recordingProvider.state, RecordingState.idle);
      expect(recordingProvider.isRecording, isFalse);
      expect(recordingProvider.isSaving, isFalse);
      expect(recordingProvider.lastRecording, isNull);
      expect(recordingProvider.errorMessage, isNull);
    });

    test('remainingSeconds inicial es maxDurationFree', () {
      expect(
        recordingProvider.remainingSeconds,
        RecordingProvider.maxDurationFree,
      );
    });

    test('elapsedSeconds inicial es 0', () {
      expect(recordingProvider.elapsedSeconds, 0);
    });

    test('startRecording requiere que el medidor este activo', () async {
      // meterProvider no esta escuchando.
      expect(meterProvider.isListening, isFalse);

      await recordingProvider.startRecording();

      // Debe setear error, no iniciar grabacion.
      expect(recordingProvider.state, RecordingState.idle);
      expect(recordingProvider.errorMessage, isNotNull);
      expect(
        recordingProvider.errorMessage,
        contains('medidor'),
      );
    });

    test('clearError limpia el mensaje de error', () async {
      await recordingProvider.startRecording();
      expect(recordingProvider.errorMessage, isNotNull);

      recordingProvider.clearError();
      expect(recordingProvider.errorMessage, isNull);
    });

    test('currentDb refleja el valor del meter provider', () {
      expect(recordingProvider.currentDb, meterProvider.currentDb);
    });

    test('maxDurationFree es 60 segundos', () {
      expect(RecordingProvider.maxDurationFree, 60);
    });
  });
}
