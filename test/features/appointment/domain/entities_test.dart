import 'package:flutter_test/flutter_test.dart';
import 'package:cabeleleilaLeila/features/appointment/domain/entities/entities.dart';
import 'package:cabeleleilaLeila/features/appointment/domain/entities/enums.dart';

void main() {
  group('Agendamento', () {
    final base = Agendamento(
      id: 1,
      nomeCliente: 'Maria Silva',
      telefoneCliente: '(11) 99999-9999',
      dataAgendada: DateTime(2025, 12, 31, 14, 0),
      dataCriacao: DateTime(2025, 1, 1),
      status: AgendamentoStatus.pendente,
      servicos: const [
        ServicoSelecionado(
          agendamentoId: 1,
          servicoId: 1,
          servicoNome: 'Corte Feminino',
          preco: 45.0,
        ),
      ],
      valorTotal: 45.0,
    );

    test('copyWith mantém campos não alterados', () {
      final copia = base.copyWith(status: AgendamentoStatus.confirmado);
      expect(copia.nomeCliente, base.nomeCliente);
      expect(copia.status, AgendamentoStatus.confirmado);
    });

    test('podeAlterar retorna true quando >= 2 dias', () {
      final futuro = base.copyWith(
        dataAgendada: DateTime.now().add(const Duration(days: 3)),
      );
      expect(futuro.getPodeAlterar(), isTrue);
    });

    test('podeAlterar retorna false quando < 2 dias', () {
      final proximo = base.copyWith(
        dataAgendada: DateTime.now().add(const Duration(days: 1)),
      );
      expect(proximo.getPodeAlterar(), isFalse);
    });

    test('podeAlterar retorna false quando não é PENDENTE', () {
      final confirmado = base.copyWith(
        dataAgendada: DateTime.now().add(const Duration(days: 3)),
        status: AgendamentoStatus.confirmado,
      );
      expect(confirmado.getPodeAlterar(), isFalse);
    });

    test('podeSerAlteradoPor retorna true para admin com >= 2 dias', () {
      final futuro = base.copyWith(
        dataAgendada: DateTime.now().add(const Duration(days: 3)),
        usuarioId: 999,
      );
      expect(
        futuro.podeSerAlteradoPor(usuarioLogadoId: 1, isAdmin: true),
        isTrue,
      );
    });

    test('podeSerAlteradoPor retorna false para admin com < 2 dias', () {
      final proximo = base.copyWith(
        dataAgendada: DateTime.now().add(const Duration(days: 1)),
        usuarioId: 999,
      );
      expect(
        proximo.podeSerAlteradoPor(usuarioLogadoId: 1, isAdmin: true),
        isFalse,
      );
    });

    test('podeSerAlteradoPor retorna true para dono com >= 2 dias', () {
      final futuro = base.copyWith(
        dataAgendada: DateTime.now().add(const Duration(days: 3)),
        usuarioId: 1,
      );
      expect(
        futuro.podeSerAlteradoPor(usuarioLogadoId: 1, isAdmin: false),
        isTrue,
      );
    });

    test('podeSerAlteradoPor retorna false para não-dono', () {
      final futuro = base.copyWith(
        dataAgendada: DateTime.now().add(const Duration(days: 3)),
        usuarioId: 999,
      );
      expect(
        futuro.podeSerAlteradoPor(usuarioLogadoId: 1, isAdmin: false),
        isFalse,
      );
    });

    test('podeSerAlteradoPor retorna false quando não é PENDENTE', () {
      final confirmado = base.copyWith(
        dataAgendada: DateTime.now().add(const Duration(days: 3)),
        status: AgendamentoStatus.confirmado,
        usuarioId: 1,
      );
      expect(
        confirmado.podeSerAlteradoPor(usuarioLogadoId: 1, isAdmin: false),
        isFalse,
      );
    });
  });

  group('ServicoSelecionado', () {
    test('copyWith atualiza status corretamente', () {
      final s = const ServicoSelecionado(
        agendamentoId: 1,
        servicoId: 1,
        servicoNome: 'Corte',
        preco: 35.0,
        status: ServicoStatus.pendente,
      );
      final atualizado = s.copyWith(status: ServicoStatus.em_andamento);
      expect(atualizado.status, ServicoStatus.em_andamento);
      expect(atualizado.servicoNome, 'Corte');
    });
  });

  group('AgendamentoStatus', () {
    test('toLabel retorna strings corretas', () {
      expect(AgendamentoStatus.pendente.toLabel(), 'Pendente');
      expect(AgendamentoStatus.confirmado.toLabel(), 'Confirmado');
      expect(AgendamentoStatus.em_andamento.toLabel(), 'Em Andamento');
      expect(AgendamentoStatus.concluido.toLabel(), 'Concluído');
      expect(AgendamentoStatus.cancelado.toLabel(), 'Cancelado');
    });

    test('toChar/fromChar são inversos', () {
      for (final s in AgendamentoStatus.values) {
        expect(AgendamentoStatusExt.fromChar(s.toChar()), s);
      }
    });
  });

  group('ServicoStatus', () {
    test('toLabel retorna strings corretas', () {
      expect(ServicoStatus.pendente.toLabel(), 'Pendente');
      expect(ServicoStatus.em_andamento.toLabel(), 'Em Andamento');
      expect(ServicoStatus.concluido.toLabel(), 'Concluído');
    });

    test('toChar/fromChar são inversos', () {
      for (final s in ServicoStatus.values) {
        expect(ServicoStatusExt.fromChar(s.toChar()), s);
      }
    });
  });
}
