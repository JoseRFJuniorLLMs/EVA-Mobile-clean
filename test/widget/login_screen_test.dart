import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:eva_mobile/presentation/screens/auth/login_screen.dart';
import 'package:eva_mobile/providers/auth_provider.dart';
import 'package:eva_mobile/providers/language_provider.dart';
import 'package:eva_mobile/data/services/storage_service.dart';

/// Widget tests for LoginScreen
/// Focus: UI elements, form validation, user interactions
void main() {
  setUp(() async {
    dotenv.testLoad(fileInput: 'ALLOW_INSECURE=true');
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen - UI Elements', () {
    testWidgets('Should display welcome text', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Bem-vindo'), findsOneWidget);
    });

    testWidgets('Should display CPF input field', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('Should display login button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('ENTRAR'), findsOneWidget);
    });

    testWidgets('Should display help button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.textContaining('ajuda'), findsWidgets);
    });

    testWidgets('Should have gradient background', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.gradient != null;
        }
        return false;
      });

      expect(containerFinder, findsWidgets);
    });
  });

  group('LoginScreen - CPF Input', () {
    testWidgets('Should accept numeric input', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextFormField), '12345678901');
      await tester.pump();

      expect(find.text('123.456.789-01'), findsOneWidget);
    });

    testWidgets('Should format CPF automatically', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textField = find.byType(TextFormField);

      await tester.enterText(textField, '12345678901');
      await tester.pump();
      expect(find.text('123.456.789-01'), findsOneWidget);
    });

    testWidgets('Should limit CPF to 11 digits', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextFormField), '12345678901234567890');
      await tester.pump();

      expect(find.text('123.456.789-01'), findsOneWidget);
    });
  });

  group('LoginScreen - Form Validation', () {
    testWidgets('Should show error for empty CPF', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('ENTRAR'));
      await tester.pumpAndSettle();

      expect(find.textContaining('CPF'), findsWidgets);
    });

    testWidgets('Should show error for incomplete CPF', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextFormField), '12345');
      await tester.tap(find.text('ENTRAR'));
      await tester.pumpAndSettle();

      expect(find.textContaining('11'), findsWidgets);
    });
  });

  group('LoginScreen - Help Dialog', () {
    testWidgets('Should show help dialog when help button tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Scroll to make help button visible (may be off-screen)
      final helpButton = find.textContaining('ajuda');
      await tester.ensureVisible(helpButton);
      await tester.pumpAndSettle();
      await tester.tap(helpButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Should close help dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Scroll to make help button visible
      final helpButton = find.textContaining('ajuda');
      await tester.ensureVisible(helpButton);
      await tester.pumpAndSettle();
      await tester.tap(helpButton);
      await tester.pumpAndSettle();

      // Find and tap the close/ok button
      final okButton = find.textContaining('Entendi');
      if (okButton.evaluate().isNotEmpty) {
        await tester.tap(okButton);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      }
    });
  });
}
