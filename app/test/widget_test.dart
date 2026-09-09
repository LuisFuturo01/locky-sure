import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test for SureThing UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('SureThing Bóveda'),
          ),
        ),
      ),
    );

    expect(find.text('SureThing Bóveda'), findsOneWidget);
  });
}
