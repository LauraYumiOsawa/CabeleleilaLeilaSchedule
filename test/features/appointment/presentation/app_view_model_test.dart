import 'package:flutter_test/flutter_test.dart';
import 'package:projetoquerinop2/features/appointment/domain/entities/entities.dart';
import 'package:projetoquerinop2/features/appointment/domain/entities/enums.dart';
import 'package:projetoquerinop2/features/appointment/domain/repositories/agendamento_repository.dart';
import 'package:projetoquerinop2/features/appointment/presentation/viewmodels/app_view_model.dart';

class FakeAgendamentoRepository implements AgendamentoRepository {
  final List<Agendamento> _store = [];
  int _nextId = 1;

  List<SalaoServico> servicos = const [
    SalaoServico(
      id: 1,
      nome: 'Corte Feminino',
      preco: 45.0,
      duracaoMinutos: 30,
    ),
    SalaoServico(
      id: 2,
      nome: 'Corte Masculino',
      preco: 35.0,
      duracaoMinutos: 20,
    ),
    SalaoServico(
      id: 3,
      nome: 'Colora\u00e7\u00e3o',
      preco: 120.0,
      duracaoMinutos: 60,
    ),
  ];

  @override
  Future<List<Agendamento>> getAtivos() async => _store
      .where(
        (a) =>
            a.status != AgendamentoStatus.concluido &&
            a.status != AgendamentoStatus.cancelado,
      )
      .toList();

  @override
  Future<List<Agendamento>> getFinalizados() async =>
      _store.where((a) => a.status == AgendamentoStatus.concluido || a.status == AgendamentoStatus.cancelado).toList();

  @override
  Future<Agendamento?> getById(int id) async {
    final idx = _store.indexWhere((a) => a.id == id);
    return idx != -1 ? _store[idx] : null;
  }

  @override
  Future<List<SalaoServico>> getServicosDisponiveis() async => servicos;

  @override
  Future<List<Agendamento>> getAgendamentosPorCliente(
    String nomeCliente,
    DateTime inicio,
    DateTime fim,
  ) async {
    return _store.where((a) {
      return a.nomeCliente == nomeCliente &&
          a.dataAgendada.isAfter(inicio.subtract(const Duration(days: 1))) &&
          a.dataAgendada.isBefore(fim.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<List<Agendamento>> getAgendamentosPorData(
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    return _store
        .where((a) {
          return a.dataAgendada.isAfter(dataInicio) &&
              a.dataAgendada.isBefore(dataFim) &&
              a.status != AgendamentoStatus.concluido &&
              a.status != AgendamentoStatus.cancelado;
        })
        .toList();
  }

  @override
  Future<DesempenhoSemanal> getDesempenhoSemanal(DateTime semanaInicio) async {
    final fim = semanaInicio.add(const Duration(days: 7));
    final semana = _store.where((a) {
      return a.dataAgendada.isAfter(
            semanaInicio.subtract(const Duration(days: 1)),
          ) &&
          a.dataAgendada.isBefore(fim.add(const Duration(days: 1)));
    }).toList();
    return DesempenhoSemanal(
      semanaInicio: semanaInicio,
      totalAgendamentos: semana.length,
      totalConcluidos: semana
          .where((a) => a.status == AgendamentoStatus.concluido)
          .length,
      totalPendentes: semana
          .where((a) => a.status == AgendamentoStatus.pendente)
          .length,
      totalConfirmados: semana
          .where((a) =>
              a.status == AgendamentoStatus.confirmado ||
              a.status == AgendamentoStatus.em_andamento)
          .length,
      receitaConfirmada: semana
          .where((a) => a.status == AgendamentoStatus.concluido)
          .fold(0.0, (s, a) => s + a.valorTotal),
      receitaPendente: semana
          .where((a) =>
              a.status == AgendamentoStatus.pendente ||
              a.status == AgendamentoStatus.confirmado)
          .fold(0.0, (s, a) => s + a.valorTotal),
    );
  }

  @override
  Future<int> criar(Agendamento ag) async {
    final id = _nextId++;
    _store.add(ag.copyWith(id: id));
    return id;
  }

  @override
  Future<void> atualizar(Agendamento ag) async {
    final idx = _store.indexWhere((a) => a.id == ag.id);
    if (idx != -1) _store[idx] = ag;
  }

  @override
  Future<void> excluir(int id) async => _store.removeWhere((a) => a.id == id);
}

Agendamento _make({
  int? id,
  AgendamentoStatus status = AgendamentoStatus.pendente,
  DateTime? dataAgendada,
}) {
  return Agendamento(
    id: id,
    nomeCliente: 'Maria Silva',
    telefoneCliente: '999999999',
    dataAgendada: dataAgendada ?? DateTime.now().add(const Duration(days: 5)),
    dataCriacao: DateTime.now(),
    status: status,
    servicos: const [
      ServicoSelecionado(
        agendamentoId: 0,
        servicoId: 1,
        servicoNome: 'Corte',
        preco: 45.0,
      ),
    ],
    valorTotal: 45.0,
  );
}

void main() {
  late FakeAgendamentoRepository repo;
  late AppViewModel vm;

  setUp(() {
    repo = FakeAgendamentoRepository();
    vm = AppViewModel(repo);
  });

  tearDown(() => vm.dispose());

  group('Estado inicial', () {
    test('começa em AppLoading', () => expect(vm.state, isA<AppLoading>()));
  });

  group('carregarTudo', () {
    test('transiciona para AppLoaded vazio', () async {
      await vm.carregarTudo();
      expect(vm.state, isA<AppLoaded>());
      final s = vm.state as AppLoaded;
      expect(s.ativos, isEmpty);
      expect(s.servicosDisponiveis.length, 3);
    });

    test('reflete agendamentos no repositório', () async {
      await repo.criar(_make());
      await vm.carregarTudo();
      expect((vm.state as AppLoaded).ativos.length, 1);
    });
  });

  group('criarAgendamento', () {
    test('adiciona e atualiza estado', () async {
      await vm.criarAgendamento(_make());
      expect((vm.state as AppLoaded).ativos.length, 1);
    });
  });

  group('status workflow', () {
    setUp(() async {
      await repo.criar(_make(id: 1));
      await vm.carregarTudo();
    });

    test('confirmarAgendamento muda status', () async {
      await vm.confirmarAgendamento(1);
      final loaded = vm.state as AppLoaded;
      expect(loaded.ativos.first.status, AgendamentoStatus.confirmado);
    });

    test('iniciarAgendamento muda para em_andamento', () async {
      await vm.confirmarAgendamento(1);
      await vm.iniciarAgendamento(1);
      expect(
        (vm.state as AppLoaded).ativos.first.status,
        AgendamentoStatus.em_andamento,
      );
    });

    test('concluirAgendamento move para finalizados', () async {
      await vm.concluirAgendamento(1);
      final loaded = vm.state as AppLoaded;
      expect(loaded.ativos, isEmpty);
      expect(loaded.finalizados.length, 1);
    });

    test('cancelarAgendamento remove dos ativos', () async {
      await vm.cancelarAgendamento(1);
      final loaded = vm.state as AppLoaded;
      expect(loaded.ativos, isEmpty);
    });
  });

  group('getSugestaoMesmoDia', () {
    test('retorna data existente na semana', () async {
      final dataSemana = DateTime.now().add(const Duration(days: 3));
      await repo.criar(
        Agendamento(
          nomeCliente: 'Jo\u00e3o',
          telefoneCliente: '999',
          dataAgendada: dataSemana,
          dataCriacao: DateTime.now(),
          status: AgendamentoStatus.pendente,
          servicos: const [],
          valorTotal: 0,
        ),
      );
      final sugestao = await vm.getSugestaoMesmoDia('Jo\u00e3o');
      expect(sugestao, isNotNull);
      expect(sugestao, dataSemana);
    });

    test(
      'retorna null quando n\u00e3o h\u00e1 agendamento na semana',
      () async {
        final sugestao = await vm.getSugestaoMesmoDia('Outra Pessoa');
        expect(sugestao, isNull);
      },
    );
  });

  group('podeAlterar', () {
    test('retorna true para agendamento >= 2 dias', () {
      final ag = _make(
        dataAgendada: DateTime.now().add(const Duration(days: 3)),
      );
      expect(vm.podeAlterar(ag), isTrue);
    });

    test('retorna false para agendamento < 2 dias', () {
      final ag = _make(
        dataAgendada: DateTime.now().add(const Duration(days: 1)),
      );
      expect(vm.podeAlterar(ag), isFalse);
    });
  });

  group('desempenho semanal', () {
    test('calcula m\u00e9tricas corretamente', () async {
      final inicio = DateTime.now();
      final dia3 = inicio.add(const Duration(days: 3));
      await repo.criar(
        Agendamento(
          nomeCliente: 'Ana',
          telefoneCliente: '999',
          dataAgendada: dia3,
          dataCriacao: DateTime.now(),
          status: AgendamentoStatus.concluido,
          servicos: const [
            ServicoSelecionado(
              agendamentoId: 0,
              servicoId: 1,
              servicoNome: 'Corte',
              preco: 45.0,
            ),
          ],
          valorTotal: 45.0,
        ),
      );
      await repo.criar(
        Agendamento(
          nomeCliente: 'Bia',
          telefoneCliente: '999',
          dataAgendada: dia3,
          dataCriacao: DateTime.now(),
          status: AgendamentoStatus.pendente,
          servicos: const [
            ServicoSelecionado(
              agendamentoId: 0,
              servicoId: 2,
              servicoNome: 'Barba',
              preco: 20.0,
            ),
          ],
          valorTotal: 20.0,
        ),
      );
      await vm.carregarTudo();
      await vm.carregarDesempenhoSemana(inicio);
      final d = (vm.state as AppLoaded).desempenho;
      expect(d, isNotNull);
      expect(d!.totalAgendamentos, 2);
      expect(d.totalConcluidos, 1);
      expect(d.totalPendentes, 1);
      expect(d.receitaConfirmada, 45.0);
    });
  });

  group('excluirAgendamento', () {
    test('remove e recarrega', () async {
      await repo.criar(_make(id: 1));
      await vm.carregarTudo();
      await vm.excluirAgendamento(1);
      expect((vm.state as AppLoaded).ativos, isEmpty);
    });
  });
}
