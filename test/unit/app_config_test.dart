import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eva_mobile/core/config/app_config.dart';

/// Unit tests for AppConfig (v2 - failover-based)
/// The old test file expected throws for missing env vars,
/// but AppConfig now uses defaults with failover.
void main() {
  setUp(() {
    dotenv.testLoad(fileInput: '');
  });

  group('AppConfig - Default Servers', () {
    test('primary server uses default GCP host', () {
      final primary = AppConfig.primary;
      expect(primary.label, 'GCP');
      expect(primary.apiBaseUrl, contains('35.232.177.102'));
    });

    test('fallback server uses default DigitalOcean host', () {
      final fallback = AppConfig.fallback;
      expect(fallback.label, 'DigitalOcean');
      expect(fallback.apiBaseUrl, contains('104.248.219.200'));
    });

    test('apiBaseUrl returns active server URL', () {
      AppConfig.active = AppConfig.primary;
      expect(AppConfig.apiBaseUrl, AppConfig.primary.apiBaseUrl);
    });

    test('wsUrl returns active server URL', () {
      AppConfig.active = AppConfig.primary;
      expect(AppConfig.wsUrl, AppConfig.primary.wsUrl);
    });
  });

  group('AppConfig - Security', () {
    test('uses HTTPS by default', () {
      final primary = AppConfig.primary;
      expect(primary.apiBaseUrl, startsWith('https://'));
      expect(primary.wsUrl, startsWith('wss://'));
    });

    test('ALLOW_INSECURE=true uses HTTP', () {
      dotenv.testLoad(fileInput: 'ALLOW_INSECURE=true');
      final primary = AppConfig.primary;
      expect(primary.apiBaseUrl, startsWith('http://'));
      expect(primary.wsUrl, startsWith('ws://'));
    });
  });

  group('AppConfig - Constants', () {
    test('Should have correct app metadata', () {
      expect(AppConfig.appName, 'EVA Mobile');
      expect(AppConfig.appVersion, '1.0.0');
    });
  });
}
