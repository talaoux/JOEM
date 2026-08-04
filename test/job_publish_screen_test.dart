import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joem/core/theme/app_colors.dart';
import 'package:joem/features/dashboard/presentation/pages/job_publish_screen.dart';

void main() {
  testWidgets(
    'Publier buttons always use AppColors.primary, even with no text entered',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: JobPublishScreen()),
      );

      final topButtonFinder = find.widgetWithText(TextButton, 'Publier');
      final bottomButtonFinder = find.widgetWithText(ElevatedButton, 'Publier');

      expect(topButtonFinder, findsOneWidget);
      expect(bottomButtonFinder, findsOneWidget);

      final TextButton topButton = tester.widget(topButtonFinder);
      final ElevatedButton bottomButton = tester.widget(bottomButtonFinder);

      expect(topButton.onPressed, isNotNull);
      expect(bottomButton.onPressed, isNotNull);
      expect(
        topButton.style!.backgroundColor!.resolve(<WidgetState>{}),
        AppColors.primary,
      );
      expect(
        bottomButton.style!.backgroundColor!.resolve(<WidgetState>{}),
        AppColors.primary,
      );
    },
  );
}