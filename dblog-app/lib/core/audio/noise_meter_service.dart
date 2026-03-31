import 'dart:async';

import 'package:noise_meter/noise_meter.dart';

/// Servicio que encapsula el paquete noise_meter.
/// Expone un Stream de [NoiseReading] para lecturas en tiempo real.
class NoiseMeterService {
  final NoiseMeter _noiseMeter = NoiseMeter();
  StreamSubscription<NoiseReading>? _subscription;
  final StreamController<NoiseReading> _controller =
      StreamController<NoiseReading>.broadcast();

  /// Stream de lecturas de ruido.
  Stream<NoiseReading> get noiseStream => _controller.stream;

  /// Indica si está escuchando activamente.
  bool get isListening => _subscription != null;

  /// Inicia la captura de audio.
  void start() {
    if (_subscription != null) return;
    _subscription = _noiseMeter.noise.listen(
      (NoiseReading reading) {
        if (!_controller.isClosed) {
          _controller.add(reading);
        }
      },
      onError: (Object error) {
        if (!_controller.isClosed) {
          _controller.addError(error);
        }
      },
    );
  }

  /// Detiene la captura de audio.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Libera recursos.
  void dispose() {
    stop();
    _controller.close();
  }
}
