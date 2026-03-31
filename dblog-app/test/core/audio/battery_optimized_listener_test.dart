import 'package:dblog_app/core/audio/battery_optimized_listener.dart';
import 'package:dblog_app/core/constants/audio_constants.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake Battery que retorna un nivel configurable sin depender del plugin.
/// Se usa para simular distintos niveles de batería en los tests.
///
/// Nota: No se puede extender Battery directamente porque es un plugin,
/// así que inyectamos el comportamiento via el constructor del listener.

void main() {
  group('BatteryOptimizedListener - Transiciones de modo', () {
    late BatteryOptimizedListener listener;
    late List<int> tickIntervals;

    setUp(() {
      // Creamos el listener sin battery real (los tests no dependen del plugin).
      listener = BatteryOptimizedListener();
      tickIntervals = [];
      listener.onSampleTick = (intervalMs) {
        tickIntervals.add(intervalMs);
      };
    });

    tearDown(() {
      listener.dispose();
    });

    test('inicia en modo pasivo', () async {
      // No podemos llamar start() porque requiere Battery plugin real.
      // Verificamos el estado inicial.
      expect(listener.mode, equals(SamplingMode.passive));
    });

    test('transiciona de pasivo a alerta cuando dB cerca del umbral', () {
      // Simular que ya está en modo pasivo (estado inicial).
      const threshold = 65.0;
      final alertLevel =
          threshold - AudioConstants.alertThresholdOffset + 1; // 56 dB

      // Forzar el threshold internamente.
      listener.updateThreshold(threshold);

      // Enviar lectura cercana al umbral.
      listener.onDbReading(alertLevel);

      expect(listener.mode, equals(SamplingMode.alert));
    });

    test('permanece en pasivo cuando dB está lejos del umbral', () {
      const threshold = 65.0;
      listener.updateThreshold(threshold);

      // dB muy por debajo del umbral de alerta (55 - 10 = 55 es el alert).
      listener.onDbReading(40.0);

      expect(listener.mode, equals(SamplingMode.passive));
    });

    test('transiciona de alerta a pasivo tras tiempo suficiente por debajo',
        () {
      const threshold = 65.0;
      listener.updateThreshold(threshold);

      // Primero ir a modo alerta.
      listener.onDbReading(60.0); // > 55 (alertThreshold)
      expect(listener.mode, equals(SamplingMode.alert));

      // Simular lecturas por debajo durante 10 segundos.
      // A 100ms por tick, necesitamos 100 lecturas.
      for (var i = 0; i < 100; i++) {
        listener.onDbReading(40.0); // < 55 (alertThreshold)
      }

      expect(listener.mode, equals(SamplingMode.passive));
    });

    test('resetea contador de alerta cuando dB sube de nuevo', () {
      const threshold = 65.0;
      listener.updateThreshold(threshold);

      // Ir a modo alerta.
      listener.onDbReading(60.0);
      expect(listener.mode, equals(SamplingMode.alert));

      // Simular algunas lecturas bajas (no suficientes para volver a pasivo).
      for (var i = 0; i < 50; i++) {
        listener.onDbReading(40.0);
      }

      // Lectura alta resetea el contador.
      listener.onDbReading(60.0);
      expect(listener.mode, equals(SamplingMode.alert));

      // Otras 50 lecturas bajas no son suficientes (se reseteó).
      for (var i = 0; i < 50; i++) {
        listener.onDbReading(40.0);
      }

      // Todavía en alerta porque el contador se reseteó.
      expect(listener.mode, equals(SamplingMode.alert));
    });

    test('enterRecordingMode cambia a modo recording', () {
      listener.enterRecordingMode();
      expect(listener.mode, equals(SamplingMode.recording));
    });

    test('exitRecordingMode vuelve a pasivo', () {
      listener.enterRecordingMode();
      expect(listener.mode, equals(SamplingMode.recording));

      listener.exitRecordingMode();
      expect(listener.mode, equals(SamplingMode.passive));
    });

    test('no transiciona en modo recording', () {
      const threshold = 65.0;
      listener.updateThreshold(threshold);

      listener.enterRecordingMode();

      // Lecturas no cambian el modo cuando está en recording.
      listener.onDbReading(40.0);
      expect(listener.mode, equals(SamplingMode.recording));

      listener.onDbReading(60.0);
      expect(listener.mode, equals(SamplingMode.recording));
    });

    test('currentIntervalMs retorna valor correcto por modo', () {
      // Pasivo.
      expect(listener.currentIntervalMs,
          equals(AudioConstants.passiveIntervalMs));

      // Alerta.
      listener.updateThreshold(65.0);
      listener.onDbReading(60.0);
      expect(listener.mode, equals(SamplingMode.alert));
      expect(
          listener.currentIntervalMs, equals(AudioConstants.activeIntervalMs));

      // Recording.
      listener.enterRecordingMode();
      expect(
          listener.currentIntervalMs, equals(AudioConstants.activeIntervalMs));
    });

    test('inicia sin batería baja', () {
      expect(listener.isLowBattery, isFalse);
      expect(listener.isAutoPaused, isFalse);
    });
  });
}
