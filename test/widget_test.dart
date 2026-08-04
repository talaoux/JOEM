// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:joem/main.dart';

void main() {
  testWidgets('Welcome screen loads', (WidgetTester tester) async {
    // Build our app and let the splash screen redirect to the welcome screen.
    await tester.pumpWidget(const JOEMApp());
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the welcome screen loads with its key content.
    expect(find.text('Réussissez.'), findsOneWidget);
    expect(find.text('Je suis recruteur'), findsOneWidget);
    expect(find.text('Je cherche un emploi'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
