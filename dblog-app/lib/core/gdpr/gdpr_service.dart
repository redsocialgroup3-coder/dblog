import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../encryption/encryption_service.dart';

/// Servicio RGPD: exportacion de datos, eliminacion de cuenta y consentimiento.
class GdprService {
  GdprService._();
  static final GdprService instance = GdprService._();

  final ApiService _api = ApiService.instance;

  // Claves de consentimiento en SharedPreferences.
  static const String consentPrivacyKey = 'gdpr_consent_privacy';
  static const String consentMicrophoneKey = 'gdpr_consent_microphone';
  static const String consentLocationKey = 'gdpr_consent_location';
  static const String consentShownKey = 'gdpr_consent_shown';

  /// Solicita la exportacion de datos del usuario (RGPD art. 20).
  /// Retorna la ruta del archivo JSON descargado.
  Future<String> requestDataExport() async {
    final data = await _api.get('/users/me/export');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/dblog_export.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );
    return file.path;
  }

  /// Elimina la cuenta y todos los datos del usuario (RGPD art. 17).
  /// Limpia tambien datos locales.
  Future<void> deleteAllData() async {
    // Eliminar en el backend.
    await _api.delete('/users/me');

    // Limpiar datos locales.
    await _clearLocalData();
  }

  /// Limpia todos los datos locales de la app.
  Future<void> _clearLocalData() async {
    // Limpiar claves de cifrado.
    await LocalEncryptionService.instance.clearKeys();

    // Limpiar shared preferences.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Eliminar archivos de grabaciones locales.
    try {
      final dir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${dir.path}/recordings');
      if (await recordingsDir.exists()) {
        await recordingsDir.delete(recursive: true);
      }
    } catch (e) {
      log('Error eliminando grabaciones locales: $e');
    }
  }

  /// Verifica si el usuario ya dio su consentimiento.
  Future<bool> hasConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(consentShownKey) ?? false;
  }

  /// Guarda el consentimiento del usuario.
  Future<void> saveConsent({
    required bool privacyAccepted,
    required bool microphoneConsent,
    required bool locationConsent,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(consentPrivacyKey, privacyAccepted);
    await prefs.setBool(consentMicrophoneKey, microphoneConsent);
    await prefs.setBool(consentLocationKey, locationConsent);
    await prefs.setBool(consentShownKey, true);
  }
}
