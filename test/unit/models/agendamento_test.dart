import 'package:flutter_test/flutter_test.dart';
import 'package:eva_mobile/data/models/agendamento.dart';

void main() {
  group('Agendamento - fromJson', () {
    test('cria Agendamento com todos os campos', () {
      final json = {
        'id': 1,
        'idoso_id': 5,
        'tipo': 'chamada_voz',
        'data_hora_agendada': '2026-03-15T14:00:00.000',
        'data_hora_realizada': '2026-03-15T14:05:00.000',
        'status': 'concluido',
        'prioridade': 'alta',
        'dados_tarefa': 'Lembrete medicamento',
        'max_retries': 5,
        'tentativas_realizadas': 2,
      };

      final ag = Agendamento.fromJson(json);

      expect(ag.id, 1);
      expect(ag.idosoId, 5);
      expect(ag.tipo, 'chamada_voz');
      expect(ag.dataHoraAgendada, DateTime(2026, 3, 15, 14, 0));
      expect(ag.dataHoraRealizada, DateTime(2026, 3, 15, 14, 5));
      expect(ag.status, 'concluido');
      expect(ag.prioridade, 'alta');
      expect(ag.dadosTarefa, 'Lembrete medicamento');
      expect(ag.maxRetries, 5);
      expect(ag.tentativasRealizadas, 2);
    });

    test('usa valores default para campos opcionais', () {
      final json = {
        'id': 2,
        'idoso_id': 3,
        'tipo': 'video',
        'data_hora_agendada': '2026-04-01T10:00:00.000',
        'status': 'agendado',
      };

      final ag = Agendamento.fromJson(json);

      expect(ag.dataHoraRealizada, isNull);
      expect(ag.prioridade, 'normal');
      expect(ag.dadosTarefa, isNull);
      expect(ag.maxRetries, 3);
      expect(ag.tentativasRealizadas, 0);
    });
  });

  group('Agendamento - toJson', () {
    test('serializa corretamente', () {
      final ag = Agendamento(
        id: 10,
        idosoId: 7,
        tipo: 'chamada_voz',
        dataHoraAgendada: DateTime(2026, 5, 1, 9, 0),
        dataHoraRealizada: null,
        status: 'agendado',
        prioridade: 'urgente',
        dadosTarefa: null,
        maxRetries: 3,
        tentativasRealizadas: 0,
      );

      final json = ag.toJson();

      expect(json['id'], 10);
      expect(json['idoso_id'], 7);
      expect(json['tipo'], 'chamada_voz');
      expect(json['data_hora_agendada'], contains('2026-05-01'));
      expect(json['data_hora_realizada'], isNull);
      expect(json['status'], 'agendado');
      expect(json['prioridade'], 'urgente');
      expect(json['dados_tarefa'], isNull);
      expect(json['max_retries'], 3);
      expect(json['tentativas_realizadas'], 0);
    });

    test('serializa dataHoraRealizada quando presente', () {
      final ag = Agendamento(
        id: 1,
        idosoId: 1,
        tipo: 'voz',
        dataHoraAgendada: DateTime(2026, 1, 1),
        dataHoraRealizada: DateTime(2026, 1, 1, 0, 5),
        status: 'concluido',
        prioridade: 'normal',
        maxRetries: 3,
        tentativasRealizadas: 1,
      );

      final json = ag.toJson();
      expect(json['data_hora_realizada'], isNotNull);
      expect(json['data_hora_realizada'], contains('2026-01-01'));
    });
  });

  group('Agendamento - isOverdue', () {
    test('isOverdue true quando data ja passou', () {
      final ag = Agendamento(
        id: 1,
        idosoId: 1,
        tipo: 'voz',
        dataHoraAgendada: DateTime(2020, 1, 1),
        status: 'agendado',
        prioridade: 'normal',
        maxRetries: 3,
        tentativasRealizadas: 0,
      );

      expect(ag.isOverdue, true);
    });

    test('isOverdue false quando data e futura', () {
      final ag = Agendamento(
        id: 1,
        idosoId: 1,
        tipo: 'voz',
        dataHoraAgendada: DateTime(2030, 12, 31),
        status: 'agendado',
        prioridade: 'normal',
        maxRetries: 3,
        tentativasRealizadas: 0,
      );

      expect(ag.isOverdue, false);
    });
  });

  group('Agendamento - canRetry', () {
    test('canRetry true quando tentativas < max', () {
      final ag = Agendamento(
        id: 1,
        idosoId: 1,
        tipo: 'voz',
        dataHoraAgendada: DateTime.now(),
        status: 'falhou',
        prioridade: 'normal',
        maxRetries: 3,
        tentativasRealizadas: 2,
      );

      expect(ag.canRetry, true);
    });

    test('canRetry false quando tentativas >= max', () {
      final ag = Agendamento(
        id: 1,
        idosoId: 1,
        tipo: 'voz',
        dataHoraAgendada: DateTime.now(),
        status: 'falhou',
        prioridade: 'normal',
        maxRetries: 3,
        tentativasRealizadas: 3,
      );

      expect(ag.canRetry, false);
    });

    test('canRetry false quando tentativas > max', () {
      final ag = Agendamento(
        id: 1,
        idosoId: 1,
        tipo: 'voz',
        dataHoraAgendada: DateTime.now(),
        status: 'falhou',
        prioridade: 'normal',
        maxRetries: 3,
        tentativasRealizadas: 5,
      );

      expect(ag.canRetry, false);
    });
  });

  group('Agendamento - roundtrip', () {
    test('fromJson -> toJson -> fromJson preserva dados', () {
      final original = {
        'id': 50,
        'idoso_id': 10,
        'tipo': 'chamada_voz',
        'data_hora_agendada': '2026-06-15T16:00:00.000',
        'data_hora_realizada': null,
        'status': 'agendado',
        'prioridade': 'alta',
        'dados_tarefa': 'Teste',
        'max_retries': 5,
        'tentativas_realizadas': 1,
      };

      final ag1 = Agendamento.fromJson(original);
      final json = ag1.toJson();
      final ag2 = Agendamento.fromJson(json);

      expect(ag2.id, ag1.id);
      expect(ag2.idosoId, ag1.idosoId);
      expect(ag2.tipo, ag1.tipo);
      expect(ag2.status, ag1.status);
      expect(ag2.prioridade, ag1.prioridade);
      expect(ag2.maxRetries, ag1.maxRetries);
      expect(ag2.tentativasRealizadas, ag1.tentativasRealizadas);
    });
  });
}
