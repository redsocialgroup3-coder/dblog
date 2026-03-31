import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Servicio que encapsula la interacción con RevenueCat SDK.
/// Gestiona inicialización, login/logout, compras y verificación de suscripciones.
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  /// API key placeholder — reemplazar con la key real de RevenueCat.
  static const String _apiKey = 'REVENUECAT_API_KEY';

  /// Entitlement ID que otorga acceso ilimitado a PDFs.
  static const String entitlementId = 'pdf_unlimited';

  /// Entitlement ID que otorga acceso a todas las funciones Pro.
  static const String proEntitlementId = 'pro';

  /// Product ID del consumible para comprar un PDF individual.
  static const String consumableProductId = 'dblog_pdf_single';

  /// Product ID de la suscripción mensual Pro.
  static const String subscriptionProductId = 'dblog_pro_monthly';

  bool _initialized = false;

  /// Inicializa el SDK de RevenueCat.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);
      final configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
      _initialized = true;
      log('RevenueCat inicializado correctamente');
    } catch (e) {
      log('Error inicializando RevenueCat: $e');
    }
  }

  /// Identifica al usuario en RevenueCat con su ID de Firebase.
  Future<void> login(String userId) async {
    try {
      await Purchases.logIn(userId);
      log('RevenueCat login: $userId');
    } catch (e) {
      log('Error en login RevenueCat: $e');
    }
  }

  /// Cierra la sesión del usuario en RevenueCat.
  Future<void> logout() async {
    try {
      await Purchases.logOut();
      log('RevenueCat logout');
    } catch (e) {
      log('Error en logout RevenueCat: $e');
    }
  }

  /// Obtiene los productos/ofertas disponibles en RevenueCat.
  Future<Offerings> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      log('Error obteniendo offerings: $e');
      rethrow;
    }
  }

  /// Compra un PDF individual como producto consumible.
  /// Retorna true si la compra fue exitosa.
  Future<bool> purchaseConsumable(StoreProduct product) async {
    try {
      await Purchases.purchaseStoreProduct(product);
      log('Compra consumible exitosa: ${product.identifier}');
      return true;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        log('Compra cancelada por el usuario');
        return false;
      }
      log('Error en compra: $e');
      rethrow;
    }
  }

  /// Verifica si el usuario actual es suscriptor con acceso ilimitado a PDFs.
  Future<bool> checkSubscription() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      log('Error verificando suscripción: $e');
      return false;
    }
  }

  /// Restaura compras anteriores del usuario.
  Future<CustomerInfo> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      log('Compras restauradas');
      return customerInfo;
    } catch (e) {
      log('Error restaurando compras: $e');
      rethrow;
    }
  }

  /// Compra la suscripción mensual Pro.
  /// Retorna true si la compra fue exitosa.
  Future<bool> purchaseSubscription(StoreProduct product) async {
    try {
      await Purchases.purchaseStoreProduct(product);
      log('Suscripción comprada: ${product.identifier}');
      return true;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        log('Suscripción cancelada por el usuario');
        return false;
      }
      log('Error en compra de suscripción: $e');
      rethrow;
    }
  }

  /// Obtiene la información de suscripción del usuario actual.
  /// Retorna un mapa con estado, fecha de expiración, etc.
  Future<SubscriptionInfo> getSubscriptionInfo() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final proEntitlement = customerInfo.entitlements.all[proEntitlementId];
      final pdfEntitlement = customerInfo.entitlements.all[entitlementId];

      // Considerar activo si tiene pro o pdf_unlimited.
      final isActive =
          (proEntitlement?.isActive ?? false) ||
          (pdfEntitlement?.isActive ?? false);

      DateTime? expirationDate;
      final expirationStr =
          proEntitlement?.expirationDate ?? pdfEntitlement?.expirationDate;
      if (expirationStr != null) {
        expirationDate = DateTime.tryParse(expirationStr);
      }

      return SubscriptionInfo(
        isActive: isActive,
        expirationDate: expirationDate,
        willRenew: proEntitlement?.willRenew ?? pdfEntitlement?.willRenew ?? false,
      );
    } catch (e) {
      log('Error obteniendo info de suscripción: $e');
      return SubscriptionInfo(isActive: false);
    }
  }

  /// Obtiene la URL de gestión de suscripciones de la store.
  /// Retorna null si no hay URL disponible.
  Future<String?> getManagementUrl() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.managementURL;
    } catch (e) {
      log('Error obteniendo URL de gestión: $e');
      return null;
    }
  }
}

/// Información de la suscripción del usuario.
class SubscriptionInfo {
  final bool isActive;
  final DateTime? expirationDate;
  final bool willRenew;

  SubscriptionInfo({
    required this.isActive,
    this.expirationDate,
    this.willRenew = false,
  });
}
