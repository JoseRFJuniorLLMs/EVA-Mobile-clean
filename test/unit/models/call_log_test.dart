import 'package:flutter_test/flutter_test.dart';
import 'package:eva_mobile/data/models/call_log.dart';

void main() {
  group('CallLog - fromJson', () {
    test('cria CallLog com todos os campos', () {
      final json = {
        'id': 42,
        'session_id': 'session-abc-123',
        'idoso_id': 7,
        'start_time': '2026-01-15T10:30:00.000',
        'end_time': '2026-01-15T10:45:00.000',
        'duration_seconds': 900,
        'was_successful': true,
        'error_message': null,
      };

      final log = CallLog.fromJson(json);

      expect(log.id, 42);
      expect(log.sessionId, 'session-abc-123');
      expect(log.idosoId, 7);
      expect(log.startTime, DateTime(2026, 1, 15, 10, 30));
      expect(log.endTime, DateTime(2026, 1, 15, 10, 45));
      expect(log.duration, const Duration(seconds: 900));
      expect(log.wasSuccessful, true);
      expect(log.errorMessage, isNull);
    });

    test('cria CallLog com erro', () {
      final json = {
        'id': 1,
        'session_id': 'err-session',
        'idoso_id': 3,
        'start_time': '2026-02-01T08:00:00.000',
        'end_time': '2026-02-01T08:00:05.000',
        'duration_seconds': 5,
        'was_successful': false,
        'error_message': 'Connection timeout',
      };

      final log = CallLog.fromJson(json);

      expect(log.wasSuccessful, false);
      expect(log.errorMessage, 'Connection timeout');
    });
  });

  group('CallLog - toJson', () {
    test('serializa corretamente', () {
      final log = CallLog(
        id: 10,
        sessionId: 'test-session',
        idosoId: 5,
        startTime: DateTime(2026, 3, 1, 14, 0),
        endTime: DateTime(2026, 3, 1, 14, 30),
        duration: const Duration(minutes: 30),
        wasSuccessful: true,
        errorMessage: null,
      );

      final json = log.toJson();

      expect(json['id'], 10);
      expect(json['session_id'], 'test-session');
      expect(json['idoso_id'], 5);
      expect(json['duration_seconds'], 1800);
      expect(json['was_successful'], true);
      expect(json['error_message'], isNull);
      expect(json['start_time'], contains('2026-03-01'));
      expect(json['end_time'], contains('2026-03-01'));
    });

    test('roundtrip fromJson -> toJson -> fromJson', () {
      final original = {
        'id': 99,
        'session_id': 'roundtrip',
        'idoso_id': 1,
        'start_time': '2026-01-01T00:00:00.000',
        'end_time': '2026-01-01T01:00:00.000',
        'duration_seconds': 3600,
        'was_successful': true,
        'error_message': null,
      };

      final log1 = CallLog.fromJson(original);
      final json = log1.toJson();
      final log2 = CallLog.fromJson(json);

      expect(log2.sessionId, log1.sessionId);
      expect(log2.idosoId, log1.idosoId);
      expect(log2.duration, log1.duration);
      expect(log2.wasSuccessful, log1.wasSuccessful);
    });
  });

  group('CallLog - id nullable', () {
    test('id pode ser null', () {
      final log = CallLog(
        sessionId: 'new',
        idosoId: 1,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: Duration.zero,
        wasSuccessful: true,
      );

      expect(log.id, isNull);
    });
  });
}
