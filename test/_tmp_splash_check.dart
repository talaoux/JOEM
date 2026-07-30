import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('Splash screen renders and animates without exceptions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(tester.takeException(), isNull);
    expect(find.text('J'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);
    expect(find.text('E'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
  });
}