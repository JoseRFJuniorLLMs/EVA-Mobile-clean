import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eva_mobile/presentation/widgets/custom_button.dart';

void main() {
  group('CustomButton', () {
    testWidgets('renderiza texto correto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Teste',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Teste'), findsOneWidget);
    });

    testWidgets('chama onPressed ao clicar', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Clica',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Clica'));
      expect(pressed, true);
    });

    testWidgets('e um ElevatedButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Btn',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
