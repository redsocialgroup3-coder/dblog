import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      home: Consumer<OnboardingProvider>(
        builder: (context, onboarding, _) {
          if (onboarding.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (onboarding.completed) {
            return const MeterScreen();
          }
          return const OnboardingScreen();
        },
      ),
    );
  }
}
