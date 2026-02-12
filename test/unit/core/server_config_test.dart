import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eva_mobile/core/config/app_config.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: '');
    // Reset active server before each test
    AppConfig.active = AppConfig.primary;
  });

  group('ServerConfig', () {
    test('healthUrl extrai base antes de /api/', () {
      const config = ServerConfig(
        label: 'Test',
        apiBaseUrl: 'http://example.com:8000/api/v1',
        apiAudioUrl: 'http://example.com:8091/api/v1',
        wsUrl: 'ws://example.com:8091/ws/pcm',
      );

      expect(config.healthUrl, 'http://example.com:8000/health');
    });

    test('healthUrl adiciona /health quando nao tem /api/', () {
      const config = ServerConfig(
        label: 'NoApi',
        apiBaseUrl: 'http://example.com:8000',
        apiAudioUrl: 'http://example.com:8091',
        wsUrl: 'ws://example.com:8091/ws/pcm',
      );

      expect(config.healthUrl, 'http://example.com:8000/health');
    });

    test('toString retorna label e url', () {
      const config = ServerConfig(
        label: 'GCP',
        apiBaseUrl: 'https://api.test.com:8000/api/v1',
        apiAudioUrl: 'https://api.test.com:8091/api/v1',
        wsUrl: 'wss://api.test.com:8091/ws/pcm',
      );

      expect(config.toString(), 'GCP (https://api.test.com:8000/api/v1)');
    });
  });

  group('AppConfig - Servers', () {
    test('primary server tem defaults', () {
      dotenv.testLoad(fileInput: '');

      final primary = AppConfig.primary;

      expect(primary.label, 'GCP');
      expect(primary.apiBaseUrl, contains('35.232.177.102'));
    });

    test('fallback server tem defaults', () {
      dotenv.testLoad(fileInput: '');

      final fallback = AppConfig.fallback;

      expect(fallback.label, 'DigitalOcean');
      expect(fallback.apiBaseUrl, contains('104.248.219.200'));
    });

    test('primary usa env vars quando disponivel', () {
      dotenv.testLoad(fileInput: '''
PRIMARY_HOST=custom.host.com
PRIMARY_API_PORT=9000
PRIMARY_AUDIO_PORT=9091
''');

      final primary = AppConfig.primary;

      expect(primary.apiBaseUrl, contains('custom.host.com'));
      expect(primary.apiBaseUrl, contains('9000'));
      expect(primary.apiAudioUrl, contains('9091'));
    });

    test('fallback usa env vars quando disponivel', () {
      dotenv.testLoad(fileInput: '''
FALLBACK_HOST=fallback.host.com
FALLBACK_API_PORT=7000
FALLBACK_AUDIO_PORT=7091
''');

      final fallback = AppConfig.fallback;

      expect(fallback.apiBaseUrl, contains('fallback.host.com'));
      expect(fallback.apiBaseUrl, contains('7000'));
    });
  });

  group('AppConfig - Active Server', () {
    test('active retorna primary quando nao definido', () {
      dotenv.testLoad(fileInput: '');

      final active = AppConfig.active;

      expect(active.label, 'GCP');
    });

    test('active pode ser alterado', () {
      dotenv.testLoad(fileInput: '');

      AppConfig.active = AppConfig.fallback;

      expect(AppConfig.active.label, 'DigitalOcean');
    });

    test('hasActiveServer reflete estado', () {
      dotenv.testLoad(fileInput: '');

      // Apos set active, hasActiveServer deve ser true
      AppConfig.active = AppConfig.primary;
      expect(AppConfig.hasActiveServer, true);
    });
  });

  group('AppConfig - Convenience Getters', () {
    test('apiBaseUrl retorna do server ativo', () {
      dotenv.testLoad(fileInput: '');

      AppConfig.active = AppConfig.primary;
      expect(AppConfig.apiBaseUrl, AppConfig.primary.apiBaseUrl);

      AppConfig.active = AppConfig.fallback;
      expect(AppConfig.apiBaseUrl, AppConfig.fallback.apiBaseUrl);
    });

    test('wsUrl retorna do server ativo', () {
      dotenv.testLoad(fileInput: '');

      AppConfig.active = AppConfig.primary;
      expect(AppConfig.wsUrl, AppConfig.primary.wsUrl);
    });
  });

  group('AppConfig - Security', () {
    test('usa https por default', () {
      dotenv.testLoad(fileInput: '');

      final primary = AppConfig.primary;

      expect(primary.apiBaseUrl, startsWith('https://'));
      expect(primary.wsUrl, startsWith('wss://'));
    });

    test('ALLOW_INSECURE=true usa http', () {
      dotenv.testLoad(fileInput: 'ALLOW_INSECURE=true');

      final primary = AppConfig.primary;

      expect(primary.apiBaseUrl, startsWith('http://'));
      expect(primary.wsUrl, startsWith('ws://'));
    });

    test('ALLOW_INSECURE=false usa https', () {
      dotenv.testLoad(fileInput: 'ALLOW_INSECURE=false');

      final primary = AppConfig.primary;

      expect(primary.apiBaseUrl, startsWith('https://'));
    });
  });

  group('AppConfig - Constants', () {
    test('app metadata correto', () {
      expect(AppConfig.appName, 'EVA Mobile');
      expect(AppConfig.appVersion, '1.0.0');
    });
  });
}
