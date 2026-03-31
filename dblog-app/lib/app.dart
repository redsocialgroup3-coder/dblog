import 'package:flutter/material.dart';

import 'features/meter/widgets/meter_screen.dart';
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
      home: const MeterScreen(),
    );
  }
}
