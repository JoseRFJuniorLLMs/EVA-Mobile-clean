import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // 🔒 SECURITY: No hardcoded IPs/URLs - all URLs must come from .env
  // 🔧 DEV MODE: Set ALLOW_INSECURE=true in .env to allow HTTP/WS for testing

  static bool get _allowInsecure {
    final value = dotenv.env['ALLOW_INSECURE'];
    return value?.toLowerCase() == 'true';
  }

  static String get apiBaseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        '❌ CRITICAL: API_BASE_URL not found in .env file!\n'
        'Please create .env with: API_BASE_URL=https://your-server.com:8000/api/v1'
      );
    }
    if (!_allowInsecure && !url.startsWith('https://') && !url.startsWith('http://localhost')) {
      throw Exception(
        '❌ SECURITY: API_BASE_URL must use HTTPS in production!\n'
        'Got: $url\n'
        'Tip: Add ALLOW_INSECURE=true to .env for testing'
      );
    }
    return url;
  }

  static String get apiAudioUrl {
    final url = dotenv.env['API_AUDIO_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        '❌ CRITICAL: API_AUDIO_URL not found in .env file!\n'
        'Please create .env with: API_AUDIO_URL=https://your-server.com:8090/api/v1'
      );
    }
    if (!_allowInsecure && !url.startsWith('https://') && !url.startsWith('http://localhost')) {
      throw Exception(
        '❌ SECURITY: API_AUDIO_URL must use HTTPS in production!\n'
        'Got: $url\n'
        'Tip: Add ALLOW_INSECURE=true to .env for testing'
      );
    }
    return url;
  }

  static String get wsUrl {
    final url = dotenv.env['WS_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        '❌ CRITICAL: WS_URL not found in .env file!\n'
        'Please create .env with: WS_URL=wss://your-server.com:8090/ws/pcm'
      );
    }
    if (!_allowInsecure && !url.startsWith('wss://') && !url.startsWith('ws://localhost')) {
      throw Exception(
        '❌ SECURITY: WS_URL must use WSS (secure WebSocket) in production!\n'
        'Got: $url\n'
        'Tip: Add ALLOW_INSECURE=true to .env for testing'
      );
    }
    return url;
  }

  static const String appName = 'EVA Mobile';
  static const String appVersion = '1.0.0';
}
