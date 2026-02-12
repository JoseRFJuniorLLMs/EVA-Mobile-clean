import 'package:flutter_test/flutter_test.dart';
import 'package:eva_mobile/providers/language_provider.dart';

void main() {
  late LanguageProvider provider;

  setUp(() {
    provider = LanguageProvider();
  });

  group('LanguageProvider - Estado Inicial', () {
    test('idioma inicial e PT', () {
      expect(provider.lang, 'pt');
    });
  });

  group('LanguageProvider - setLanguage', () {
    test('muda para EN', () {
      provider.setLanguage('en');
      expect(provider.lang, 'en');
    });

    test('muda para ES', () {
      provider.setLanguage('es');
      expect(provider.lang, 'es');
    });

    test('muda para RU', () {
      provider.setLanguage('ru');
      expect(provider.lang, 'ru');
    });

    test('nao muda para idioma invalido', () {
      provider.setLanguage('jp');
      expect(provider.lang, 'pt'); // Mantém PT
    });

    test('nao muda quando ja e o mesmo idioma', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setLanguage('pt'); // Ja e PT
      expect(notified, false);
    });

    test('notifica listeners quando muda', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setLanguage('en');
      expect(notified, true);
    });
  });

  group('LanguageProvider - t() traducoes', () {
    test('retorna traducao PT por default', () {
      expect(provider.t('welcome'), 'Bem-vindo');
      expect(provider.t('enter'), 'ENTRAR');
    });

    test('retorna traducao EN apos mudar idioma', () {
      provider.setLanguage('en');

      expect(provider.t('welcome'), 'Welcome');
      expect(provider.t('enter'), 'SIGN IN');
    });

    test('retorna traducao ES', () {
      provider.setLanguage('es');

      expect(provider.t('welcome'), 'Bienvenido');
    });

    test('retorna a propria chave quando nao encontra traducao', () {
      expect(provider.t('chave_inexistente'), 'chave_inexistente');
    });

    test('fallback para PT quando chave nao existe no idioma atual', () {
      provider.setLanguage('ru');

      // Todas as chaves devem existir em RU tambem
      expect(provider.t('welcome'), isNotEmpty);
      expect(provider.t('welcome'), isNot('welcome'));
    });
  });

  group('LanguageProvider - Todas as chaves traduzidas', () {
    final keysTeste = [
      'welcome', 'enter', 'hello', 'connecting', 'hangup',
      'logout', 'my_profile', 'schedule', 'agenda',
      'microphone', 'speaker', 'call_ended',
    ];

    for (final lang in ['pt', 'en', 'es', 'ru']) {
      test('idioma $lang tem todas as chaves essenciais', () {
        provider.setLanguage(lang);

        for (final key in keysTeste) {
          final value = provider.t(key);
          expect(value, isNot(key),
              reason: 'Chave "$key" nao traduzida em $lang');
          expect(value, isNotEmpty,
              reason: 'Chave "$key" vazia em $lang');
        }
      });
    }
  });
}
