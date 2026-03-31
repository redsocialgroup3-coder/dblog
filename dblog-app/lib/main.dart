import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/auth/auth_provider.dart';
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
                create: (_) => HistoryProvider(),
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
            ],
            child: const App(),
          );
        },
      ),
    ),
  );
}
