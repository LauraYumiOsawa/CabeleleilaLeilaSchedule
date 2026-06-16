import '../entities/entities.dart';

/// Contrato que a camada de domínio conhece.
abstract interface class AgendamentoRepository {
  Future<List<Agendamento>> getAtivos();
  Future<List<Agendamento>> getFinalizados();
  Future<Agendamento?> getById(int id);
  Future<List<SalaoServico>> getServicosDisponiveis();
  Future<List<Agendamento>> getAgendamentosPorCliente(
    String nomeCliente,
    DateTime inicio,
    DateTime fim,
  );
  Future<List<Agendamento>> getAgendamentosPorData(
    DateTime dataInicio,
    DateTime dataFim,
  );
  Future<DesempenhoSemanal> getDesempenhoSemanal(DateTime semanaInicio);
  Future<int> criar(Agendamento agendamento);
  Future<void> atualizar(Agendamento agendamento);
  Future<void> excluir(int id);
}
