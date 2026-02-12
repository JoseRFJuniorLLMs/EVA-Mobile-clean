import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eva_mobile/presentation/widgets/elderly_friendly_text.dart';

void main() {
  group('ElderlyFriendlyText', () {
    testWidgets('renderiza texto', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElderlyFriendlyText(text: 'Ola Dona Maria'),
          ),
        ),
      );

      expect(find.text('Ola Dona Maria'), findsOneWidget);
    });

    testWidgets('fontSize default e 20', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElderlyFriendlyText(text: 'Teste'),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Teste'));
      expect(text.style?.fontSize, 20);
    });

    testWidgets('fontSize customizavel', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElderlyFriendlyText(text: 'Grande', fontSize: 32),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Grande'));
      expect(text.style?.fontSize, 32);
    });

    testWidgets('fontWeight e w600 (semibold)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElderlyFriendlyText(text: 'Bold'),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Bold'));
      expect(text.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('line height e 1.5', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElderlyFriendlyText(text: 'Height'),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Height'));
      expect(text.style?.height, 1.5);
    });
  });
}
