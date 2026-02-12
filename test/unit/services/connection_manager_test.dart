import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eva_mobile/data/services/connection_manager.dart';
import 'package:eva_mobile/core/config/app_config.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'ALLOW_INSECURE=true');
  });

  group('ConnectionManager - Singleton', () {
    test('e singleton', () {
      final cm1 = ConnectionManager();
      final cm2 = ConnectionManager();

      expect(identical(cm1, cm2), true);
    });
  });

  group('ConnectionManager - Getters', () {
    test('isOnPrimary reflete server ativo', () {
      final cm = ConnectionManager();

      AppConfig.active = AppConfig.primary;
      expect(cm.isOnPrimary, true);
      expect(cm.isOnFallback, false);
    });

    test('isOnFallback reflete server ativo', () {
      final cm = ConnectionManager();

      AppConfig.active = AppConfig.fallback;
      expect(cm.isOnPrimary, false);
      expect(cm.isOnFallback, true);
    });

    test('activeLabel retorna label do server ativo', () {
      final cm = ConnectionManager();

      AppConfig.active = AppConfig.primary;
      expect(cm.activeLabel, 'GCP');

      AppConfig.active = AppConfig.fallback;
      expect(cm.activeLabel, 'DigitalOcean');
    });
  });

  group('ConnectionManager - dispose', () {
    test('dispose nao causa crash', () {
      final cm = ConnectionManager();

      // Nao deve lancar excecao
      cm.dispose();
    });
  });
}
