import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/meter/providers/meter_provider.dart';
import 'features/recording/providers/recording_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => MeterProvider(),
      child: Consumer<MeterProvider>(
        builder: (context, meterProvider, _) {
          return ChangeNotifierProvider(
            create: (_) => RecordingProvider(meterProvider: meterProvider),
            child: const App(),
          );
        },
      ),
    ),
  );
}
