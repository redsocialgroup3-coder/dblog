import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth/auth_provider.dart';
import 'features/auth/widgets/login_screen.dart';
import 'features/meter/widgets/meter_screen.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/onboarding/widgets/onboarding_screen.dart';
import 'shared/theme/app_theme.dart';

/// Widget raíz de la aplicación dBLog.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dBLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer2<AuthProvider, OnboardingProvider>(
        builder: (context, auth, onboarding, _) {
          if (onboarding.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!onboarding.completed) {
            return const OnboardingScreen();
          }
          // Si no está autenticado, mostrar login
          if (!auth.isAuthenticated) {
            return LoginScreen(
              onSkip: () {
                // Modo offline: navegar directamente al medidor
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MeterScreen()),
                );
              },
            );
          }
          return const MeterScreen();
        },
      ),
    );
  }
}
