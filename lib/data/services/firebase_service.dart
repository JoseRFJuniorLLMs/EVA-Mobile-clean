import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart'; // 🔴 P1 FIX: For MethodChannel

import 'api_service.dart';
import 'storage_service.dart';
import 'package:provider/provider.dart';
import '../../providers/call_provider.dart';
import '../../main.dart'; // Para acessar navigatorKey
import 'package:go_router/go_router.dart';
import 'callkit_service.dart'; // ✅ CallKit Service

// Callback global para notificações em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final logger = Logger();
  logger.i('🔔 Background notification: ${message.data}');

  if (message.data['action'] == 'START_VOICE_CALL') {
    logger.i(
      '📞 Voice call request in background: ${message.data['sessionId']}',
    );

    // ✅ MOSTRAR TELA DE CHAMADA IMEDIATAMENTE (BACKGROUND)
    final sessionId = message.data['sessionId'];
    final name = message.data['idosoNome'] ?? 'EVA';

    await CallKitService.showIncomingCall(
      uuid: sessionId,
      name: name,
      avatar: 'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
      handle: 'Assistente Virtual',
    );

    // 🔴 P1 FIX: Force launch app after showing CallKit
    try {
      const platform = MethodChannel('com.eva.br/app_launcher');
      await platform.invokeMethod('launchApp');
      logger.i('✅ App launch triggered from background');
    } catch (e) {
      logger.e('❌ Failed to launch app: $e');
    }
  }
}

class FirebaseService {
  static final Logger _logger = Logger();
  static FirebaseMessaging? _messaging;

  // Callback para quando receber uma chamada de voz
  static Function(String sessionId, Map<String, dynamic> idosoData)?
      onVoiceCallReceived;

  static Future<void> initialize() async {
    try {
      _logger.i('🔥 Starting Firebase Messaging initialization...');
      _messaging = FirebaseMessaging.instance;

      // Configurar handler de background
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // ===== PASSO 1: SOLICITAR PERMISSÕES =====
      _logger.i('🔐 Requesting notification permissions...');
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: true,
        criticalAlert: true,
        provisional: false, // Importante: false para pedir permissão explícita
      );

      _logger.i('📱 Permission status: ${settings.authorizationStatus}');
      _logger.i('🔔 Alert setting: ${settings.alert}');
      _logger.i('🔊 Sound setting: ${settings.sound}');
      _logger.i('📛 Badge setting: ${settings.badge}');

      _logger.i('📱 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('✅ Notification permissions granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        _logger.i('⚠️ Provisional permission granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _logger.e('❌ Notification permissions denied');
        throw Exception(
          'Permissões de notificação negadas. Por favor, ative nas configurações do dispositivo.',
        );
      } else {
        _logger.e('❌ Notification permissions not determined');
        throw Exception('Permissões de notificação não determinadas');
      }

      // ===== PASSO 2: OBTER TOKEN (Background/Silent) =====
      _logger.i(
        '📨 Inicialização básica do Firebase (Token será obtido sob demanda)...',
      );

      // Não bloquear a inicialização esperando o token.
      // O token é obtido explicitamente no SetupScreen ou refreshed pelo listener.
      getTokenWithRetry(maxAttempts: 1).then((token) {
        if (token != null) {
          _logger.i(
            '✅ Token obtido em background: ${token.substring(0, 10)}...',
          );
          StorageService.saveFcmToken(token);
        }
      }).catchError((e) {
        _logger.w(
          '⚠️ Falha ao obter token em background (não crítico): $e',
        );
      });

      // Salvar token localmente se já existir no cache?
      // O listener onTokenRefresh cuidará disso.

      // ===== PASSO 3: SINCRONIZAR COM BACKEND =====
      _logger.i('🔄 Sincronizando token com backend...');
      // await _syncTokenWithBackend(token); // Opcional no init, feito no login

      // ===== PASSO 4: CONFIGURAR LISTENERS AGORA É MANUAL =====
      // _setupListeners(); // REMOVIDO: Deve ser chamado manualmente após registrar callbacks

      _logger.i('✅ Firebase Messaging initialized (Listeners pending)');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Firebase Messaging: $e');
      _logger.e('Stack trace: $stackTrace');
      rethrow; // Propagar erro para ser tratado no main
    }
  }

  /// Inicia os listeners de notificação (Chamar APÓS configurar callbacks)
  static void startListening() {
    _logger.i('👂 Starting Firebase listeners...');
    _setupListeners();
    _logger.i('✅ Listeners active');
  }

  // Método público com retry robusto (exponencial)
  static Future<String?> getTokenWithRetry({
    int maxAttempts = 5,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _logger.i('🔄 Tentativa $attempt/$maxAttempts de obter token...');

        // Delay exponencial: 1s, 2s, 4s, 8s, 16s
        if (attempt > 1) {
          final delayInSeconds =
              initialDelay.inSeconds * (1 << (attempt - 2)); // 2^(attempt-2)
          _logger.i('⏳ Aguardando ${delayInSeconds}s...');
          await Future.delayed(Duration(seconds: delayInSeconds));
        }

        // Verificar se o serviço está pronto
        if (_messaging == null) {
          _logger.w(
            '⚠️ Firebase Messaging não inicializado, tentando inicializar...',
          );
          _messaging = FirebaseMessaging.instance;
        }

        // Tentar obter token
        String? token = await _messaging!.getToken();

        if (token != null && token.isNotEmpty) {
          _logger.i('✅ Token obtido na tentativa $attempt');
          return token;
        }

        _logger.w('⚠️ Token null na tentativa $attempt');
      } catch (e) {
        _logger.e('❌ Erro na tentativa $attempt: $e');

        if (attempt == maxAttempts) {
          _logger.e('❌ Todas as tentativas falharam.');
        }
      }
    }

    return null;
  }

  /// Método de emergência para forçar renovação do token
  static Future<String?> forceRefreshToken() async {
    try {
      _logger.w('☢️ FORCING TOKEN REFRESH...');
      await _messaging?.deleteToken();
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Esperar o Firebase respirar

      // Reinicializar instância
      _messaging = FirebaseMessaging.instance;

      return await getTokenWithRetry(maxAttempts: 3);
    } catch (e) {
      _logger.e('❌ Error forcing token refresh: $e');
      return null;
    }
  }

  /// Sincroniza o token com o backend
  static Future<void> _syncTokenWithBackend(String token) async {
    try {
      final cpf = StorageService.getIdosoCpf();

      if (cpf == null) {
        _logger.w('⚠️ No CPF found. Skipping token sync with backend.');
        return;
      }

      _logger.i('🔄 Syncing token with backend for CPF: $cpf');

      final apiService = ApiService();
      final result = await apiService.syncTokenByCpf(cpf: cpf, token: token);

      _logger.i('✅ Token synced successfully with backend');
    } catch (e) {
      _logger.e('❌ Error syncing token: $e');
      // Não propagar erro - o token foi salvo localmente
    }
  }

  /// Configura todos os listeners do Firebase
  static void _setupListeners() {
    // Listener para token refresh
    _messaging!.onTokenRefresh.listen(
      (newToken) async {
        _logger.i('🔄 FCM Token refreshed');
        await StorageService.saveFcmToken(newToken);
        await _syncTokenWithBackend(newToken);
      },
      onError: (error) {
        _logger.e('❌ Error on token refresh: $error');
      },
    );

    // Listener para mensagens em foreground
    FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (error) {
        _logger.e('❌ Error handling foreground message: $error');
      },
    );

    // Listener para quando o app é aberto via notificação
    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageOpenedApp,
      onError: (error) {
        _logger.e('❌ Error handling message opened app: $error');
      },
    );

    // Verificar se o app foi aberto por uma notificação
    _messaging!.getInitialMessage().then((message) {
      if (message != null) {
        _handleInitialMessage(message);
      }
    }).catchError((error) {
      _logger.e('❌ Error getting initial message: $error');
    });
  }

  // Handler para mensagens em foreground (app aberto)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.i('📨 Foreground notification received');

    if (message.data['action'] == 'START_VOICE_CALL') {
      _logger.i(
        '📞 Voice call notification in foreground - Auto-opening call screen',
      );

      // 🔴 P1 FIX: Auto-navigate to call screen when notification arrives
      final context = navigatorKey.currentContext;
      if (context != null) {
        final provider = Provider.of<CallProvider>(context, listen: false);

        // Extract session data
        final sessionId = message.data['sessionId'];
        Map<String, dynamic> idosoData = {};
        if (message.data.containsKey('idosoId'))
          idosoData['idosoId'] = message.data['idosoId'];
        if (message.data.containsKey('idosoNome'))
          idosoData['nome'] = message.data['idosoNome'];

        // Update provider state to show incoming call
        provider.receiveCall(sessionId, idosoData: idosoData);

        // Navigate to call screen automatically
        context.push('/call');

        _logger.i('✅ Auto-navigated to call screen');
      } else {
        _logger.w('⚠️ No context available for navigation');
      }

      return;
    }

    _logger.i('Title: ${message.notification?.title}');
    _logger.i('Body: ${message.notification?.body}');
    _processNotificationData(message.data);
  }

  // Handler para quando o app é aberto via notificação
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    _logger.i('📲 App opened from notification');

    if (message.data['action'] == 'START_VOICE_CALL') {
      _logger.i('🚀 User tapped standard notification -> Accepting Call');
      final context = navigatorKey.currentContext;
      if (context != null) {
        final provider = Provider.of<CallProvider>(context, listen: false);

        // 1. Navegar para tela de chamada
        context.push('/call');

        // 2. Aceitar a chamada (simulando clique no CallKit)
        // Precisamos garantir que os dados da sessão estejam setados
        final sessionId = message.data['sessionId'];
        provider.receiveCall(sessionId, idosoData: {}); // Garante estado
        provider.acceptCall();
      }
      return;
    }

    await _processNotificationData(message.data);
  }

  // Handler para quando o app é iniciado por uma notificação
  static Future<void> _handleInitialMessage(RemoteMessage message) async {
    _logger.i('🚀 App started from notification');

    if (message.data['action'] == 'START_VOICE_CALL') {
      _logger.i('🚀 User started app from notification -> Accepting Call');
      // Pequeno delay para garantir que o contexto esteja pronto
      Future.delayed(const Duration(seconds: 1), () {
        final context = navigatorKey.currentContext;
        if (context != null) {
          final provider = Provider.of<CallProvider>(context, listen: false);
          context.push('/call');
          final sessionId = message.data['sessionId'];
          provider.receiveCall(sessionId, idosoData: {});
          provider.acceptCall();
        }
      });
      return;
    }

    await _processNotificationData(message.data);
  }

  // Processa os dados da notificação
  static Future<void> _processNotificationData(
    Map<String, dynamic> data, {
    bool isForeground = false,
  }) async {
    try {
      final action = data['action'] as String?;
      _logger.i('🔍 Processing Notification Action: $action');
      _logger.i('🔍 Notification Data: $data');

      // 🐞 DEBUG: Tentar atualizar status na tela
      try {
        final context = navigatorKey.currentContext;
        if (context != null) {
          // Usar listen: false fora da árvore de widgets
          final provider = Provider.of<CallProvider>(context, listen: false);
          provider.updateDebugStatus(
            "Msg: $action | ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}",
          );
        }
      } catch (e) {
        _logger.w('⚠️ Falha ao atualizar debug UI: $e');
      }

      if (action == 'START_VOICE_CALL') {
        final sessionId = data['sessionId'] as String?;

        if (sessionId == null || sessionId.isEmpty) {
          _logger.e('❌ Invalid sessionId in notification');
          return;
        }

        _logger.i('📞 Voice call request received');
        _logger.i('Session ID: $sessionId');

        // Extrair dados do idoso
        Map<String, dynamic> idosoData = {};

        if (data.containsKey('idosoId')) idosoData['idosoId'] = data['idosoId'];
        if (data.containsKey('idosoNome')) {
          idosoData['nome'] = data['idosoNome'];
        }
        if (data.containsKey('tarefaTipo')) {
          idosoData['tarefaTipo'] = data['tarefaTipo'];
        }
        if (data.containsKey('prioridade')) {
          idosoData['prioridade'] = data['prioridade'];
        }

        _logger.i('Idoso data: $idosoData');

        // ✅ LÓGICA DE LINHA OCUPADA (BUSY LINE)
        // Verificar se já existe uma chamada ativa
        bool isBusy = false;

        // 1. Verificar CallKit (Background/Nativo)
        try {
          final activeCalls =
              await CallKitService.activeCalls(); // Abstração ou direto
          if (activeCalls is List && activeCalls.isNotEmpty) {
            isBusy = true;
          }
        } catch (e) {
          /* ignore */
        }

        // 2. Verificar Provider (Foreground/App)
        if (!isBusy) {
          try {
            final context = navigatorKey.currentContext;
            if (context != null) {
              final provider = Provider.of<CallProvider>(
                context,
                listen: false,
              );
              if (provider.status == CallStatus.connected ||
                  provider.status == CallStatus.connecting) {
                isBusy = true;
              }
            }
          } catch (e) {
            /* ignore */
          }
        }

        if (isBusy) {
          _logger.w('⛔ LINHA OCUPADA! Ignorando nova chamada recebida.');
          // Opcional: Enviar feedback ao backend de "busy"
          return;
        }

        // ✅ LÓGICA DE FOREGROUND vs BACKGROUND
        // Se o app já está aberto (isForeground), NÃO mostramos a tela do CallKit (Overlay).
        // Apenas disparamos o status 'ringing' para mostrar o botão pulsante dentro do app.
        if (!isForeground) {
          _logger.i('🌑 Background/Terminated -> CallKit (Tela Nativa)');
          CallKitService.showIncomingCall(
            uuid: sessionId,
            name: idosoData['nome'] ?? 'EVA',
            avatar:
                'https://cdn-icons-png.flaticon.com/512/4140/4140048.png', // Avatar padrão
            handle: 'Assistente Virtual',
          );
        } else {
          _logger.i('☀️ Foreground -> UI Interna (Sem CallKit)');
        }

        // Chamar callback para atualizar estado interno (sem tocar som extra se o CallKit já tocar)
        if (onVoiceCallReceived != null) {
          _logger.i('✅ Triggering call handler...');
          onVoiceCallReceived!(sessionId, idosoData);
        } else {
          _logger.w('⚠️ No call handler registered!');
        }
      } else if (action != null) {
        _logger.i('ℹ️ Unknown action: $action');
      }
    } catch (e) {
      _logger.e('❌ Error processing notification: $e');
    }
  }

  /// Obtém o token atual (sem retry)
  static Future<String?> getToken() async {
    try {
      return await _messaging?.getToken();
    } catch (e) {
      _logger.e('❌ Error getting token: $e');
      return null;
    }
  }

  /// Deleta o token (útil para logout)
  static Future<void> deleteToken() async {
    try {
      await _messaging?.deleteToken();
      _logger.i('🗑️ FCM Token deleted');
    } catch (e) {
      _logger.e('❌ Error deleting token: $e');
    }
  }

  /// Verifica se as notificações estão habilitadas
  static Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _messaging!.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      _logger.e('❌ Error checking notification status: $e');
      return false;
    }
  }
}
