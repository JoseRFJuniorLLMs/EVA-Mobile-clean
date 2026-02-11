import 'dart:async';
import 'dart:convert';
import '../../core/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import 'connection_manager.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  final Logger _logger = Logger();
  final ConnectionManager _connManager = ConnectionManager();
  WebSocketChannel? _channel;
  final _messageController = StreamController<dynamic>.broadcast();

  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 10;
  static const _baseReconnectDelay = Duration(seconds: 3);

  // Reads the WS URL from AppConfig.active (changes after failover)
  String get _wsUrl => AppConfig.wsUrl;

  bool get isConnected => _channel != null;

  Stream<dynamic> get messages => _messageController.stream;

  Future<void> connect() async {
    if (_channel != null) {
      _logger.w('⚠️ WebSocket already connected');
      return;
    }

    try {
      _logger.i('🔌 Connecting to WebSocket: $_wsUrl [${AppConfig.active.label}]');
      final uri = Uri.parse(_wsUrl);
      _channel = WebSocketChannel.connect(uri);

      _logger.i('✅ WebSocket connected successfully');
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (message) {
          _messageController.add(message);
        },
        onError: (error) async {
          _logger.e('❌ WebSocket error: $error');
          _messageController.addError(error);
          await _reconnect();
        },
        onDone: () async {
          _logger.w('⚠️ WebSocket connection closed');
          _channel = null;
          await _reconnect();
        },
      );

      _startPingTimer();
    } catch (e) {
      _logger.e('❌ Error connecting to WebSocket: $e');
      _channel = null;
      rethrow;
    }
  }

  Timer? _pingTimer;

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_channel != null) {
        try {
          sendMessage({'type': 'ping'});
        } catch (e) {
          _logger.e('❌ Error sending ping: $e');
          _reconnect();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _reconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      // All attempts exhausted on current server — try failover
      _logger.w('🔄 Max reconnects reached. Attempting server failover...');
      await _connManager.failover();
      _reconnectAttempts = 0;

      // Try connecting to the new server
      try {
        await connect();
        return;
      } catch (e) {
        _logger.e('❌ Failover WS connect also failed: $e');
        _messageController.addError('All servers unreachable');
        return;
      }
    }

    _reconnectAttempts++;
    _logger.i(
      '🔄 Reconnection attempt $_reconnectAttempts/$_maxReconnectAttempts [${AppConfig.active.label}]',
    );

    _pingTimer?.cancel();
    _pingTimer = null;

    // Exponential backoff (3s, 6s, 12s, 24s, 30s max)
    final delaySeconds =
        (_baseReconnectDelay.inSeconds * (1 << (_reconnectAttempts - 1))).clamp(3, 30);
    _logger.i('⏳ Waiting ${delaySeconds}s before reconnect...');
    await Future.delayed(Duration(seconds: delaySeconds));

    try {
      if (_channel != null) {
        try {
          await _channel!.sink.close();
        } catch (_) {}
        _channel = null;
      }
      await connect();
      _reconnectAttempts = 0;
    } catch (e) {
      _logger.e('❌ Reconnection attempt $_reconnectAttempts failed: $e');
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel == null) {
      _logger.e('❌ Cannot send message: WebSocket not connected');
      _reconnect();
      return;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      _logger.i('📤 Message sent: ${message['type']}');
    } catch (e) {
      _logger.e('❌ Error sending message: $e');
      _reconnect();
    }
  }

  void sendBytes(List<int> data) {
    if (_channel == null) return;

    const int chunkSize = 4096;
    int offset = 0;
    while (offset < data.length) {
      final end = (offset + chunkSize > data.length) ? data.length : offset + chunkSize;
      final chunk = data.sublist(offset, end);
      try {
        _channel!.sink.add(chunk);
      } catch (e) {
        _logger.e('❌ Error sending bytes chunk: $e');
        _reconnect();
        break;
      }
      offset = end;
    }
  }

  Future<void> disconnect() async {
    _logger.i('🔌 Disconnecting WebSocket...');

    _pingTimer?.cancel();
    _pingTimer = null;

    if (_channel != null) {
      try {
        await _channel!.sink.close();
      } catch (e) {
        _logger.e('❌ Error closing WebSocket: $e');
      }
      _channel = null;
    }

    _logger.i('✅ WebSocket disconnected');
  }

  void dispose() {
    _logger.i('🗑️ Disposing WebSocket service...');
    disconnect();
    _messageController.close();
    _logger.i('✅ WebSocket service disposed');
  }
}
