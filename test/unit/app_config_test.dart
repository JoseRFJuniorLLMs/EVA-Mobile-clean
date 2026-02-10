import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eva_mobile/core/config/app_config.dart';

/// Unit tests for AppConfig
/// Focus: Environment variable validation, security enforcement
void main() {
  group('AppConfig - Environment Variable Validation', () {
    test('Should throw exception when API_BASE_URL is missing', () async {
      dotenv.testLoad(fileInput: '');

      expect(
        () => AppConfig.apiBaseUrl,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('API_BASE_URL not found'),
        )),
      );
    });

    test('Should throw exception when API_AUDIO_URL is missing', () async {
      dotenv.testLoad(fileInput: '');

      expect(
        () => AppConfig.apiAudioUrl,
        throwsA(isA<Exception>()),
      );
    });

    test('Should throw exception when WS_URL is missing', () async {
      dotenv.testLoad(fileInput: '');

      expect(
        () => AppConfig.wsUrl,
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AppConfig - HTTPS Enforcement', () {
    test('Should reject HTTP URLs in production (API_BASE_URL)', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://104.248.219.200:8000/api/v1');

      expect(
        () => AppConfig.apiBaseUrl,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('must use HTTPS'),
        )),
      );
    });

    test('Should reject HTTP URLs in production (API_AUDIO_URL)', () {
      dotenv.testLoad(fileInput: 'API_AUDIO_URL=http://104.248.219.200:8090/api/v1');

      expect(
        () => AppConfig.apiAudioUrl,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('must use HTTPS'),
        )),
      );
    });

    test('Should reject WS URLs in production (WS_URL)', () {
      dotenv.testLoad(fileInput: 'WS_URL=ws://104.248.219.200:8090/ws/pcm');

      expect(
        () => AppConfig.wsUrl,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('must use WSS'),
        )),
      );
    });

    test('Should allow localhost HTTP for development (API_BASE_URL)', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:8000/api/v1');

      final url = AppConfig.apiBaseUrl;

      expect(url, 'http://localhost:8000/api/v1');
    });

    test('Should allow localhost WS for development (WS_URL)', () {
      dotenv.testLoad(fileInput: 'WS_URL=ws://localhost:8090/ws/pcm');

      final url = AppConfig.wsUrl;

      expect(url, 'ws://localhost:8090/ws/pcm');
    });
  });

  group('AppConfig - Valid Configuration', () {
    test('Should accept valid HTTPS URLs', () {
      dotenv.testLoad(fileInput: '''
API_BASE_URL=https://api.evacare.com:8000/api/v1
API_AUDIO_URL=https://api.evacare.com:8090/api/v1
WS_URL=wss://api.evacare.com:8090/ws/pcm
''');

      final apiBase = AppConfig.apiBaseUrl;
      final apiAudio = AppConfig.apiAudioUrl;
      final ws = AppConfig.wsUrl;

      expect(apiBase, 'https://api.evacare.com:8000/api/v1');
      expect(apiAudio, 'https://api.evacare.com:8090/api/v1');
      expect(ws, 'wss://api.evacare.com:8090/ws/pcm');
    });
  });

  group('AppConfig - No Hardcoded Values', () {
    test('Should have no hardcoded IPs or fallback URLs', () {
      dotenv.testLoad(fileInput: '');

      expect(() => AppConfig.apiBaseUrl, throwsException);
      expect(() => AppConfig.apiAudioUrl, throwsException);
      expect(() => AppConfig.wsUrl, throwsException);
    });
  });

  group('AppConfig - Constants', () {
    test('Should have correct app metadata', () {
      expect(AppConfig.appName, 'EVA Mobile');
      expect(AppConfig.appVersion, '1.0.0');
    });
  });
}
