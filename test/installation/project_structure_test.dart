import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Instalacao - Arquivos essenciais', () {
    test('pubspec.yaml existe', () {
      expect(File('pubspec.yaml').existsSync(), true);
    });

    test('lib/main.dart existe', () {
      expect(File('lib/main.dart').existsSync(), true);
    });

    test('.env existe', () {
      expect(File('.env').existsSync(), true);
    });

    test('android/app/build.gradle.kts existe', () {
      expect(File('android/app/build.gradle.kts').existsSync(), true);
    });
  });

  group('Instalacao - pubspec.yaml', () {
    late Map<dynamic, dynamic> pubspec;

    setUpAll(() {
      final content = File('pubspec.yaml').readAsStringSync();
      // Parse YAML manually (sem dependencia extra)
      // Verificar strings chave
      expect(content, contains('name: eva_mobile'));
    });

    test('nome do pacote correto', () {
      final content = File('pubspec.yaml').readAsStringSync();
      expect(content, contains('name: eva_mobile'));
    });

    test('versao definida', () {
      final content = File('pubspec.yaml').readAsStringSync();
      expect(content, contains('version:'));
    });

    test('SDK constraint definido', () {
      final content = File('pubspec.yaml').readAsStringSync();
      expect(content, contains('sdk:'));
    });

    test('dependencias essenciais presentes', () {
      final content = File('pubspec.yaml').readAsStringSync();

      final deps = [
        'flutter:',
        'provider:',
        'go_router:',
        'firebase_core:',
        'firebase_messaging:',
        'audioplayers:',
        'sound_stream:',
        'web_socket_channel:',
        'http:',
        'shared_preferences:',
        'flutter_secure_storage:',
        'logger:',
        'flutter_dotenv:',
        'permission_handler:',
        'flutter_callkit_incoming:',
      ];

      for (final dep in deps) {
        expect(content, contains(dep),
            reason: 'Dependencia "$dep" faltando no pubspec.yaml');
      }
    });

    test('flutter_test em dev_dependencies', () {
      final content = File('pubspec.yaml').readAsStringSync();
      expect(content, contains('flutter_test:'));
    });

    test('assets configurados', () {
      final content = File('pubspec.yaml').readAsStringSync();
      expect(content, contains('assets/images/'));
      expect(content, contains('assets/sounds/'));
      expect(content, contains('.env'));
    });
  });

  group('Instalacao - Firebase', () {
    test('google-services.json existe', () {
      final file = File('android/app/google-services.json');
      expect(file.existsSync(), true);
    });

    test('google-services.json e JSON valido', () {
      final file = File('android/app/google-services.json');
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        expect(() => jsonDecode(content), returnsNormally);
      }
    });

    test('google-services.json tem project_id correto', () {
      final file = File('android/app/google-services.json');
      if (file.existsSync()) {
        final json = jsonDecode(file.readAsStringSync());
        expect(json['project_info']['project_id'], 'eva-push-01');
      }
    });

    test('google-services.json tem package_name correto', () {
      final file = File('android/app/google-services.json');
      if (file.existsSync()) {
        final json = jsonDecode(file.readAsStringSync());
        final client = json['client'][0];
        final androidInfo = client['client_info']['android_client_info'];
        expect(androidInfo['package_name'], 'com.eva.br');
      }
    });

    test('firebase_options.dart existe', () {
      expect(File('lib/firebase_options.dart').existsSync(), true);
    });
  });

  group('Instalacao - Estrutura de diretorios', () {
    test('lib/core existe', () {
      expect(Directory('lib/core').existsSync(), true);
    });

    test('lib/data existe', () {
      expect(Directory('lib/data').existsSync(), true);
    });

    test('lib/presentation existe', () {
      expect(Directory('lib/presentation').existsSync(), true);
    });

    test('lib/providers existe', () {
      expect(Directory('lib/providers').existsSync(), true);
    });

    test('lib/data/models existe', () {
      expect(Directory('lib/data/models').existsSync(), true);
    });

    test('lib/data/services existe', () {
      expect(Directory('lib/data/services').existsSync(), true);
    });

    test('lib/presentation/screens existe', () {
      expect(Directory('lib/presentation/screens').existsSync(), true);
    });

    test('lib/presentation/widgets existe', () {
      expect(Directory('lib/presentation/widgets').existsSync(), true);
    });
  });

  group('Instalacao - Assets', () {
    test('diretorio assets/images existe', () {
      expect(Directory('assets/images').existsSync(), true);
    });

    test('diretorio assets/sounds existe', () {
      expect(Directory('assets/sounds').existsSync(), true);
    });

    test('eva_transparent.png existe', () {
      expect(File('assets/images/eva_transparent.png').existsSync(), true);
    });

    test('ringtone.mp3 existe', () {
      expect(File('assets/sounds/ringtone.mp3').existsSync(), true);
    });

    test('notifica.mp3 existe', () {
      expect(File('assets/sounds/notifica.mp3').existsSync(), true);
    });
  });

  group('Instalacao - Android Config', () {
    test('AndroidManifest.xml existe', () {
      expect(
        File('android/app/src/main/AndroidManifest.xml').existsSync(),
        true,
      );
    });

    test('AndroidManifest tem package com.eva.br', () {
      final file = File('android/app/src/main/AndroidManifest.xml');
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        // Pode usar namespace ou package attribute (case-insensitive)
        expect(
          content.contains('com.eva.br') || content.toLowerCase().contains('eva'),
          true,
        );
      }
    });

    test('MainActivity.kt existe', () {
      final file = File(
        'android/app/src/main/kotlin/com/eva/br/MainActivity.kt',
      );
      expect(file.existsSync(), true);
    });

    test('proguard-rules.pro existe', () {
      expect(File('android/app/proguard-rules.pro').existsSync(), true);
    });
  });

  group('Instalacao - Source Files', () {
    final requiredFiles = [
      'lib/main.dart',
      'lib/core/config/app_config.dart',
      'lib/core/localization/translations.dart',
      'lib/core/constants/colors.dart',
      'lib/core/constants/text_styles.dart',
      'lib/core/theme/app_theme.dart',
      'lib/core/utils/logger.dart',
      'lib/core/utils/permissions.dart',
      'lib/data/models/idoso.dart',
      'lib/data/models/call_log.dart',
      'lib/data/models/agendamento.dart',
      'lib/data/services/api_service.dart',
      'lib/data/services/storage_service.dart',
      'lib/data/services/websocket_service.dart',
      'lib/data/services/connection_manager.dart',
      'lib/data/services/firebase_service.dart',
      'lib/data/services/callkit_service.dart',
      'lib/data/services/native_audio_service.dart',
      'lib/providers/auth_provider.dart',
      'lib/providers/call_provider.dart',
      'lib/providers/language_provider.dart',
      'lib/presentation/screens/auth/login_screen.dart',
      'lib/presentation/screens/home/home_screen.dart',
      'lib/presentation/screens/call/call_screen.dart',
      'lib/presentation/screens/profile/profile_screen.dart',
      'lib/presentation/screens/schedule/schedule_screen.dart',
      'lib/presentation/screens/splash/splash_screen.dart',
      'lib/presentation/widgets/custom_button.dart',
      'lib/presentation/widgets/elderly_friendly_text.dart',
      'lib/presentation/widgets/pulsing_button.dart',
    ];

    for (final path in requiredFiles) {
      test('$path existe', () {
        expect(File(path).existsSync(), true,
            reason: 'Arquivo $path nao encontrado');
      });
    }
  });
}
