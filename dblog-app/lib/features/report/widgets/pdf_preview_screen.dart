import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/payments/payment_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/report_request.dart';
import '../providers/report_provider.dart';

/// Pantalla de vista previa del PDF generado con marca de agua PREVIEW.
/// Permite compartir la vista previa, comprar el informe individual vía
/// RevenueCat o generarlo directamente si el usuario es suscriptor.
class PdfPreviewScreen extends StatelessWidget {
  /// Ruta al archivo PDF de vista previa.
  final String pdfPath;

  /// Datos del informe para regenerar el PDF final tras el pago.
  final ReportRequest reportRequest;

  const PdfPreviewScreen({
    super.key,
    required this.pdfPath,
    required this.reportRequest,
  });

  /// Ejecuta la compra del PDF y, si es exitosa, genera el PDF final.
  Future<void> _handlePurchaseAndGenerate(BuildContext context) async {
    final paymentProvider = context.read<PaymentProvider>();
    final reportProvider = context.read<ReportProvider>();

    final success = await paymentProvider.purchasePdfReport();

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.error ?? 'No se pudo completar la compra'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    // Compra exitosa: generar PDF final sin marca de agua.
    await reportProvider.generateFinal(reportRequest);

    if (!context.mounted) return;

    if (reportProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reportProvider.error!),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (reportProvider.finalPdfPath != null) {
      // Resetear estado de compra individual tras generar.
      paymentProvider.resetPurchase();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe generado correctamente'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final fileExists = File(pdfPath).existsSync();
    final isProcessing =
        paymentProvider.isProcessingPurchase || reportProvider.isGenerating;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista previa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartir PDF',
            onPressed: fileExists
                ? () => reportProvider.sharePdf(pdfPath)
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de vista previa.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.warning.withValues(alpha: 0.15),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_outlined,
                      color: AppTheme.warning, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'VISTA PREVIA — Contiene marca de agua',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido del PDF.
            Expanded(
              child: fileExists
                  ? _PdfPlaceholderView(pdfPath: pdfPath)
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.danger,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No se encontró el archivo PDF',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Botones de acción.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                  top: BorderSide(color: AppTheme.surfaceLight),
                ),
              ),
              child: Column(
                children: [
                  // Comprar informe o generar directamente si es suscriptor.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _handlePurchaseAndGenerate(context),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.textSecondary,
                              ),
                            )
                          : Icon(
                              paymentProvider.isSubscriber
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.shopping_cart_outlined,
                            ),
                      label: Text(
                        paymentProvider.isSubscriber
                            ? 'Generar informe'
                            : 'Comprar informe (4.99\u20AC)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Compartir vista previa.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: fileExists
                          ? () => reportProvider.sharePdf(pdfPath)
                          : null,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Compartir vista previa'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Volver.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Volver'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget placeholder para visualizar el PDF.
/// Muestra información del archivo y un icono representativo.
/// Cuando se integre un visor de PDF nativo (syncfusion o similar),
/// este widget se reemplazará por el visor real.
class _PdfPlaceholderView extends StatelessWidget {
  final String pdfPath;

  const _PdfPlaceholderView({required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    final file = File(pdfPath);
    final fileSize = file.existsSync() ? file.lengthSync() : 0;
    final fileSizeStr = fileSize > 1024 * 1024
        ? '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(fileSize / 1024).toStringAsFixed(0)} KB';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppTheme.primary,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'PDF generado correctamente',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tamaño: $fileSizeStr',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Contiene marca de agua PREVIEW',
            style: TextStyle(
              color: AppTheme.warning,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Usa el botón "Compartir" para enviar\nel PDF por email, WhatsApp o AirDrop',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
