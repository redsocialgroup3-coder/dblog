import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import '../auth/auth_service.dart';

/// Servicio HTTP base para comunicarse con el backend dBLog.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // TODO: Configurar URL real del backend en producción.
  static const String _defaultBaseUrl = 'http://localhost:8000';

  String _baseUrl = _defaultBaseUrl;
  final HttpClient _client = HttpClient();

  /// Permite configurar la base URL del backend.
  void configure({required String baseUrl}) {
    _baseUrl = baseUrl;
  }

  /// Obtiene el token de Firebase del usuario actual.
  Future<String?> _getToken() async {
    return await AuthService.instance.getIdToken();
  }

  /// Realiza una petición GET.
  Future<Map<String, dynamic>> get(String path) async {
    return _request('GET', path);
  }

  /// Realiza una petición POST.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _request('POST', path, body: body);
  }

  /// Realiza una petición PUT.
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _request('PUT', path, body: body);
  }

  /// Realiza una petición DELETE.
  Future<void> delete(String path) async {
    await _request('DELETE', path, expectBody: false);
  }

  /// Realiza una petición GET que retorna una lista.
  Future<List<dynamic>> getList(String path) async {
    final uri = Uri.parse('$_baseUrl$path');

    try {
      final request = await _client.getUrl(uri);

      final token = await _getToken();
      if (token != null) {
        request.headers.set('Authorization', 'Bearer $token');
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody.isEmpty) return [];
        return jsonDecode(responseBody) as List<dynamic>;
      }

      String detail = 'Error del servidor';
      if (responseBody.isNotEmpty) {
        try {
          final errorJson = jsonDecode(responseBody);
          detail = errorJson['detail'] ?? detail;
        } catch (_) {}
      }
      throw ApiException(response.statusCode, detail);
    } on SocketException catch (e) {
      log('Error de conexion: $e');
      throw ApiException(0, 'No se pudo conectar con el servidor');
    }
  }

  /// Sube un archivo con multipart/form-data.
  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required File file,
    required Map<String, String> fields,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');

    try {
      final request = await _client.postUrl(uri);

      final token = await _getToken();
      if (token != null) {
        request.headers.set('Authorization', 'Bearer $token');
      }

      // Construir multipart request manualmente.
      final boundary = 'boundary-${DateTime.now().millisecondsSinceEpoch}';
      request.headers.contentType =
          ContentType('multipart', 'form-data', parameters: {'boundary': boundary});

      final sb = StringBuffer();

      // Campos de texto.
      for (final entry in fields.entries) {
        sb.writeln('--$boundary');
        sb.writeln('Content-Disposition: form-data; name="${entry.key}"');
        sb.writeln();
        sb.writeln(entry.value);
      }

      // Campo archivo.
      final fileName = file.path.split('/').last;
      sb.writeln('--$boundary');
      sb.writeln(
          'Content-Disposition: form-data; name="file"; filename="$fileName"');
      sb.writeln('Content-Type: audio/mp4');
      sb.writeln();

      final fileBytes = await file.readAsBytes();
      request.write(sb.toString());
      request.add(fileBytes);
      request.write('\r\n--$boundary--\r\n');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody.isEmpty) return {};
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }

      String detail = 'Error del servidor';
      if (responseBody.isNotEmpty) {
        try {
          final errorJson = jsonDecode(responseBody);
          detail = errorJson['detail'] ?? detail;
        } catch (_) {}
      }
      throw ApiException(response.statusCode, detail);
    } on SocketException catch (e) {
      log('Error de conexion: $e');
      throw ApiException(0, 'No se pudo conectar con el servidor');
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool expectBody = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');

    try {
      final request = await _openRequest(method, uri);

      // Agregar Authorization header.
      final token = await _getToken();
      if (token != null) {
        request.headers.set('Authorization', 'Bearer $token');
      }

      // Agregar body si existe.
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!expectBody || responseBody.isEmpty) {
          return {};
        }
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }

      // Manejar errores HTTP.
      String detail = 'Error del servidor';
      if (responseBody.isNotEmpty) {
        try {
          final errorJson = jsonDecode(responseBody);
          detail = errorJson['detail'] ?? detail;
        } catch (_) {
          // El body no es JSON.
        }
      }
      throw ApiException(response.statusCode, detail);
    } on SocketException catch (e) {
      log('Error de conexion: $e');
      throw ApiException(0, 'No se pudo conectar con el servidor');
    }
  }

  Future<HttpClientRequest> _openRequest(String method, Uri uri) {
    switch (method) {
      case 'GET':
        return _client.getUrl(uri);
      case 'POST':
        return _client.postUrl(uri);
      case 'PUT':
        return _client.putUrl(uri);
      case 'DELETE':
        return _client.deleteUrl(uri);
      default:
        return _client.getUrl(uri);
    }
  }
}

/// Excepcion para errores de la API.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
