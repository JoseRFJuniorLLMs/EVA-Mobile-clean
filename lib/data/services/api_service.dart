import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../core/config/app_config.dart';

class ApiService {
  final Logger _logger = Logger();

  // 🔴 P0 FIX: Global timeout for all HTTP requests
  static const _defaultTimeout = Duration(seconds: 30);

  String get baseUrl => AppConfig.apiBaseUrl;
  String get audioUrl => AppConfig.apiAudioUrl;

  /// Busca idoso pelo CPF usando o endpoint específico
  Future<Map<String, dynamic>?> getIdosoByCpf(String cpf) async {
    try {
      _logger.i('🔍 Buscando idoso por CPF: $cpf');

      final cpfClean = cpf.replaceAll(RegExp(r'[^0-9]'), '');

      final url = Uri.parse('$baseUrl/idosos/by-cpf/$cpfClean');
      final response = await http.get(url).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final idoso = jsonDecode(response.body);
        _logger.i('✅ Idoso encontrado: ${idoso['nome']}');
        return idoso;
      } else if (response.statusCode == 404) {
        _logger.w('⚠️ CPF não encontrado');
        return null;
      } else {
        _logger.e('❌ Erro ao buscar idoso: ${response.statusCode}');
        throw Exception(
          'Erro no servidor (${response.statusCode}). Tente novamente.',
        );
      }
    } catch (e) {
      _logger.e('❌ Erro ao buscar idoso por CPF: $e');
      return null;
    }
  }

  /// Sincroniza o token de notificação via CPF
  Future<bool> syncTokenByCpf({
    required String cpf,
    required String token,
  }) async {
    try {
      _logger.i('🔄 Sincronizando token para CPF: $cpf');
      final url = Uri.parse(
        '$baseUrl/idosos/sync-token-by-cpf?cpf=$cpf&token=$token',
      );

      final response = await http.patch(url, headers: {
        'Content-Type': 'application/json'
      }).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        _logger.i('✅ Token sincronizado com sucesso');
        return true;
      } else {
        _logger.e('❌ Falha ao sincronizar: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Erro ao sincronizar token: $e');
      return false;
    }
  }

  /// Busca a lista completa de idosos
  Future<List<Map<String, dynamic>>> listIdosos() async {
    try {
      _logger.i('🔍 Buscando idosos em: $baseUrl/idosos');
      final response = await http
          .get(Uri.parse('$baseUrl/idosos'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _logger.i('✅ ${data.length} idosos encontrados');
        return data.cast<Map<String, dynamic>>();
      }

      _logger.w('⚠️ Status ${response.statusCode} ao buscar idosos');
      return [];
    } catch (e) {
      _logger.e('❌ Erro ao listar idosos: $e');
      return [];
    }
  }

  /// Atualiza o token FCM do dispositivo
  Future<bool> updateDeviceToken(String cpf, String token) async {
    try {
      _logger.i('🔄 Sincronizando FCM token para CPF $cpf');
      final url = Uri.parse(
        '$baseUrl/idosos/sync-token-by-cpf?cpf=$cpf&token=$token',
      );

      final response = await http.patch(url, headers: {
        'Content-Type': 'application/json'
      }).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        _logger.i('✅ Token sincronizado com sucesso');
        return true;
      } else {
        _logger.e('❌ Falha ao sincronizar: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Erro de conexão: $e');
      return false;
    }
  }

  /// Obtém dados detalhados de um idoso
  Future<Map<String, dynamic>?> getIdoso(int idosoId) async {
    try {
      _logger.i('🔍 Buscando dados do idoso: $idosoId');
      final response = await http
          .get(Uri.parse('$baseUrl/idosos/$idosoId'))
          .timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('✅ Dados do idoso obtidos');
        return data;
      }

      _logger.w('⚠️ Idoso não encontrado: status ${response.statusCode}');
      return null;
    } catch (e) {
      _logger.e('❌ Erro ao obter dados do idoso: $e');
      return null;
    }
  }

  /// Obter histórico de chamadas
  Future<List<Map<String, dynamic>>> getCallHistory(int idosoId) async {
    try {
      _logger.i('📚 Fetching call history for idoso: $idosoId');

      final url = Uri.parse('$audioUrl/call-logs?idoso_id=$idosoId');
      final response = await http.get(url).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _logger.i('✅ Fetched ${data.length} call logs');
        return data.cast<Map<String, dynamic>>();
      } else {
        _logger.e('❌ Failed to fetch call history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('❌ Error fetching call history: $e');
      return [];
    }
  }

  /// Salva o histórico da chamada
  Future<bool> saveCallLog({
    required String sessionId,
    required int idosoId,
    required DateTime startTime,
    required DateTime endTime,
    required Duration duration,
    required bool wasSuccessful,
    String? errorMessage,
  }) async {
    try {
      _logger.i('💾 Salvando log de chamada: $sessionId');

      final response = await http.post(
        Uri.parse('$audioUrl/call-logs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': sessionId,
          'idoso_id': idosoId,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'duration_seconds': duration.inSeconds,
          'was_successful': wasSuccessful,
          'error_message': errorMessage,
        }),
      );

      final success = response.statusCode == 200 || response.statusCode == 201;

      if (success) {
        _logger.i('✅ Log de chamada salvo');
      } else {
        _logger.e('❌ Erro ao salvar log: ${response.statusCode}');
      }

      return success;
    } catch (e) {
      _logger.e('❌ Erro ao salvar log de chamada: $e');
      return false;
    }
  }

  /// Reporta erros críticos
  Future<bool> reportError(
    String sessionId,
    String type,
    String message,
  ) async {
    try {
      _logger.i('⚠️ Reportando erro: $type');

      final response = await http.post(
        Uri.parse('$audioUrl/call-errors'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': sessionId,
          'error_type': type,
          'error_message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      final success = response.statusCode == 201;

      if (success) {
        _logger.i('✅ Erro reportado');
      } else {
        _logger.e('❌ Falha ao reportar: ${response.statusCode}');
      }

      return success;
    } catch (e) {
      _logger.e('❌ Erro ao reportar falha: $e');
      return false;
    }
  }

  /// Verifica se o servidor está online
  Future<bool> checkHealth() async {
    try {
      _logger.i('🏥 Verificando saúde do servidor...');
      final rootUrl = baseUrl.endsWith('/api/v1')
          ? baseUrl.substring(0, baseUrl.length - 7)
          : baseUrl;

      final response = await http
          .get(Uri.parse('$rootUrl/health'))
          .timeout(const Duration(seconds: 5));

      final isHealthy = response.statusCode == 200;

      if (isHealthy) {
        _logger.i('✅ Servidor online');
      } else {
        _logger.w('⚠️ Servidor retornou: ${response.statusCode}');
      }

      return isHealthy;
    } catch (e) {
      _logger.e('❌ Servidor offline ou erro: $e');
      return false;
    }
  }

  /// Envia logs de erro do app para o backend
  Future<bool> sendErrorLog({
    required String level,
    required String message,
    String? details,
    String? deviceInfo,
    String? appVersion,
    String? userCpf,
  }) async {
    try {
      _logger.i('📤 Enviando log de erro para backend...');
      final url = Uri.parse('$baseUrl/logs/mobile');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'level': level,
          'message': message,
          'details': details,
          'device_info': deviceInfo,
          'app_version': appVersion,
          'user_cpf': userCpf,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('❌ Erro crítico ao enviar log: $e');
      return false;
    }
  }
}
