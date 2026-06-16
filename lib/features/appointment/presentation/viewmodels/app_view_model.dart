import 'package:flutter/foundation.dart';

import '../../../auth/presentation/services/auth_manager.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/agendamento_repository.dart';

sealed class AppState {}

class AppLoading extends AppState {}

class AppLoaded extends AppState {
  final List<Agendamento> ativos;
  final List<Agendamento> finalizados;
  final List<SalaoServico> servicosDisponiveis;
  final Agendamento? selecionado;
  final DesempenhoSemanal? desempenho;

  AppLoaded({
    this.ativos = const [],
    this.finalizados = const [],
    this.servicosDisponiveis = const [],
    this.selecionado,
    this.desempenho,
  });

  AppLoaded copyWith({
    List<Agendamento>? ativos,
    List<Agendamento>? finalizados,
    List<SalaoServico>? servicosDisponiveis,
    Agendamento? selecionado,
    DesempenhoSemanal? desempenho,
  }) {
    return AppLoaded(
      ativos: ativos ?? this.ativos,
      finalizados: finalizados ?? this.finalizados,
      servicosDisponiveis: servicosDisponiveis ?? this.servicosDisponiveis,
      selecionado: selecionado ?? this.selecionado,
      desempenho: desempenho ?? this.desempenho,
    );
  }
}

class AppError extends AppState {
  final String message;
  AppError(this.message);
}

class AppViewModel extends ChangeNotifier {
  final AgendamentoRepository _repo;

  AppViewModel(this._repo);

  AppState _state = AppLoading();
  AppState get state => _state;

  AppLoaded? get _loaded => _state is AppLoaded ? _state as AppLoaded : null;

  void _notify() => notifyListeners();

  Future<void> carregarTudo() async {
    _state = AppLoading();
    _notify();
    try {
      final results = await Future.wait([
        _repo.getAtivos(),
        _repo.getFinalizados(),
        _repo.getServicosDisponiveis(),
      ]);
      final ativos = results[0] as List<Agendamento>;
      final finalizados = results[1] as List<Agendamento>;
      final servicos = results[2] as List<SalaoServico>;
      final old = _loaded;
      _state = AppLoaded(
        ativos: _ordenar(ativos),
        finalizados: finalizados,
        servicosDisponiveis: servicos,
        selecionado: old?.selecionado,
        desempenho: old?.desempenho,
      );
    } catch (e) {
      _state = AppError(e.toString());
    }
    _notify();
  }

  Future<void> carregarDesempenhoSemana(DateTime semanaInicio) async {
    try {
      final d = await _repo.getDesempenhoSemanal(semanaInicio);
      final currentLoaded = _loaded ?? AppLoaded();
      _state = currentLoaded.copyWith(desempenho: d);
      _notify();
    } catch (e) {
      _state = AppError(e.toString());
      _notify();
    }
  }

  Future<void> carregarDetalhe(int id) async {
    try {
      final ag = await _repo.getById(id);
      final currentLoaded = _loaded ?? AppLoaded();
      _state = currentLoaded.copyWith(selecionado: ag);
      _notify();
    } catch (e) {
      _state = AppError(e.toString());
      _notify();
    }
  }

  Future<void> criarAgendamento(Agendamento ag) async {
    await _repo.criar(ag);
    await carregarTudo();
  }

  Future<void> atualizarAgendamento(Agendamento ag) async {
    await _repo.atualizar(ag);
    await carregarTudo();
  }

  Future<void> excluirAgendamento(int id) async {
    await _repo.excluir(id);
    await carregarTudo();
  }

  Future<String?> confirmarAgendamento(int id) async {
    final ag = await _repo.getById(id);
    if (ag == null) return 'Agendamento não encontrado.';
    if (_loaded != null) {
      final ativosSemEste =
          _loaded!.ativos.where((a) => a.id != id).toList();
      final agConfirmado = ag.copyWith(status: AgendamentoStatus.confirmado);
      final erro = _verificarConflito(agConfirmado, ativosSemEste);
      if (erro != null) return erro;
    }
    await _repo.atualizar(ag.copyWith(status: AgendamentoStatus.confirmado));
    await carregarTudo();
    return null;
  }

  Future<void> iniciarAgendamento(int id) async {
    final ag = await _repo.getById(id);
    if (ag != null) {
      await _repo.atualizar(
        ag.copyWith(status: AgendamentoStatus.em_andamento),
      );
      await carregarTudo();
    }
  }

  Future<void> concluirAgendamento(int id) async {
    final ag = await _repo.getById(id);
    if (ag != null) {
      await _repo.atualizar(
        ag.copyWith(
          status: AgendamentoStatus.concluido,
          servicos: ag.servicos
              .map((s) => s.copyWith(status: ServicoStatus.concluido))
              .toList(),
        ),
      );
      await carregarTudo();
    }
  }

  Future<void> cancelarAgendamento(int id) async {
    final ag = await _repo.getById(id);
    if (ag != null) {
      await _repo.atualizar(ag.copyWith(status: AgendamentoStatus.cancelado));
      await carregarTudo();
    }
  }

  Future<void> reverterAgendamento(int id) async {
    final ag = await _repo.getById(id);
    if (ag == null) return;
    AgendamentoStatus statusAnterior;
    switch (ag.status) {
      case AgendamentoStatus.confirmado:
        statusAnterior = AgendamentoStatus.pendente;
      case AgendamentoStatus.em_andamento:
        statusAnterior = AgendamentoStatus.confirmado;
      default:
        return;
    }
    await _repo.atualizar(ag.copyWith(status: statusAnterior));
    await carregarTudo();
  }

  Future<void> alterarStatusServico(
    int agendamentoId,
    int servicoId,
    ServicoStatus novoStatus,
  ) async {
    final ag = await _repo.getById(agendamentoId);
    if (ag != null) {
      final novosServicos = ag.servicos.map((s) {
        if (s.id == servicoId) return s.copyWith(status: novoStatus);
        return s;
      }).toList();
      await _repo.atualizar(ag.copyWith(servicos: novosServicos));
      await carregarTudo();
    }
  }

  Future<DateTime?> getSugestaoMesmoDia(String nomeCliente) async {
    final inicioSemana = _inicioDaSemana(DateTime.now());
    final fimSemana = inicioSemana.add(const Duration(days: 7));
    final existentes = await _repo.getAgendamentosPorCliente(
      nomeCliente,
      inicioSemana,
      fimSemana,
    );
    if (existentes.isEmpty) return null;
    existentes.sort((a, b) => a.dataAgendada.compareTo(b.dataAgendada));
    return existentes.first.dataAgendada;
  }

  bool podeAlterar(Agendamento ag) => ag.getPodeAlterar();

  String? validarAlteracaoAgendamento(Agendamento ag) {
    final authManager = AuthManager();
    final usuarioId = authManager.currentUser?.id;
    final isAdmin = authManager.isAdmin;

    if (ag.status != AgendamentoStatus.pendente) {
      return 'Apenas agendamentos PENDENTES podem ser alterados.';
    }

    final agora = DateTime.now();
    final diff = ag.dataAgendada.difference(agora).inDays;
    if (diff < 2) {
      return 'Alteração permitida apenas com 2 dias de antecedência. Entre em contato por telefone.';
    }

    if (!isAdmin && ag.usuarioId != usuarioId) {
      return 'Você não tem permissão para alterar este agendamento.';
    }

    return null;
  }

  bool podeAlterarAgendamento(Agendamento ag) {
    return validarAlteracaoAgendamento(ag) == null;
  }

  static DateTime _inicioDaSemana(DateTime d) {
    final diff = d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day - diff);
  }

  String? _verificarConflito(
    Agendamento ag,
    List<Agendamento> ativos,
  ) {
    if (ag.status == AgendamentoStatus.cancelado ||
        ag.status == AgendamentoStatus.concluido) {
      return null;
    }
    final novoInicio = ag.inicio;
    final novoFim = ag.fim;
    for (final existente in ativos) {
      if (existente.status == AgendamentoStatus.cancelado ||
          existente.status == AgendamentoStatus.concluido) {
        continue;
      }
      final existsInicio = existente.inicio;
      final existsFim = existente.fim;
      if (novoInicio.isBefore(existsFim) && novoFim.isAfter(existsInicio)) {
        return 'Conflito de horário com o agendamento de ${existente.nomeCliente} às ${existsInicio.hour.toString().padLeft(2, '0')}:${existsInicio.minute.toString().padLeft(2, '0')} - ${existsFim.hour.toString().padLeft(2, '0')}:${existsFim.minute.toString().padLeft(2, '0')}. Próximo horário disponível: ${existsFim.hour.toString().padLeft(2, '0')}:${existsFim.minute.toString().padLeft(2, '0')}.';
      }
    }
    return null;
  }

  List<Agendamento> _ordenar(List<Agendamento> items) {
    final copy = List<Agendamento>.from(items);
    copy.sort((a, b) => a.dataAgendada.compareTo(b.dataAgendada));
    return copy;
  }
}
