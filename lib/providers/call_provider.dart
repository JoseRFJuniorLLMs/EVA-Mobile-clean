import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/services/native_audio_service.dart';
import '../data/services/storage_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../data/services/firebase_service.dart';
import 'dart:convert';
import '../data/services/websocket_service.dart';
import '../data/services/api_service.dart';

enum CallStatus { idle, ringing, connecting, connected, ending, ended, error }

class CallProvider with ChangeNotifier {
  final Logger _logger = Logger();

  final NativeAudioService _nativeAudio = NativeAudioService();
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription? _wsSubscription;

  final ApiService _apiService = ApiService();
  final _platformChannel = const MethodChannel('com.eva.br/minimize');
  AudioPlayer? _ringtonePlayer;

  CallStatus _status = CallStatus.idle;
  String? _currentSessionId;
  Map<String, dynamic>? _currentIdosoData;
  DateTime? _callStartTime;
  String? _errorMessage;

  Timer? _durationTimer;
  Duration _callDuration = Duration.zero;

  bool _isMuted = false;
  bool _isSpeakerOn = true;

  int _totalPacketsReceived = 0;
  DateTime? _lastPacketTime;
  String? _debugStatus;
  String? _fcmToken;
  double get currentVolume => _currentVolume;
  double _currentVolume = 0.0;

  bool _isInitializing = false;
  Future<void>? _initializationFuture;

  CallProvider._internal() {
    _logger.i('CallProvider criado');

    FirebaseService.onVoiceCallReceived = (sessionId, idosoData) {
      _logger.i('Callback do Firebase disparado no Provider!');
      receiveCall(sessionId, idosoData: idosoData);
    };
  }

  CallProvider.fallback() {
    _logger.w('CallProvider criado em modo FALLBACK');
  }

  static Future<CallProvider> create() async {
    final provider = CallProvider._internal();
    provider.initialize();
    return provider;
  }

  // Getters
  CallStatus get status => _status;
  String? get currentSessionId => _currentSessionId;
  Map<String, dynamic>? get currentIdosoData => _currentIdosoData;
  bool get isCallActive => _status == CallStatus.connected;
  String? get errorMessage => _errorMessage;
  Duration get callDuration => _callDuration;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  int get totalPacketsReceived => _totalPacketsReceived;
  DateTime? get lastPacketTime => _lastPacketTime;
  String? get debugStatus => _debugStatus;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_isInitializing) {
      return _initializationFuture!;
    }

    if (_nativeAudio.isInitialized) {
      return;
    }

    _isInitializing = true;
    _initializationFuture = _initializeInternal();
    await _initializationFuture;
  }

  Future<void> _initializeInternal() async {
    try {
      _logger.i('Inicializando CallProvider com Native Audio...');

      _nativeAudio.onAudioRecorded = (data) {
        _wsService.sendBytes(data);
      };

      await _nativeAudio.initialize();

      _nativeAudio.volumeStream.listen((vol) {
        _currentVolume = vol;
        notifyListeners();
      });

      _logger.i('CallProvider inicializado com sucesso');
      _debugStatus = "Inicializado";

      _fcmToken = await StorageService.getFcmToken();

      try {
        final freshToken = await FirebaseMessaging.instance.getToken();
        if (freshToken != null) {
          if (_fcmToken != freshToken) {
            _fcmToken = freshToken;
            await StorageService.saveFcmToken(freshToken);
            _debugStatus = "Token Atualizado";
          }
          _fcmToken = freshToken;
        }
      } catch (e) {
        _logger.e('Erro ao validar token: $e');
      }

      notifyListeners();
    } catch (e) {
      _logger.e('Erro ao inicializar CallProvider: $e');
      _debugStatus = "Erro Init: $e";
      notifyListeners();
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  void updateDebugStatus(String status) {
    _debugStatus = status;
    notifyListeners();
  }

  void updateFcmToken(String token) {
    _fcmToken = token;
    notifyListeners();
  }

  Future<void> receiveCall(
    String sessionId, {
    Map<String, dynamic>? idosoData,
  }) async {
    _logger.i('RECEBENDO CHAMADA - Session: $sessionId');

    _currentSessionId = sessionId;
    _currentIdosoData = idosoData;
    _status = CallStatus.ringing;
    _errorMessage = null;

    _playRingtone();
    notifyListeners();
  }

  void startOutgoingCall() async {
    _logger.i('Iniciando chamada ativa (Outgoing)...');

    _currentSessionId = 'mobile-${DateTime.now().millisecondsSinceEpoch}';
    _status = CallStatus.connecting;
    notifyListeners();

    acceptCall();
  }

  Future<void> acceptCall() async {
    _logger.i('CHAMADA ACEITA PELO USUARIO');

    if (_initializationFuture != null) {
      try {
        await _initializationFuture;
      } catch (e) {
        _logger.e('Erro na inicializacao: $e');
        _status = CallStatus.error;
        _errorMessage = "Erro ao inicializar: ${e.toString()}";
        _apiService.sendErrorLog(
          level: 'CRITICAL',
          message: 'Failed to initialize during Call Accept',
          details: e.toString(),
        );
        notifyListeners();
        return;
      }
    }

    if (!_nativeAudio.isInitialized) {
      await _nativeAudio.initialize();
    }

    await _stopRingtone();

    _status = CallStatus.connecting;
    notifyListeners();

    try {
      var status = await Permission.microphone.request();
      if (!status.isGranted) {
        _logger.e('Permissao de microfone negada!');
        _status = CallStatus.error;
        _errorMessage = "Permissao de microfone necessaria";
        _apiService.sendErrorLog(
          level: 'WARNING',
          message: 'Microphone Permission Denied',
          details: 'User denied permission',
        );
        notifyListeners();
        return;
      }

      _logger.i('Conectando ao WebSocket...');
      await _wsService.connect();

      _wsSubscription?.cancel();
      final sessionCreatedCompleter = Completer<void>();

      _wsSubscription = _wsService.messages.listen(
        (data) {
          if (data is List<int>) {
            _nativeAudio.playChunk(Uint8List.fromList(data));
            _totalPacketsReceived++;
            _lastPacketTime = DateTime.now();
          } else if (data is String) {
            try {
              final msg = jsonDecode(data);
              _logger.i('MSG: ${msg['type']}');

              if (msg['type'] == 'session_created') {
                if (!sessionCreatedCompleter.isCompleted) {
                  sessionCreatedCompleter.complete();
                }
                if (_status != CallStatus.connected) {
                  _status = CallStatus.connected;
                  _callStartTime = DateTime.now();
                  _startTimer();
                  notifyListeners();
                }
              } else if (msg['type'] == 'error') {
                _logger.e('Erro do Backend: ${msg['message']}');
                _status = CallStatus.error;
                _errorMessage = msg['message'] ?? 'Erro desconhecido';
                notifyListeners();
              }
            } catch (e) {
              _logger.w('Erro ao decodificar JSON: $e');
            }
          }
        },
        onError: (e) {
          _logger.e('Erro no WebSocket: $e');
          _status = CallStatus.error;
          _errorMessage = "Erro na conexao: $e";
          _apiService.sendErrorLog(
            level: 'ERROR',
            message: 'WebSocket Error',
            details: e.toString(),
          );
          notifyListeners();
        },
      );

      final cpf = StorageService.getIdosoCpf();
      if (cpf == null) throw Exception('CPF nao encontrado');

      if (_currentSessionId == null) {
        _currentSessionId = 'mobile-${DateTime.now().millisecondsSinceEpoch}';
      }

      if (_currentSessionId != null) {
        await FlutterCallkitIncoming.setCallConnected(_currentSessionId!);
      }

      _logger.i('Registrando cliente: $cpf');
      _wsService.sendMessage(
          {'type': 'register', 'user_type': 'patient', 'cpf': cpf});

      await Future.delayed(const Duration(milliseconds: 500));

      final sessionId = _currentSessionId!;
      _logger.i('Iniciando sessao: $sessionId');
      _wsService.sendMessage({
        'type': 'start_call',
        'cpf': cpf,
        'session_id': sessionId,
      });

      _logger.i('Aguardando confirmacao do backend...');
      await sessionCreatedCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout aguardando session_created');
        },
      );

      _logger.i('Iniciando Captura de Audio...');
      await _nativeAudio.start();

      _logger.i('EVA CONECTADA COM SUCESSO!');
    } catch (e, stackTrace) {
      _logger.e('ERRO AO ATENDER CHAMADA: $e');

      _status = CallStatus.error;
      _errorMessage = "Erro ao conectar: ${e.toString()}";

      _apiService.sendErrorLog(
        level: 'CRITICAL',
        message: 'Exception during Call Connection',
        details: '$e\n$stackTrace',
      );

      notifyListeners();
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_callStartTime != null) {
        _callDuration = DateTime.now().difference(_callStartTime!);
        notifyListeners();
      }
    });
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  Future<void> endCall() async {
    _logger.i('FINALIZANDO CHAMADA');

    _durationTimer?.cancel();
    await _stopRingtone();

    if (_nativeAudio.isInitialized) {
      await _nativeAudio.stop();
    }

    _wsSubscription?.cancel();
    _wsService.disconnect();

    if (_currentSessionId != null && _callStartTime != null) {
      await _apiService.saveCallLog(
        sessionId: _currentSessionId!,
        idosoId: _currentIdosoData?['id'] ?? 0,
        startTime: _callStartTime!,
        endTime: DateTime.now(),
        duration: _callDuration,
        wasSuccessful: _errorMessage == null,
      );
    }

    _status = CallStatus.ended;
    notifyListeners();

    Future.delayed(const Duration(seconds: 2), () {
      _resetState();

      try {
        _platformChannel.invokeMethod('minimizeApp');
      } catch (e) {
        _logger.w('Erro ao minimizar app: $e');
      }
    });
  }

  void _resetState() {
    _status = CallStatus.idle;
    _currentSessionId = null;
    _currentIdosoData = null;
    _callDuration = Duration.zero;
    _callStartTime = null;
    _totalPacketsReceived = 0;
    _lastPacketTime = null;
    notifyListeners();
  }

  Future<void> _playRingtone() async {
    try {
      _ringtonePlayer ??= AudioPlayer();
      await _ringtonePlayer!.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer!.play(AssetSource('sounds/notifica.mp3'));
    } catch (e) {
      _logger.w('Erro ao tocar ringtone: $e');
    }
  }

  Future<void> _stopRingtone() async {
    try {
      if (_ringtonePlayer != null) {
        await _ringtonePlayer!.stop();
        await _ringtonePlayer!.dispose();
        _ringtonePlayer = null;
      }
    } catch (e) {
      _logger.e('Erro ao parar ringtone: $e');
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _stopRingtone();
    _nativeAudio.dispose();
    super.dispose();
  }
}
