import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:joem/features/employer_dashboard/presentation/employer_dashboard_screen.dart';

void main() {
  testWidgets('Employer dashboard renders without exceptions (mobile width)', (tester) async {
    tester.view.physicalSize = const Size(390, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: EmployerDashboardScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Bonjour Heritiana 👋'), findsOneWidget);
    expect(find.text('Créer une offre'), findsOneWidget);
    expect(find.text('Mes offres récentes'), findsOneWidget);
    expect(find.text('Développeur Flutter'), findsWidgets);
  });

  testWidgets('Employer dashboard renders without exceptions (desktop width)', (tester) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: EmployerDashboardScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Évolution des candidatures'), findsOneWidget);
  });
}