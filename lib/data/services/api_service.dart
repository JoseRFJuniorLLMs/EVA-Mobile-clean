import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../core/config/app_config.dart';
import 'connection_manager.dart';

class ApiService {
  final Logger _logger = Logger();
  final ConnectionManager _connManager = ConnectionManager();

  static const _defaultTimeout = Duration(seconds: 30);

  // Consecutive failures trigger failover
  int _consecutiveFailures = 0;
  static const _failoverThreshold = 3;

  String get baseUrl => AppConfig.apiBaseUrl;
  String get audioUrl => AppConfig.apiAudioUrl;

  /// Wraps HTTP calls with automatic failover on repeated failures.
  Future<http.Response?> _resilientGet(Uri url, {Duration? timeout}) async {
    try {
      final response = await http.get(url).timeout(timeout ?? _defaultTimeout);
      _consecutiveFailures = 0;
      return response;
    } catch (e) {
      _consecutiveFailures++;
      _logger.e('❌ Request failed ($_consecutiveFailures/$_failoverThreshold): $e');

      if (_consecutiveFailures >= _failoverThreshold) {
        _logger.w('🔄 Triggering failover after $_consecutiveFailures failures...');
        await _connManager.failover();
        _consecutiveFailures = 0;

        // Retry once on the new server
        try {
          final newUrl = _rebuildUrl(url);
          final response = await http.get(newUrl).timeout(timeout ?? _defaultTimeout);
          return response;
        } catch (retryError) {
          _logger.e('❌ Retry on failover also failed: $retryError');
          return null;
        }
      }
      return null;
    }
  }

  /// Rebuild a URL for the new active server after failover.
  Uri _rebuildUrl(Uri original) {
    final path = original.path;
    final query = original.query;

    final newBase = path.contains('/call-') || path.contains('/call_')
        ? audioUrl
        : baseUrl;
    final newUrl = query.isNotEmpty ? '$newBase$path?$query' : '$newBase$path';
    return Uri.parse(newUrl);
  }

  /// Busca idoso pelo CPF
  Future<Map<String, dynamic>?> getIdosoByCpf(String cpf) async {
    try {
      _logger.i('🔍 Buscando idoso por CPF: $cpf [${AppConfig.active.label}]');
      final cpfClean = cpf.replaceAll(RegExp(r'[^0-9]'), '');
      final url = Uri.parse('$baseUrl/idosos/by-cpf/$cpfClean');
      final response = await _resilientGet(url);

      if (response == null) return null;

      if (response.statusCode == 200) {
        final idoso = jsonDecode(response.body);
        _logger.i('✅ Idoso encontrado: ${idoso['nome']}');
        return idoso;
      } else if (response.statusCode == 404) {
        _logger.w('⚠️ CPF nao encontrado');
        return null;
      } else {
        _logger.e('❌ Erro ao buscar idoso: ${response.statusCode}');
        throw Exception('Erro no servidor (${response.statusCode}). Tente novamente.');
      }
    } catch (e) {
      _logger.e('❌ Erro ao buscar idoso por CPF: $e');
      return null;
    }
  }

  /// Sincroniza o token FCM via CPF
  Future<bool> syncTokenByCpf({required String cpf, required String token}) async {
    try {
      _logger.i('🔄 Sincronizando token para CPF: $cpf [${AppConfig.active.label}]');
      final url = Uri.parse('$baseUrl/idosos/sync-token-by-cpf?cpf=$cpf&token=$token');

      final response = await http.patch(url, headers: {
        'Content-Type': 'application/json'
      }).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        _logger.i('✅ Token sincronizado com sucesso');
        _consecutiveFailures = 0;
        return true;
      } else {
        _logger.e('❌ Falha ao sincronizar: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _consecutiveFailures++;
      _logger.e('❌ Erro ao sincronizar token: $e');
      if (_consecutiveFailures >= _failoverThreshold) {
        await _connManager.failover();
        _consecutiveFailures = 0;
      }
      return false;
    }
  }

  /// Busca a lista completa de idosos
  Future<List<Map<String, dynamic>>> listIdosos() async {
    try {
      _logger.i('🔍 Buscando idosos em: $baseUrl/idosos [${AppConfig.active.label}]');
      final url = Uri.parse('$baseUrl/idosos');
      final response = await _resilientGet(url, timeout: const Duration(seconds: 10));

      if (response == null) return [];

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
    return syncTokenByCpf(cpf: cpf, token: token);
  }

  /// Obtém dados detalhados de um idoso
  Future<Map<String, dynamic>?> getIdoso(int idosoId) async {
    try {
      _logger.i('🔍 Buscando dados do idoso: $idosoId [${AppConfig.active.label}]');
      final url = Uri.parse('$baseUrl/idosos/$idosoId');
      final response = await _resilientGet(url);

      if (response == null) return null;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('✅ Dados do idoso obtidos');
        return data;
      }

      _logger.w('⚠️ Idoso nao encontrado: status ${response.statusCode}');
      return null;
    } catch (e) {
      _logger.e('❌ Erro ao obter dados do idoso: $e');
      return null;
    }
  }

  /// Obter historico de chamadas
  Future<List<Map<String, dynamic>>> getCallHistory(int idosoId) async {
    try {
      _logger.i('📚 Fetching call history for idoso: $idosoId [${AppConfig.active.label}]');
      final url = Uri.parse('$audioUrl/call-logs?idoso_id=$idosoId');
      final response = await _resilientGet(url);

      if (response == null) return [];

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

  /// Salva o historico da chamada
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
      _logger.i('💾 Salvando log de chamada: $sessionId [${AppConfig.active.label}]');

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
      ).timeout(_defaultTimeout);

      final success = response.statusCode == 200 || response.statusCode == 201;

      if (success) {
        _logger.i('✅ Log de chamada salvo');
        _consecutiveFailures = 0;
      } else {
        _logger.e('❌ Erro ao salvar log: ${response.statusCode}');
      }

      return success;
    } catch (e) {
      _logger.e('❌ Erro ao salvar log de chamada: $e');
      return false;
    }
  }

  /// Reporta erros criticos
  Future<bool> reportError(String sessionId, String type, String message) async {
    try {
      _logger.i('⚠️ Reportando erro: $type [${AppConfig.active.label}]');

      final response = await http.post(
        Uri.parse('$audioUrl/call-errors'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': sessionId,
          'error_type': type,
          'error_message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(_defaultTimeout);

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
      _logger.i('🏥 Verificando saude do servidor [${AppConfig.active.label}]...');
      final url = Uri.parse(AppConfig.active.healthUrl);
      final response = await http.get(url).timeout(const Duration(seconds: 5));

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

  // ── Agendamentos ────────────────────────────────────────

  /// Lista todos os agendamentos de um idoso
  Future<List<Map<String, dynamic>>> listAgendamentos(int idosoId) async {
    try {
      _logger.i('Listando agendamentos para idoso: $idosoId [${AppConfig.active.label}]');
      final url = Uri.parse('$baseUrl/agendamentos?idoso_id=$idosoId');
      final response = await _resilientGet(url);

      if (response == null) return [];

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _logger.i('${data.length} agendamentos encontrados');
        return data.cast<Map<String, dynamic>>();
      }

      _logger.w('Status ${response.statusCode} ao listar agendamentos');
      return [];
    } catch (e) {
      _logger.e('Erro ao listar agendamentos: $e');
      return [];
    }
  }

  /// Cria um novo agendamento
  Future<Map<String, dynamic>?> createAgendamento({
    required int idosoId,
    required DateTime dataHoraAgendada,
    String tipo = 'chamada_voz',
    String prioridade = 'normal',
  }) async {
    try {
      _logger.i('Criando agendamento para idoso: $idosoId [${AppConfig.active.label}]');

      final body = {
        'idoso_id': idosoId,
        'tipo': tipo,
        'data_hora_agendada': dataHoraAgendada.toUtc().toIso8601String(),
        'prioridade': prioridade,
        'status': 'agendado',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/agendamentos/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _logger.i('Agendamento criado com ID: ${data['id']}');
        _consecutiveFailures = 0;
        return data;
      }

      _logger.e('Erro ao criar agendamento: ${response.statusCode}');

      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('detail')) {
          throw Exception(errorData['detail']);
        }
      } catch (_) {}

      throw Exception('Erro ${response.statusCode}');
    } catch (e) {
      _logger.e('Erro ao criar agendamento: $e');
      _consecutiveFailures++;
      if (_consecutiveFailures >= _failoverThreshold) {
        await _connManager.failover();
        _consecutiveFailures = 0;
      }
      rethrow;
    }
  }

  /// Atualiza um agendamento
  Future<bool> updateAgendamento({
    required int agendamentoId,
    DateTime? dataHoraAgendada,
    String? tipo,
    String? prioridade,
  }) async {
    try {
      _logger.i('Atualizando agendamento ID: $agendamentoId [${AppConfig.active.label}]');

      final body = <String, dynamic>{};
      if (dataHoraAgendada != null) {
        body['data_hora_agendada'] = dataHoraAgendada.toUtc().toIso8601String();
      }
      if (tipo != null) body['tipo'] = tipo;
      if (prioridade != null) body['prioridade'] = prioridade;

      final response = await http.put(
        Uri.parse('$baseUrl/agendamentos/$agendamentoId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        _logger.i('Agendamento atualizado');
        _consecutiveFailures = 0;
        return true;
      }

      _logger.e('Erro ao atualizar agendamento: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.e('Erro ao atualizar agendamento: $e');
      return false;
    }
  }

  /// Atualiza status de um agendamento
  Future<bool> updateAgendamentoStatus({
    required int agendamentoId,
    required String status,
  }) async {
    try {
      _logger.i('Atualizando status do agendamento $agendamentoId para: $status [${AppConfig.active.label}]');

      final response = await http.patch(
        Uri.parse('$baseUrl/agendamentos/$agendamentoId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        _logger.i('Status atualizado');
        _consecutiveFailures = 0;
        return true;
      }

      _logger.e('Erro ao atualizar status: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.e('Erro ao atualizar status: $e');
      return false;
    }
  }

  /// Cancela um agendamento
  Future<bool> cancelAgendamento(int agendamentoId) async {
    return updateAgendamentoStatus(
      agendamentoId: agendamentoId,
      status: 'cancelado',
    );
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
      _logger.i('📤 Enviando log de erro para backend [${AppConfig.active.label}]...');
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
      ).timeout(_defaultTimeout);

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('❌ Erro critico ao enviar log: $e');
      return false;
    }
  }
}
