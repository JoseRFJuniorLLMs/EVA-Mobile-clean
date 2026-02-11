import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../core/config/app_config.dart';

/// Manages server connectivity with automatic failover.
///
/// Flow: GCP (primary) → DigitalOcean (fallback)
/// Periodically rechecks primary when running on fallback.
class ConnectionManager {
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  final Logger _logger = Logger();
  Timer? _recheckTimer;
  bool _initialized = false;

  static const _healthTimeout = Duration(seconds: 5);
  static const _recheckInterval = Duration(seconds: 60);

  bool get isOnPrimary => AppConfig.active.label == AppConfig.primary.label;
  bool get isOnFallback => !isOnPrimary;
  String get activeLabel => AppConfig.active.label;

  /// Initialize: find first available server.
  /// Call once at app startup before any API/WS calls.
  Future<void> initialize() async {
    if (_initialized) return;

    _logger.i('🔍 Checking server connectivity...');

    // Try GCP first
    if (await _checkHealth(AppConfig.primary)) {
      AppConfig.active = AppConfig.primary;
      _logger.i('✅ Connected to PRIMARY: ${AppConfig.primary}');
      _initialized = true;
      return;
    }

    _logger.w('⚠️ GCP unreachable, trying DigitalOcean...');

    // Try DigitalOcean
    if (await _checkHealth(AppConfig.fallback)) {
      AppConfig.active = AppConfig.fallback;
      _logger.i('✅ Connected to FALLBACK: ${AppConfig.fallback}');
      _startRecheckTimer();
      _initialized = true;
      return;
    }

    // Both down — default to primary and hope it comes back
    _logger.e('❌ Both servers unreachable! Defaulting to GCP.');
    AppConfig.active = AppConfig.primary;
    _startRecheckTimer();
    _initialized = true;
  }

  /// Check health of a specific server config.
  Future<bool> _checkHealth(ServerConfig server) async {
    try {
      final url = Uri.parse(server.healthUrl);
      _logger.i('  → Checking ${server.label}: $url');
      final response = await http.get(url).timeout(_healthTimeout);
      return response.statusCode == 200;
    } catch (e) {
      _logger.w('  → ${server.label} failed: $e');
      return false;
    }
  }

  /// When on fallback, periodically try to switch back to primary.
  void _startRecheckTimer() {
    _recheckTimer?.cancel();
    _recheckTimer = Timer.periodic(_recheckInterval, (_) async {
      if (isOnPrimary) {
        // Already on primary, stop checking
        _recheckTimer?.cancel();
        _recheckTimer = null;
        return;
      }

      _logger.i('🔄 Rechecking GCP availability...');
      if (await _checkHealth(AppConfig.primary)) {
        AppConfig.active = AppConfig.primary;
        _logger.i('✅ Switched back to PRIMARY: ${AppConfig.primary}');
        _recheckTimer?.cancel();
        _recheckTimer = null;
      }
    });
  }

  /// Force a failover check (e.g., after repeated API errors).
  Future<ServerConfig> failover() async {
    _logger.w('🔄 Forced failover requested...');

    final other = isOnPrimary ? AppConfig.fallback : AppConfig.primary;

    if (await _checkHealth(other)) {
      AppConfig.active = other;
      _logger.i('✅ Failover to: $other');

      if (isOnFallback) {
        _startRecheckTimer();
      } else {
        _recheckTimer?.cancel();
        _recheckTimer = null;
      }

      return other;
    }

    _logger.e('❌ Failover target also unreachable. Staying on ${AppConfig.active}');
    return AppConfig.active;
  }

  void dispose() {
    _recheckTimer?.cancel();
    _recheckTimer = null;
  }
}
