import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/agendamento_repository.dart';
import '../services/agendamento_service.dart';

class AgendamentoRepositoryImpl implements AgendamentoRepository {
  final AgendamentoService _service;

  AgendamentoRepositoryImpl({AgendamentoService? service})
    : _service = service ?? AgendamentoService();

  // ── mapeamento ──────────────────────────────────────────────────────

  Agendamento _fromMap(
    Map<String, dynamic> m,
    List<ServicoSelecionado> servicos,
  ) {
    return Agendamento(
      id: (m['id'] as num?)?.toInt(),
      nomeCliente: m['nome_cliente'] as String? ?? '',
      telefoneCliente: m['telefone'] as String? ?? '',
      dataAgendada: DateTime.parse(m['data_agendada'] as String),
      dataCriacao: DateTime.parse(m['data_criacao'] as String),
      status: AgendamentoStatusExt.fromChar(m['status'] as String? ?? 'P'),
      servicos: servicos,
      valorTotal: (m['valor_total'] as num?)?.toDouble() ?? 0.0,
      usuarioId: m['usuario_id'] as int?,
    );
  }

  ServicoSelecionado _servicoFromMap(Map<String, dynamic> m) {
    return ServicoSelecionado(
      id: (m['id'] as num?)?.toInt(),
      agendamentoId: (m['agendamento_id'] as num?)?.toInt() ?? 0,
      servicoId: (m['servico_id'] as num?)?.toInt() ?? 0,
      servicoNome: m['servico_nome'] as String? ?? '',
      preco: (m['preco'] as num?)?.toDouble() ?? 0.0,
      status: ServicoStatusExt.fromChar(m['status_servico'] as String? ?? 'P'),
    );
  }

  // ── contrato ────────────────────────────────────────────────────────

  @override
  Future<List<Agendamento>> getAtivos() async {
    final rows = await _service.queryAgendamentos();
    return _hydrated(rows);
  }

  @override
  Future<List<Agendamento>> getFinalizados() async {
    final rows = await _service.queryAgendamentos(
      where: 'status IN (?, ?)',
      whereArgs: ['F', 'X'],
    );
    return _hydrated(rows);
  }

  Future<List<Agendamento>> _hydrated(List<Map<String, dynamic>> rows) async {
    final result = <Agendamento>[];
    for (final r in rows) {
      final id = (r['id'] as num?)?.toInt() ?? 0;
      final servRows = await _service.queryServicosByAgendamento(id);
      final servicos = servRows.map(_servicoFromMap).toList();
      result.add(_fromMap(r, servicos));
    }
    return result;
  }

  @override
  Future<Agendamento?> getById(int id) async {
    final rows = await _service.queryAgendamentos(
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    final servRows = await _service.queryServicosByAgendamento(id);
    final servicos = servRows.map(_servicoFromMap).toList();
    return _fromMap(rows.first, servicos);
  }

  @override
  Future<List<SalaoServico>> getServicosDisponiveis() async {
    final rows = await _service.queryServicosDisponiveis();
    return rows
        .map(
          (m) => SalaoServico(
            id: (m['id'] as num?)?.toInt() ?? 0,
            nome: m['nome'] as String? ?? '',
            preco: (m['preco'] as num?)?.toDouble() ?? 0.0,
            duracaoMinutos: (m['duracao_minutos'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  @override
  Future<List<Agendamento>> getAgendamentosPorCliente(
    String nomeCliente,
    DateTime inicio,
    DateTime fim,
  ) async {
    final rows = await _service.queryAgendamentos(
      where: 'nome_cliente = ? AND data_agendada >= ? AND data_agendada < ?',
      whereArgs: [nomeCliente, inicio.toIso8601String(), fim.toIso8601String()],
    );
    return _hydrated(rows);
  }

  @override
  Future<List<Agendamento>> getAgendamentosPorData(
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    final rows = await _service.queryAgendamentosPorData(dataInicio, dataFim);
    return _hydrated(rows);
  }

  @override
  Future<DesempenhoSemanal> getDesempenhoSemanal(DateTime semanaInicio) async {
    final semanaFim = semanaInicio.add(const Duration(days: 7));
    final m = await _service.queryCountReceita(semanaInicio, semanaFim);
    return DesempenhoSemanal(
      semanaInicio: semanaInicio,
      totalAgendamentos: (m['total'] as num?)?.toInt() ?? 0,
      totalConcluidos: (m['concluidos'] as num?)?.toInt() ?? 0,
      totalPendentes: (m['pendentes'] as num?)?.toInt() ?? 0,
      totalConfirmados: (m['confirmados'] as num?)?.toInt() ?? 0,
      totalCancelados: (m['cancelados'] as num?)?.toInt() ?? 0,
      receitaConfirmada: (m['receitaConfirmada'] as num?)?.toDouble() ?? 0.0,
      receitaPendente: (m['receitaPendente'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Future<int> criar(Agendamento agendamento) async {
    final id = await _service.insertAgendamento({
      'nome_cliente': agendamento.nomeCliente,
      'telefone': agendamento.telefoneCliente,
      'data_agendada': agendamento.dataAgendada.toIso8601String(),
      'data_criacao': agendamento.dataCriacao.toIso8601String(),
      'status': agendamento.status.toChar(),
      'valor_total': agendamento.valorTotal,
      'usuario_id': agendamento.usuarioId,
    });
    final agId = id;
    for (final s in agendamento.servicos) {
      await _service.insertServico({
        'agendamento_id': agId,
        'servico_id': s.servicoId,
        'servico_nome': s.servicoNome,
        'preco': s.preco,
        'status_servico': s.status.toChar(),
      });
    }
    return agId;
  }

  @override
  Future<void> atualizar(Agendamento agendamento) async {
    if (agendamento.id == null) return;
    await _service.updateAgendamento(agendamento.id!, {
      'nome_cliente': agendamento.nomeCliente,
      'telefone': agendamento.telefoneCliente,
      'data_agendada': agendamento.dataAgendada.toIso8601String(),
      'status': agendamento.status.toChar(),
      'valor_total': agendamento.valorTotal,
      'usuario_id': agendamento.usuarioId,
    });
    for (final s in agendamento.servicos) {
      if (s.id != null) {
        await _service.updateServico(s.id!, {
          'servico_id': s.servicoId,
          'servico_nome': s.servicoNome,
          'preco': s.preco,
          'status_servico': s.status.toChar(),
        });
      }
    }
  }

  @override
  Future<void> excluir(int id) async {
    await _service.deleteAgendamento(id);
  }
}
