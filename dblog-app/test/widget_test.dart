import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dblog_app/app.dart';
import 'package:dblog_app/features/meter/providers/meter_provider.dart';

void main() {
  testWidgets('App renders dBLog title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MeterProvider(),
        child: const App(),
      ),
    );

    expect(find.text('dBLog'), findsOneWidget);
  });
}
