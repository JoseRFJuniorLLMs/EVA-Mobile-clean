import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eva_mobile/data/services/websocket_service.dart';
import 'package:eva_mobile/core/config/app_config.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'ALLOW_INSECURE=true');
  });

  group('WebSocketService - Singleton', () {
    test('e singleton', () {
      final ws1 = WebSocketService();
      final ws2 = WebSocketService();

      expect(identical(ws1, ws2), true);
    });
  });

  group('WebSocketService - Estado Inicial', () {
    test('nao esta conectado inicialmente', () {
      final ws = WebSocketService();
      expect(ws.isConnected, false);
    });

    test('messages stream existe', () {
      final ws = WebSocketService();
      expect(ws.messages, isA<Stream>());
    });
  });

  group('WebSocketService - sendMessage sem conexao', () {
    test('sendMessage sem conexao nao causa crash', () {
      final ws = WebSocketService();

      // Nao deve lançar excecao
      ws.sendMessage({'type': 'ping'});
    });
  });

  group('WebSocketService - sendBytes sem conexao', () {
    test('sendBytes sem conexao nao causa crash', () {
      final ws = WebSocketService();

      // Nao deve lancar excecao
      ws.sendBytes([1, 2, 3, 4]);
    });
  });

  group('WebSocketService - Constants', () {
    test('usa URL do AppConfig.active', () {
      dotenv.testLoad(fileInput: 'ALLOW_INSECURE=true');

      AppConfig.active = AppConfig.primary;
      final wsUrl = AppConfig.wsUrl;

      expect(wsUrl, contains('ws'));
      expect(wsUrl, contains('/ws/pcm'));
    });
  });
}
