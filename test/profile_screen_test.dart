import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eva_mobile/presentation/screens/profile/profile_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:eva_mobile/providers/auth_provider.dart';
import 'package:eva_mobile/providers/language_provider.dart';
import 'package:eva_mobile/data/services/storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('ProfileScreen has a logout button and user info', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/profile',
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ),
    ));

    expect(find.text('Meu Perfil'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
