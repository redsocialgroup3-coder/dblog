import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_service.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/payments/payment_provider.dart';
import '../models/report_request.dart';

/// ChangeNotifier que gestiona la generación y compartición de informes PDF.
class ReportProvider extends ChangeNotifier {
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String? _previewPdfPath;
  String? get previewPdfPath => _previewPdfPath;

  String? _finalPdfPath;
  String? get finalPdfPath => _finalPdfPath;

  String? _error;
  String? get error => _error;

  /// Genera una vista previa del PDF con marca de agua PREVIEW.
  Future<void> generatePreview(ReportRequest request) async {
    _isGenerating = true;
    _error = null;
    _previewPdfPath = null;
    notifyListeners();

    try {
      final bytes = await _downloadPdf('/reports/preview', request);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/dblog_preview_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(bytes);
      _previewPdfPath = file.path;
    } on ApiException catch (e) {
      log('Error generando preview: $e');
      _error = e.message;
    } catch (e) {
      log('Error generando preview: $e');
      _error = 'No se pudo generar la vista previa';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Genera el PDF final sin marca de agua (requiere pago).
  /// Recibe opcionalmente un [PaymentProvider] para verificar entitlement.
  Future<void> generateFinal(
    ReportRequest request, {
    PaymentProvider? paymentProvider,
  }) async {
    // Verificar que el usuario tiene derecho a generar el PDF.
    if (paymentProvider != null && !paymentProvider.canGeneratePdf) {
      _error = 'Debes comprar el informe o ser suscriptor para generarlo';
      notifyListeners();
      return;
    }

    _isGenerating = true;
    _error = null;
    _finalPdfPath = null;
    notifyListeners();

    try {
      final bytes = await _downloadPdf('/reports/generate', request);
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/dblog_informe_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(bytes);
      _finalPdfPath = file.path;
    } on ApiException catch (e) {
      log('Error generando PDF final: $e');
      _error = e.message;
    } catch (e) {
      log('Error generando PDF final: $e');
      _error = 'No se pudo generar el informe';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Comparte un PDF usando el share sheet nativo del sistema.
  Future<void> sharePdf(String filePath) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles([file], text: 'Informe dBLog');
    } catch (e) {
      log('Error compartiendo PDF: $e');
      _error = 'No se pudo compartir el archivo';
      notifyListeners();
    }
  }

  /// Descarga un PDF desde el endpoint especificado.
  Future<Uint8List> _downloadPdf(
    String path,
    ReportRequest request,
  ) async {
    // Usar el base URL del ApiService (localhost:8000 por defecto).
    const baseUrl = 'http://localhost:8000';
    final uri = Uri.parse('$baseUrl$path');
    final httpClient = HttpClient();

    try {
      final httpRequest = await httpClient.postUrl(uri);

      // Agregar Authorization header.
      final token = await AuthService.instance.getIdToken();
      if (token != null) {
        httpRequest.headers.set('Authorization', 'Bearer $token');
      }

      httpRequest.headers.contentType = ContentType.json;
      httpRequest.write(jsonEncode(request.toJson()));

      final response = await httpRequest.close();
      final bytes = await consolidateHttpClientResponseBytes(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return bytes;
      }

      throw ApiException(
        response.statusCode,
        'Error del servidor (${response.statusCode})',
      );
    } finally {
      httpClient.close();
    }
  }

  /// Limpia el estado.
  void clear() {
    _previewPdfPath = null;
    _finalPdfPath = null;
    _error = null;
    notifyListeners();
  }

  /// Limpia el mensaje de error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
