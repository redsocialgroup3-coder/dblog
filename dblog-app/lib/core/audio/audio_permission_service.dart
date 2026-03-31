import 'package:permission_handler/permission_handler.dart';

/// Servicio para gestionar permisos de micrófono.
class AudioPermissionService {
  /// Solicita permiso de micrófono. Retorna `true` si fue concedido.
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Verifica si el permiso de micrófono ya está concedido.
  Future<bool> isMicrophoneGranted() async {
    return Permission.microphone.isGranted;
  }

  /// Verifica si el permiso fue denegado permanentemente.
  Future<bool> isPermanentlyDenied() async {
    return Permission.microphone.isPermanentlyDenied;
  }

  /// Abre la configuración de la app para que el usuario conceda permisos.
  Future<bool> openSettings() async {
    return openAppSettings();
  }
}
