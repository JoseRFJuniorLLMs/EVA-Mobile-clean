import 'package:flutter_test/flutter_test.dart';
import 'package:eva_mobile/core/utils/logger.dart';

void main() {
  group('AppLogger', () {
    test('log nao causa crash', () {
      // Em debug mode, deve funcionar sem erros
      AppLogger.log('Teste de log');
    });

    test('error nao causa crash', () {
      AppLogger.error('Teste de erro');
    });

    test('error com exception nao causa crash', () {
      AppLogger.error('Teste com exception', Exception('test'));
    });
  });
}
