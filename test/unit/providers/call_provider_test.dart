import 'package:flutter_test/flutter_test.dart';
import 'package:eva_mobile/providers/call_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CallProvider - Fallback Mode', () {
    late CallProvider provider;

    setUp(() {
      provider = CallProvider.fallback();
    });

    test('estado inicial e idle', () {
      expect(provider.status, CallStatus.idle);
    });

    test('isCallActive false no inicio', () {
      expect(provider.isCallActive, false);
    });

    test('currentSessionId null no inicio', () {
      expect(provider.currentSessionId, isNull);
    });

    test('currentIdosoData null no inicio', () {
      expect(provider.currentIdosoData, isNull);
    });

    test('callDuration zero no inicio', () {
      expect(provider.callDuration, Duration.zero);
    });

    test('errorMessage null no inicio', () {
      expect(provider.errorMessage, isNull);
    });

    test('debugStatus null no inicio', () {
      expect(provider.debugStatus, isNull);
    });

    test('fcmToken null no inicio', () {
      expect(provider.fcmToken, isNull);
    });

    test('isMuted false por default', () {
      expect(provider.isMuted, false);
    });

    test('isSpeakerOn true por default', () {
      expect(provider.isSpeakerOn, true);
    });

    test('totalPacketsReceived zero no inicio', () {
      expect(provider.totalPacketsReceived, 0);
    });

    test('lastPacketTime null no inicio', () {
      expect(provider.lastPacketTime, isNull);
    });
  });

  group('CallProvider - Toggle Controls', () {
    late CallProvider provider;

    setUp(() {
      provider = CallProvider.fallback();
    });

    test('toggleMute alterna estado', () {
      expect(provider.isMuted, false);

      provider.toggleMute();
      expect(provider.isMuted, true);

      provider.toggleMute();
      expect(provider.isMuted, false);
    });

    test('toggleSpeaker alterna estado', () {
      expect(provider.isSpeakerOn, true);

      provider.toggleSpeaker();
      expect(provider.isSpeakerOn, false);

      provider.toggleSpeaker();
      expect(provider.isSpeakerOn, true);
    });

    test('toggleMute notifica listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.toggleMute();
      expect(notified, true);
    });

    test('toggleSpeaker notifica listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.toggleSpeaker();
      expect(notified, true);
    });
  });

  group('CallProvider - Debug Status', () {
    late CallProvider provider;

    setUp(() {
      provider = CallProvider.fallback();
    });

    test('updateDebugStatus atualiza estado', () {
      provider.updateDebugStatus('Teste debug');

      expect(provider.debugStatus, 'Teste debug');
    });

    test('updateDebugStatus notifica listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.updateDebugStatus('status');
      expect(notified, true);
    });

    test('updateFcmToken atualiza token', () {
      provider.updateFcmToken('new-token-123');

      expect(provider.fcmToken, 'new-token-123');
    });

    test('updateFcmToken notifica listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.updateFcmToken('token');
      expect(notified, true);
    });
  });

  group('CallProvider - receiveCall', () {
    late CallProvider provider;

    setUp(() {
      provider = CallProvider.fallback();
    });

    test('receiveCall muda status para ringing', () async {
      await provider.receiveCall('session-123');

      expect(provider.status, CallStatus.ringing);
      expect(provider.currentSessionId, 'session-123');
    });

    test('receiveCall salva idosoData', () async {
      final idosoData = {'id': 5, 'nome': 'Dona Maria'};
      await provider.receiveCall('session-456', idosoData: idosoData);

      expect(provider.currentIdosoData, idosoData);
    });

    test('receiveCall limpa erro anterior', () async {
      await provider.receiveCall('session-789');

      expect(provider.errorMessage, isNull);
    });

    test('receiveCall notifica listeners', () async {
      var notified = false;
      provider.addListener(() => notified = true);

      await provider.receiveCall('session-test');
      expect(notified, true);
    });
  });

  group('CallStatus enum', () {
    test('tem todos os estados', () {
      expect(CallStatus.values.length, 7);
      expect(CallStatus.values, contains(CallStatus.idle));
      expect(CallStatus.values, contains(CallStatus.ringing));
      expect(CallStatus.values, contains(CallStatus.connecting));
      expect(CallStatus.values, contains(CallStatus.connected));
      expect(CallStatus.values, contains(CallStatus.ending));
      expect(CallStatus.values, contains(CallStatus.ended));
      expect(CallStatus.values, contains(CallStatus.error));
    });
  });

  group('CallProvider - currentVolume', () {
    test('volume inicia em 0.0', () {
      final provider = CallProvider.fallback();
      expect(provider.currentVolume, 0.0);
    });
  });
}
