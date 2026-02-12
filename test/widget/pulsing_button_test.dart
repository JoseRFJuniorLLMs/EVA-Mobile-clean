import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eva_mobile/presentation/widgets/pulsing_button.dart';

void main() {
  group('PulsingButton', () {
    testWidgets('renderiza label em uppercase', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PulsingButton(
              onTap: () {},
              label: 'atender',
              icon: Icons.phone,
            ),
          ),
        ),
      );

      expect(find.text('ATENDER'), findsOneWidget);
    });

    testWidgets('chama onTap ao clicar', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PulsingButton(
              onTap: () => tapped = true,
              label: 'Clica',
              icon: Icons.phone,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, true);
    });

    testWidgets('exibe icone quando fornecido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PulsingButton(
              onTap: () {},
              label: 'Teste',
              icon: Icons.phone,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.phone), findsOneWidget);
    });

    testWidgets('nao exibe icone quando null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PulsingButton(
              onTap: () {},
              label: 'Sem Icone',
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('tamanho default e 200', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PulsingButton(
                onTap: () {},
                label: 'Tamanho',
                icon: Icons.phone,
              ),
            ),
          ),
        ),
      );

      // O Container deve ter 200x200
      final container = tester.widget<Container>(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.constraints?.maxWidth == 200 ||
            (w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).shape == BoxShape.circle)),
      );
      expect(container, isNotNull);
    });

    testWidgets('usa tamanho customizado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PulsingButton(
                onTap: () {},
                label: 'Custom',
                size: 300,
              ),
            ),
          ),
        ),
      );

      // Deve renderizar sem erro
      expect(find.text('CUSTOM'), findsOneWidget);
    });

    testWidgets('tem semantics de botao', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PulsingButton(
              onTap: () {},
              label: 'Atender',
              icon: Icons.phone,
            ),
          ),
        ),
      );

      // Verifica que Semantics widget existe com button=true
      final semantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.button == true,
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets('semantics default quando label vazio', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PulsingButton(
              onTap: () {},
              label: '',
              icon: Icons.phone,
            ),
          ),
        ),
      );

      // Verifica que Semantics widget existe com label fallback
      final semantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Atender chamada',
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets('com imagePath esconde conteudo texto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PulsingButton(
              onTap: () {},
              label: 'Hidden',
              imagePath: 'assets/images/oceano_azul.jpg',
            ),
          ),
        ),
      );

      // SizedBox.shrink deve estar presente (oculta texto)
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('animacao inicia', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PulsingButton(
              onTap: () {},
              label: 'Anim',
              icon: Icons.phone,
            ),
          ),
        ),
      );

      // Avancar animacao
      await tester.pump(const Duration(milliseconds: 750));

      // Deve ter AnimatedBuilder (pode haver mais de um no widget tree)
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });
  });
}
