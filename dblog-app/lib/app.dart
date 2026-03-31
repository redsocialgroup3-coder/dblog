import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth/auth_provider.dart';
import 'core/gdpr/consent_dialog.dart';
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
          // Mostrar consentimiento RGPD si no se ha aceptado.
          return const _ConsentGate();
        },
      ),
    );
  }
}

/// Widget que muestra el dialogo de consentimiento RGPD antes de acceder al medidor.
class _ConsentGate extends StatefulWidget {
  const _ConsentGate();

  @override
  State<_ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends State<_ConsentGate> {
  bool _consentChecked = false;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    // Esperar al siguiente frame para que el context este disponible.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ConsentDialog.showIfNeeded(context);
      if (mounted) {
        setState(() => _consentChecked = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_consentChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const MeterScreen();
  }
}
