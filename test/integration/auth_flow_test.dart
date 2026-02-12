import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eva_mobile/data/services/storage_service.dart';

/// Integration tests for authentication flow
/// Focus: Login/logout flow, session persistence (SharedPreferences only)
/// Note: SecureStorage tests skipped - requires platform channels
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('Auth Flow - Login', () {
    test('Should complete full login flow and persist session', () async {
      const idosoId = 456;
      const nome = 'Seu Joao';
      const cpf = '987.654.321-00';
      const telefone = '(21) 91234-5678';

      final savedUser = await StorageService.saveIdosoData(
        idosoId: idosoId,
        nome: nome,
        cpf: cpf,
        telefone: telefone,
      );

      expect(savedUser, true);
      expect(StorageService.isLoggedIn(), true);
      expect(StorageService.getIdosoId(), idosoId);
      expect(StorageService.getIdosoNome(), nome);
    });
  });

  group('Auth Flow - Session Persistence', () {
    test('Should maintain session across app restarts (simulated)', () async {
      await StorageService.saveIdosoData(
        idosoId: 789,
        nome: 'Dona Rosa',
        cpf: '111.222.333-44',
        telefone: '(31) 99999-8888',
      );

      // Simulate app restart
      await StorageService.init();

      expect(StorageService.isLoggedIn(), true);
      expect(StorageService.getIdosoId(), 789);
      expect(StorageService.getIdosoNome(), 'Dona Rosa');
    });
  });

  group('Auth Flow - Logout (SharedPreferences)', () {
    test('Should clear SharedPreferences data', () async {
      await StorageService.saveIdosoData(
        idosoId: 999,
        nome: 'Test User',
        cpf: '000.000.000-00',
        telefone: '(00) 00000-0000',
      );

      expect(StorageService.isLoggedIn(), true);

      // clearAll may fail on SecureStorage in test, but SharedPrefs should clear
      await StorageService.clearAll();

      // SharedPreferences data should be cleared regardless
      expect(StorageService.getIdosoId(), null);
      expect(StorageService.getIdosoNome(), null);
      expect(StorageService.getIdosoCpf(), null);
    });

    test('Should handle logout when not logged in', () async {
      await StorageService.clearAll();
      expect(StorageService.isLoggedIn(), false);
    });
  });

  group('Auth Flow - Multiple Sessions', () {
    test('Should replace old session with new login', () async {
      await StorageService.saveIdosoData(
        idosoId: 111,
        nome: 'First User',
        cpf: '111.111.111-11',
        telefone: '(11) 11111-1111',
      );

      await StorageService.saveIdosoData(
        idosoId: 222,
        nome: 'Second User',
        cpf: '222.222.222-22',
        telefone: '(22) 22222-2222',
      );

      expect(StorageService.getIdosoId(), 222);
      expect(StorageService.getIdosoNome(), 'Second User');
      expect(StorageService.getIdosoCpf(), '222.222.222-22');
    });
  });
}
