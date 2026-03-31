import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/auth/auth_provider.dart';
import 'core/encryption/encryption_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/legal/legal_provider.dart';
import 'core/payments/payment_provider.dart';
import 'core/payments/payment_service.dart';
import 'core/sync/sync_provider.dart';
import 'features/history/providers/history_provider.dart';
import 'features/meter/providers/meter_provider.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/recording/providers/recording_provider.dart';
import 'features/report/providers/report_provider.dart';
import 'features/surveillance/providers/surveillance_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase.
  // NOTA: Requiere google-services.json (Android) y GoogleService-Info.plist (iOS).
  // Sin estos archivos configurados, Firebase no se inicializará.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    log('Firebase no pudo inicializarse: $e');
  }

  // Inicializar RevenueCat.
  try {
    await PaymentService.instance.initialize();
  } catch (e) {
    log('RevenueCat no pudo inicializarse: $e');
  }

  // Inicializar notificaciones locales.
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    log('NotificationService no pudo inicializarse: $e');
  }

  // Inicializar servicio de cifrado local.
  try {
    await LocalEncryptionService.instance.initialize();
  } catch (e) {
    log('LocalEncryptionService no pudo inicializarse: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => MeterProvider(),
      child: Consumer<MeterProvider>(
        builder: (context, meterProvider, _) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) =>
                    RecordingProvider(meterProvider: meterProvider),
              ),
              ChangeNotifierProvider(
                create: (_) => OnboardingProvider(),
              ),
              ChangeNotifierProvider(
                create: (_) => AuthProvider(),
              ),
              ChangeNotifierProvider(
                create: (_) => SyncProvider(),
              ),
              ChangeNotifierProvider(
                create: (_) => ProfileProvider(),
              ),
              ChangeNotifierProvider(
                create: (_) => LegalProvider(),
              ),
              ChangeNotifierProvider(
                create: (_) => ReportProvider(),
              ),
              ChangeNotifierProvider(
                create: (_) => PaymentProvider(),
              ),
              ChangeNotifierProxyProvider<PaymentProvider, HistoryProvider>(
                create: (_) => HistoryProvider(),
                update: (_, paymentProvider, historyProvider) {
                  historyProvider!.setPaymentProvider(paymentProvider);
                  return historyProvider;
                },
              ),
              ChangeNotifierProxyProvider2<PaymentProvider, LegalProvider,
                  SurveillanceProvider>(
                create: (_) => SurveillanceProvider(
                  paymentProvider: PaymentProvider(),
                  legalProvider: LegalProvider(),
                ),
                update: (_, paymentProvider, legalProvider,
                    surveillanceProvider) {
                  // Recrear solo si no existe aún.
                  return surveillanceProvider ??
                      SurveillanceProvider(
                        paymentProvider: paymentProvider,
                        legalProvider: legalProvider,
                      );
                },
              ),
            ],
            child: const App(),
          );
        },
      ),
    ),
  );
}
