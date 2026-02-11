import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Server endpoint configuration
class ServerConfig {
  final String label;
  final String apiBaseUrl;
  final String apiAudioUrl;
  final String wsUrl;

  const ServerConfig({
    required this.label,
    required this.apiBaseUrl,
    required this.apiAudioUrl,
    required this.wsUrl,
  });

  /// Health check URL (root of API)
  String get healthUrl {
    final base = apiBaseUrl;
    final idx = base.indexOf('/api/');
    return idx > 0 ? '${base.substring(0, idx)}/health' : '$base/health';
  }

  @override
  String toString() => '$label ($apiBaseUrl)';
}

class AppConfig {
  // Active server (set by ConnectionManager)
  static ServerConfig? _active;

  static ServerConfig get active {
    if (_active != null) return _active!;
    // Default to primary until ConnectionManager runs
    return primary;
  }

  static set active(ServerConfig config) => _active = config;

  static bool get hasActiveServer => _active != null;

  // ── Servers ──────────────────────────────────────────────

  static ServerConfig get primary {
    final host = dotenv.env['PRIMARY_HOST'] ?? '35.232.177.102';
    final apiPort = dotenv.env['PRIMARY_API_PORT'] ?? '8000';
    final audioPort = dotenv.env['PRIMARY_AUDIO_PORT'] ?? '8091';
    final scheme = _allowInsecure ? 'http' : 'https';
    final wsScheme = _allowInsecure ? 'ws' : 'wss';

    return ServerConfig(
      label: 'GCP',
      apiBaseUrl: '$scheme://$host:$apiPort/api/v1',
      apiAudioUrl: '$scheme://$host:$audioPort/api/v1',
      wsUrl: '$wsScheme://$host:$audioPort/ws/pcm',
    );
  }

  static ServerConfig get fallback {
    final host = dotenv.env['FALLBACK_HOST'] ?? '104.248.219.200';
    final apiPort = dotenv.env['FALLBACK_API_PORT'] ?? '8000';
    final audioPort = dotenv.env['FALLBACK_AUDIO_PORT'] ?? '8091';
    final scheme = _allowInsecure ? 'http' : 'https';
    final wsScheme = _allowInsecure ? 'ws' : 'wss';

    return ServerConfig(
      label: 'DigitalOcean',
      apiBaseUrl: '$scheme://$host:$apiPort/api/v1',
      apiAudioUrl: '$scheme://$host:$audioPort/api/v1',
      wsUrl: '$wsScheme://$host:$audioPort/ws/pcm',
    );
  }

  // ── Convenience getters (used by ApiService, WebSocketService) ──

  static String get apiBaseUrl => active.apiBaseUrl;
  static String get apiAudioUrl => active.apiAudioUrl;
  static String get wsUrl => active.wsUrl;

  // ── Security ─────────────────────────────────────────────

  static bool get _allowInsecure {
    final value = dotenv.env['ALLOW_INSECURE'];
    return value?.toLowerCase() == 'true';
  }

  // ── App info ─────────────────────────────────────────────

  static const String appName = 'EVA Mobile';
  static const String appVersion = '1.0.0';
}
