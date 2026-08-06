import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('Splash screen renders and animates without exceptions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.text('JOEM'), findsOneWidget);
    expect(find.byType(RichText), findsWidgets);
  });
}