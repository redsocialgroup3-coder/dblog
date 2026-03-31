import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de cifrado local para archivos de audio.
///
/// Usa AES-256-CBC para cifrar/descifrar archivos localmente.
/// La clave se genera al primer uso y se almacena en SharedPreferences.
class LocalEncryptionService {
  LocalEncryptionService._();
  static final LocalEncryptionService instance = LocalEncryptionService._();

  static const String _keyPrefKey = 'encryption_local_key';
  static const String _ivPrefKey = 'encryption_local_iv';

  Key? _key;
  IV? _iv;

  /// Inicializa el servicio, generando o cargando la clave existente.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storedKey = prefs.getString(_keyPrefKey);
    final storedIv = prefs.getString(_ivPrefKey);

    if (storedKey != null && storedIv != null) {
      _key = Key.fromBase64(storedKey);
      _iv = IV.fromBase64(storedIv);
    } else {
      _key = Key.fromSecureRandom(32);
      _iv = IV.fromSecureRandom(16);
      await prefs.setString(_keyPrefKey, _key!.base64);
      await prefs.setString(_ivPrefKey, _iv!.base64);
    }
  }

  /// Cifra bytes de un archivo.
  Uint8List encryptBytes(Uint8List data) {
    if (_key == null || _iv == null) {
      throw StateError('EncryptionService no inicializado. Llama a initialize() primero.');
    }
    final encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: _iv!);
    return encrypted.bytes;
  }

  /// Descifra bytes de un archivo.
  Uint8List decryptBytes(Uint8List encryptedData) {
    if (_key == null || _iv == null) {
      throw StateError('EncryptionService no inicializado. Llama a initialize() primero.');
    }
    final encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));
    final encrypted = Encrypted(encryptedData);
    final decrypted = encrypter.decryptBytes(encrypted, iv: _iv!);
    return Uint8List.fromList(decrypted);
  }

  /// Cifra un archivo y lo guarda con extension .enc.
  Future<File> encryptFile(File file) async {
    final bytes = await file.readAsBytes();
    final encrypted = encryptBytes(bytes);
    final encryptedFile = File('${file.path}.enc');
    await encryptedFile.writeAsBytes(encrypted);
    return encryptedFile;
  }

  /// Descifra un archivo .enc y retorna los bytes originales.
  Future<Uint8List> decryptFile(File encryptedFile) async {
    final bytes = await encryptedFile.readAsBytes();
    return decryptBytes(bytes);
  }

  /// Limpia las claves almacenadas (para eliminacion de cuenta).
  Future<void> clearKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrefKey);
    await prefs.remove(_ivPrefKey);
    _key = null;
    _iv = null;
  }
}
