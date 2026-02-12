import 'package:flutter_test/flutter_test.dart';
import 'package:eva_mobile/core/localization/translations.dart';

void main() {
  group('AppTranslations - Idiomas disponveis', () {
    test('tem 4 idiomas', () {
      expect(AppTranslations.all.length, 4);
      expect(AppTranslations.all.containsKey('pt'), true);
      expect(AppTranslations.all.containsKey('en'), true);
      expect(AppTranslations.all.containsKey('es'), true);
      expect(AppTranslations.all.containsKey('ru'), true);
    });
  });

  group('AppTranslations - Consistencia de chaves', () {
    test('todos os idiomas tem as mesmas chaves que PT', () {
      final ptKeys = AppTranslations.all['pt']!.keys.toSet();

      for (final lang in ['en', 'es', 'ru']) {
        final langKeys = AppTranslations.all[lang]!.keys.toSet();

        final missingInLang = ptKeys.difference(langKeys);
        final extraInLang = langKeys.difference(ptKeys);

        expect(missingInLang, isEmpty,
            reason: '$lang faltando chaves: $missingInLang');
        expect(extraInLang, isEmpty,
            reason: '$lang tem chaves extras: $extraInLang');
      }
    });

    test('nenhuma traducao esta vazia', () {
      for (final entry in AppTranslations.all.entries) {
        final lang = entry.key;
        final translations = entry.value;

        for (final kv in translations.entries) {
          expect(kv.value.isNotEmpty, true,
              reason: 'Chave "${kv.key}" vazia em $lang');
        }
      }
    });
  });

  group('AppTranslations - Chaves essenciais', () {
    final essentialKeys = [
      'welcome',
      'enter',
      'hello',
      'connecting',
      'hangup',
      'logout',
      'my_profile',
      'schedule',
      'agenda',
    ];

    for (final key in essentialKeys) {
      test('chave "$key" existe em todos os idiomas', () {
        for (final lang in AppTranslations.all.keys) {
          expect(AppTranslations.all[lang]!.containsKey(key), true,
              reason: 'Chave "$key" faltando em $lang');
        }
      });
    }
  });

  group('AppTranslations - PT-BR', () {
    test('textos de login corretos', () {
      final pt = AppTranslations.all['pt']!;

      expect(pt['welcome'], 'Bem-vindo');
      expect(pt['enter'], 'ENTRAR');
      expect(pt['doc_label'], 'CPF');
      expect(pt['doc_hint'], '000.000.000-00');
    });

    test('textos de call corretos', () {
      final pt = AppTranslations.all['pt']!;

      expect(pt['connecting'], 'Conectando...');
      expect(pt['hangup'], 'Desligar');
      expect(pt['call_ended'], 'Chamada Encerrada');
    });
  });

  group('AppTranslations - EN', () {
    test('textos de login corretos', () {
      final en = AppTranslations.all['en']!;

      expect(en['welcome'], 'Welcome');
      expect(en['enter'], 'SIGN IN');
      expect(en['doc_label'], 'ID Number');
    });
  });

  group('AppTranslations - ES', () {
    test('textos de login corretos', () {
      final es = AppTranslations.all['es']!;

      expect(es['welcome'], 'Bienvenido');
      expect(es['enter'], 'ENTRAR');
      expect(es['doc_label'], 'DNI');
    });
  });
}
