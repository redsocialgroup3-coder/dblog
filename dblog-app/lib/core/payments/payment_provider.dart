import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'payment_service.dart';

/// ChangeNotifier que gestiona el estado de pagos y suscripciones.
/// Expone métodos para comprar PDFs individuales y verificar entitlements.
class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService.instance;

  bool _isSubscriber = false;
  bool _hasPurchasedPdf = false;
  bool _isProcessingPurchase = false;
  String? _error;
  Offerings? _offerings;

  /// Si el usuario tiene suscripción activa (PDFs ilimitados).
  bool get isSubscriber => _isSubscriber;

  /// Si el usuario acaba de comprar un PDF individual.
  bool get hasPurchasedPdf => _hasPurchasedPdf;

  /// Si hay una compra en proceso.
  bool get isProcessingPurchase => _isProcessingPurchase;

  /// Mensaje de error de la última operación.
  String? get error => _error;

  /// Productos/ofertas disponibles en RevenueCat.
  Offerings? get offerings => _offerings;

  /// True si el usuario puede generar un PDF (suscriptor o compra individual).
  bool get canGeneratePdf => _isSubscriber || _hasPurchasedPdf;

  /// Verifica los entitlements del usuario (suscripción activa).
  Future<void> checkEntitlements() async {
    try {
      _isSubscriber = await _paymentService.checkSubscription();
      notifyListeners();
    } catch (e) {
      log('Error verificando entitlements: $e');
    }
  }

  /// Carga los productos disponibles de RevenueCat.
  Future<void> loadOfferings() async {
    try {
      _offerings = await _paymentService.getOfferings();
      notifyListeners();
    } catch (e) {
      log('Error cargando offerings: $e');
      _error = 'No se pudieron cargar los productos';
      notifyListeners();
    }
  }

  /// Compra un PDF individual como consumible.
  /// Retorna true si la compra fue exitosa.
  Future<bool> purchasePdfReport() async {
    _isProcessingPurchase = true;
    _error = null;
    notifyListeners();

    try {
      // Si es suscriptor, no necesita comprar.
      if (_isSubscriber) {
        _hasPurchasedPdf = true;
        return true;
      }

      // Obtener el producto consumible del offering actual.
      final offering = _offerings?.current;
      if (offering == null) {
        _error = 'No hay productos disponibles';
        return false;
      }

      // Buscar el paquete de PDF individual.
      final package = offering.availablePackages.firstWhere(
        (pkg) =>
            pkg.storeProduct.identifier ==
            PaymentService.consumableProductId,
        orElse: () => offering.availablePackages.first,
      );

      final success =
          await _paymentService.purchaseConsumable(package.storeProduct);

      if (success) {
        _hasPurchasedPdf = true;
        return true;
      }

      _error = 'Compra cancelada';
      return false;
    } on PlatformException catch (e) {
      log('Error en compra de PDF: $e');
      _error = 'Error al procesar el pago';
      return false;
    } catch (e) {
      log('Error inesperado en compra: $e');
      _error = 'Error inesperado al procesar el pago';
      return false;
    } finally {
      _isProcessingPurchase = false;
      notifyListeners();
    }
  }

  /// Restaura compras anteriores.
  Future<void> restorePurchases() async {
    _isProcessingPurchase = true;
    _error = null;
    notifyListeners();

    try {
      final customerInfo = await _paymentService.restorePurchases();
      _isSubscriber =
          customerInfo.entitlements.all[PaymentService.entitlementId]?.isActive ??
              false;
    } catch (e) {
      log('Error restaurando compras: $e');
      _error = 'No se pudieron restaurar las compras';
    } finally {
      _isProcessingPurchase = false;
      notifyListeners();
    }
  }

  /// Resetea el estado de compra individual (tras generar el PDF).
  void resetPurchase() {
    _hasPurchasedPdf = false;
    notifyListeners();
  }

  /// Limpia el mensaje de error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
