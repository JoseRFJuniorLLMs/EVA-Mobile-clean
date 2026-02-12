import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eva_mobile/data/services/storage_service.dart';

/// Unit tests for StorageService
/// Focus: SharedPreferences data persistence (non-sensitive data)
/// Note: FlutterSecureStorage tests are skipped in unit tests because
/// they require platform channels that aren't available in test environment.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('StorageService - Basic Data Persistence', () {
    test('Should save and retrieve idoso data', () async {
      const idosoId = 123;
      const nome = 'Dona Maria';
      const cpf = '123.456.789-00';
      const telefone = '(11) 98765-4321';

      final saved = await StorageService.saveIdosoData(
        idosoId: idosoId,
        nome: nome,
        cpf: cpf,
        telefone: telefone,
      );

      expect(saved, true);
      expect(StorageService.getIdosoId(), idosoId);
      expect(StorageService.getIdosoNome(), nome);
      expect(StorageService.getIdosoCpf(), cpf);
      expect(StorageService.getIdosoTelefone(), telefone);
      expect(StorageService.isLoggedIn(), true);
    });

    test('Should return null for non-existent data', () {
      final id = StorageService.getIdosoId();
      final nome = StorageService.getIdosoNome();

      expect(id, null);
      expect(nome, null);
      expect(StorageService.isLoggedIn(), false);
    });

    test('Should overwrite data on re-save', () async {
      await StorageService.saveIdosoData(
        idosoId: 1, nome: 'First', cpf: '111', telefone: '111',
      );
      await StorageService.saveIdosoData(
        idosoId: 2, nome: 'Second', cpf: '222', telefone: '222',
      );

      expect(StorageService.getIdosoId(), 2);
      expect(StorageService.getIdosoNome(), 'Second');
    });
  });

  group('StorageService - isLoggedIn', () {
    test('false before login', () {
      expect(StorageService.isLoggedIn(), false);
    });

    test('true after saveIdosoData', () async {
      await StorageService.saveIdosoData(
        idosoId: 1, nome: 'Test', cpf: '000', telefone: '999',
      );
      expect(StorageService.isLoggedIn(), true);
    });
  });

  group('StorageService - prefs getter', () {
    test('prefs is not null after init', () {
      expect(StorageService.prefs, isNotNull);
    });
  });
}
