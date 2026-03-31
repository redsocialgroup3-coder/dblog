import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Servicio que encapsula la grabación de audio en formato AAC/M4A.
/// Almacena los archivos en el directorio de documentos de la app.
class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  /// Indica si hay una grabación en curso.
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  /// Ruta del archivo que se está grabando actualmente.
  String? _currentFilePath;
  String? get currentFilePath => _currentFilePath;

  /// Inicia la grabación de audio en formato AAC/M4A.
  /// Retorna la ruta del archivo donde se guardará.
  Future<String> startRecording(String fileName) async {
    if (_isRecording) {
      throw StateError('Ya hay una grabación en curso.');
    }

    final dir = await _getRecordingsDirectory();
    final filePath = '${dir.path}/$fileName';

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 128000,
      numChannels: 1,
    );

    await _recorder.start(config, path: filePath);
    _isRecording = true;
    _currentFilePath = filePath;

    return filePath;
  }

  /// Detiene la grabación y retorna la ruta del archivo.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;
    _currentFilePath = null;

    return path;
  }

  /// Obtiene el directorio de grabaciones, creándolo si no existe.
  Future<Directory> _getRecordingsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${appDir.path}/recordings');

    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    return recordingsDir;
  }

  /// Libera recursos del recorder.
  void dispose() {
    if (_isRecording) {
      _recorder.stop();
    }
    _recorder.dispose();
    debugPrint('RecordingService disposed');
  }
}
