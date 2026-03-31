import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  DateTime? _subscriptionExpirationDate;
  bool _subscriptionWillRenew = false;

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

  /// Fecha de expiración/renovación de la suscripción.
  DateTime? get subscriptionExpirationDate => _subscriptionExpirationDate;

  /// Si la suscripción se renovará automáticamente.
  bool get subscriptionWillRenew => _subscriptionWillRenew;

  /// True si el usuario puede generar un PDF (suscriptor o compra individual).
  bool get canGeneratePdf => _isSubscriber || _hasPurchasedPdf;

  /// Verifica los entitlements del usuario (suscripción activa).
  Future<void> checkEntitlements() async {
    try {
      _isSubscriber = await _paymentService.checkSubscription();
      // También cargar info de suscripción.
      final info = await _paymentService.getSubscriptionInfo();
      _subscriptionExpirationDate = info.expirationDate;
      _subscriptionWillRenew = info.willRenew;
      if (info.isActive) _isSubscriber = true;
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

  /// Compra la suscripción mensual Pro.
  /// Retorna true si la compra fue exitosa.
  Future<bool> purchaseSubscription() async {
    _isProcessingPurchase = true;
    _error = null;
    notifyListeners();

    try {
      // Obtener el producto de suscripción del offering actual.
      final offering = _offerings?.current;
      if (offering == null) {
        _error = 'No hay productos disponibles';
        return false;
      }

      // Buscar el paquete de suscripción mensual.
      final package = offering.availablePackages.firstWhere(
        (pkg) =>
            pkg.storeProduct.identifier ==
            PaymentService.subscriptionProductId,
        orElse: () => offering.availablePackages.first,
      );

      final success =
          await _paymentService.purchaseSubscription(package.storeProduct);

      if (success) {
        _isSubscriber = true;
        // Actualizar info de suscripción tras la compra.
        final info = await _paymentService.getSubscriptionInfo();
        _subscriptionExpirationDate = info.expirationDate;
        _subscriptionWillRenew = info.willRenew;
        return true;
      }

      _error = 'Compra cancelada';
      return false;
    } on PlatformException catch (e) {
      log('Error en compra de suscripción: $e');
      _error = 'Error al procesar el pago';
      return false;
    } catch (e) {
      log('Error inesperado en suscripción: $e');
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
      // Verificar también el entitlement pro.
      if (customerInfo.entitlements.all[PaymentService.proEntitlementId]?.isActive ??
          false) {
        _isSubscriber = true;
      }
      // Actualizar info de suscripción.
      final info = await _paymentService.getSubscriptionInfo();
      _subscriptionExpirationDate = info.expirationDate;
      _subscriptionWillRenew = info.willRenew;
    } catch (e) {
      log('Error restaurando compras: $e');
      _error = 'No se pudieron restaurar las compras';
    } finally {
      _isProcessingPurchase = false;
      notifyListeners();
    }
  }

  /// Abre la URL de gestión de suscripciones de la store.
  Future<void> openManagementUrl() async {
    try {
      final url = await _paymentService.getManagementUrl();
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      log('Error abriendo gestión de suscripciones: $e');
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
