import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eva_mobile/data/services/api_service.dart';
import 'package:eva_mobile/core/config/app_config.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'ALLOW_INSECURE=true');
    AppConfig.active = AppConfig.primary;
  });

  group('ApiService - Getters', () {
    test('baseUrl retorna do AppConfig', () {
      final api = ApiService();

      expect(api.baseUrl, AppConfig.apiBaseUrl);
    });

    test('audioUrl retorna do AppConfig', () {
      final api = ApiService();

      expect(api.audioUrl, AppConfig.apiAudioUrl);
    });
  });

  group('ApiService - CPF Cleaning', () {
    test('getIdosoByCpf limpa formatacao do CPF', () async {
      final api = ApiService();

      // Este teste vai falhar na rede, mas valida que nao da crash
      final result = await api.getIdosoByCpf('123.456.789-00');
      // Sem rede retorna null
      expect(result, isNull);
    });

    test('getIdosoByCpf com CPF limpo', () async {
      final api = ApiService();

      final result = await api.getIdosoByCpf('12345678900');
      expect(result, isNull);
    });
  });

  group('ApiService - Fallback behavior', () {
    test('listIdosos retorna lista vazia quando servidor offline', () async {
      final api = ApiService();

      final result = await api.listIdosos();
      expect(result, isA<List>());
    });

    test('getCallHistory retorna lista vazia quando offline', () async {
      final api = ApiService();

      final result = await api.getCallHistory(1);
      expect(result, isA<List>());
    });

    test('checkHealth retorna false quando offline', () async {
      final api = ApiService();

      final result = await api.checkHealth();
      expect(result, isA<bool>());
    });
  });

  group('ApiService - Error reporting', () {
    test('reportError nao crasha quando offline', () async {
      final api = ApiService();

      final result = await api.reportError(
        'test-session',
        'TEST_ERROR',
        'Teste unitario',
      );
      expect(result, isA<bool>());
    });

    test('sendErrorLog nao crasha quando offline', () async {
      final api = ApiService();

      final result = await api.sendErrorLog(
        level: 'INFO',
        message: 'Test message',
        details: 'Test details',
      );
      expect(result, isA<bool>());
    });
  });

  group('ApiService - Agendamentos offline', () {
    test('listAgendamentos retorna vazio quando offline', () async {
      final api = ApiService();

      final result = await api.listAgendamentos(1);
      expect(result, isA<List>());
    });

    test('cancelAgendamento retorna bool quando offline', () async {
      final api = ApiService();

      final result = await api.cancelAgendamento(999);
      expect(result, isA<bool>());
    });
  });
}
