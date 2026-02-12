import 'package:flutter_test/flutter_test.dart';
import 'package:eva_mobile/data/models/idoso.dart';

void main() {
  group('Idoso - fromJson', () {
    test('cria Idoso com todos os campos', () {
      final json = {
        'id': 1,
        'nome': 'Dona Maria',
        'data_nascimento': '1945-03-15T00:00:00.000',
        'telefone': '(11) 98765-4321',
        'cpf': '12345678901',
        'device_token': 'token_abc',
        'ativo': true,
        'nivel_cognitivo': 'Leve',
        'limitacoes_auditivas': true,
        'usa_aparelho_auditivo': false,
        'tom_voz': 'Grave',
        'preferencia_horario': 'Manha',
      };

      final idoso = Idoso.fromJson(json);

      expect(idoso.id, 1);
      expect(idoso.nome, 'Dona Maria');
      expect(idoso.dataNascimento, DateTime(1945, 3, 15));
      expect(idoso.telefone, '(11) 98765-4321');
      expect(idoso.cpf, '12345678901');
      expect(idoso.deviceToken, 'token_abc');
      expect(idoso.ativo, true);
      expect(idoso.nivelCognitivo, 'Leve');
      expect(idoso.limitacoesAuditivas, true);
      expect(idoso.usaAparelhoAuditivo, false);
      expect(idoso.tomVoz, 'Grave');
      expect(idoso.preferenciaHorario, 'Manha');
    });

    test('usa valores default para campos opcionais', () {
      final json = {
        'id': 2,
        'nome': 'Seu Joao',
        'data_nascimento': '1940-07-22T00:00:00.000',
        'telefone': '(21) 91234-5678',
        'cpf': '98765432100',
      };

      final idoso = Idoso.fromJson(json);

      expect(idoso.deviceToken, isNull);
      expect(idoso.ativo, true);
      expect(idoso.nivelCognitivo, 'Normal');
      expect(idoso.limitacoesAuditivas, false);
      expect(idoso.usaAparelhoAuditivo, false);
      expect(idoso.tomVoz, 'Normal');
      expect(idoso.preferenciaHorario, 'Qualquer horário');
    });
  });

  group('Idoso - toJson', () {
    test('serializa corretamente para JSON', () {
      final idoso = Idoso(
        id: 5,
        nome: 'Test',
        dataNascimento: DateTime(1950, 1, 1),
        telefone: '(11) 99999-9999',
        cpf: '11122233344',
        deviceToken: 'tok',
        ativo: false,
        nivelCognitivo: 'Moderado',
        limitacoesAuditivas: true,
        usaAparelhoAuditivo: true,
        tomVoz: 'Agudo',
        preferenciaHorario: 'Tarde',
      );

      final json = idoso.toJson();

      expect(json['id'], 5);
      expect(json['nome'], 'Test');
      expect(json['data_nascimento'], contains('1950-01-01'));
      expect(json['telefone'], '(11) 99999-9999');
      expect(json['cpf'], '11122233344');
      expect(json['device_token'], 'tok');
      expect(json['ativo'], false);
      expect(json['nivel_cognitivo'], 'Moderado');
      expect(json['limitacoes_auditivas'], true);
      expect(json['usa_aparelho_auditivo'], true);
      expect(json['tom_voz'], 'Agudo');
      expect(json['preferencia_horario'], 'Tarde');
    });

    test('roundtrip fromJson -> toJson -> fromJson', () {
      final original = {
        'id': 10,
        'nome': 'Roundtrip',
        'data_nascimento': '1960-06-15T00:00:00.000',
        'telefone': '999',
        'cpf': '00000000000',
        'device_token': null,
        'ativo': true,
        'nivel_cognitivo': 'Normal',
        'limitacoes_auditivas': false,
        'usa_aparelho_auditivo': false,
        'tom_voz': 'Normal',
        'preferencia_horario': 'Qualquer horario',
      };

      final idoso1 = Idoso.fromJson(original);
      final json = idoso1.toJson();
      final idoso2 = Idoso.fromJson(json);

      expect(idoso2.id, idoso1.id);
      expect(idoso2.nome, idoso1.nome);
      expect(idoso2.cpf, idoso1.cpf);
      expect(idoso2.ativo, idoso1.ativo);
    });
  });

  group('Idoso - idade', () {
    test('calcula idade corretamente', () {
      final now = DateTime.now();
      final birthYear = now.year - 80;
      final idoso = Idoso(
        id: 1,
        nome: 'Test',
        dataNascimento: DateTime(birthYear, 1, 1),
        telefone: '999',
        cpf: '000',
        ativo: true,
        nivelCognitivo: 'Normal',
        limitacoesAuditivas: false,
        usaAparelhoAuditivo: false,
        tomVoz: 'Normal',
        preferenciaHorario: 'Qualquer',
      );

      expect(idoso.idade, 80);
    });

    test('idade antes do aniversario no ano atual', () {
      final now = DateTime.now();
      // Nasceu daqui a 1 mes -> ainda nao fez aniversario
      final futureMonth = now.month == 12 ? 1 : now.month + 1;
      final birthYear = now.year - 75;

      final idoso = Idoso(
        id: 1,
        nome: 'Test',
        dataNascimento: DateTime(birthYear, futureMonth, 15),
        telefone: '999',
        cpf: '000',
        ativo: true,
        nivelCognitivo: 'Normal',
        limitacoesAuditivas: false,
        usaAparelhoAuditivo: false,
        tomVoz: 'Normal',
        preferenciaHorario: 'Qualquer',
      );

      // Se o mes futuro eh janeiro do proximo ano, a conta muda
      if (futureMonth < now.month) {
        expect(idoso.idade, 75);
      } else {
        expect(idoso.idade, 74);
      }
    });
  });
}
