import 'enums.dart';

/// Serviço oferecido pelo salão (cabelo, barba, etc.).
class SalaoServico {
  final int id;
  final String nome;
  final double preco;
  final int duracaoMinutos;

  const SalaoServico({
    required this.id,
    required this.nome,
    required this.preco,
    required this.duracaoMinutos,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SalaoServico && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Serviço selecionado pelo cliente dentro de um agendamento.
class ServicoSelecionado {
  final int? id;
  final int agendamentoId;
  final int servicoId;
  final String servicoNome;
  final double preco;
  final ServicoStatus status;

  const ServicoSelecionado({
    this.id,
    required this.agendamentoId,
    required this.servicoId,
    required this.servicoNome,
    required this.preco,
    this.status = ServicoStatus.pendente,
  });

  ServicoSelecionado copyWith({
    int? id,
    int? agendamentoId,
    int? servicoId,
    String? servicoNome,
    double? preco,
    ServicoStatus? status,
  }) {
    return ServicoSelecionado(
      id: id ?? this.id,
      agendamentoId: agendamentoId ?? this.agendamentoId,
      servicoId: servicoId ?? this.servicoId,
      servicoNome: servicoNome ?? this.servicoNome,
      preco: preco ?? this.preco,
      status: status ?? this.status,
    );
  }
}

/// Agendamento de cliente no salão.
class Agendamento {
  final int? id;
  final String nomeCliente;
  final String telefoneCliente;
  final DateTime dataAgendada;
  final DateTime dataCriacao;
  final AgendamentoStatus status;
  final List<ServicoSelecionado> servicos;
  final double valorTotal;
  final int? usuarioId;

  const Agendamento({
    this.id,
    required this.nomeCliente,
    required this.telefoneCliente,
    required this.dataAgendada,
    required this.dataCriacao,
    required this.status,
    required this.servicos,
    required this.valorTotal,
    this.usuarioId,
  });

  static const _duracaoServicoMap = {
    1: 30,
    2: 20,
    3: 60,
    4: 45,
    5: 30,
    6: 20,
    7: 25,
    8: 15,
  };

  int get duracaoMinutos {
    return servicos.fold(0, (sum, s) {
      return sum + (_duracaoServicoMap[s.servicoId] ?? 30);
    });
  }

  DateTime get inicio {
    return dataAgendada;
  }

  DateTime get fim {
    return dataAgendada.add(Duration(minutes: duracaoMinutos));
  }

  Agendamento copyWith({
    int? id,
    String? nomeCliente,
    String? telefoneCliente,
    DateTime? dataAgendada,
    DateTime? dataCriacao,
    AgendamentoStatus? status,
    List<ServicoSelecionado>? servicos,
    double? valorTotal,
    int? usuarioId,
  }) {
    return Agendamento(
      id: id ?? this.id,
      nomeCliente: nomeCliente ?? this.nomeCliente,
      telefoneCliente: telefoneCliente ?? this.telefoneCliente,
      dataAgendada: dataAgendada ?? this.dataAgendada,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      status: status ?? this.status,
      servicos: servicos ?? this.servicos,
      valorTotal: valorTotal ?? this.valorTotal,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }

  bool getPodeAlterar() {
    final agora = DateTime.now();
    final diff = dataAgendada.difference(agora).inDays;
    return status == AgendamentoStatus.pendente && diff >= 2;
  }

  bool podeSerAlteradoPor({required int? usuarioLogadoId, required bool isAdmin}) {
    if (!getPodeAlterar()) return false;
    
    if (isAdmin) return true;
    
    return usuarioId == usuarioLogadoId;
  }
}

/// Métricas semanais para o painel gerencial.
class DesempenhoSemanal {
  final DateTime semanaInicio;
  final int totalAgendamentos;
  final int totalConcluidos;
  final int totalPendentes;
  final int totalConfirmados;
  final double receitaConfirmada;
  final double receitaPendente;

  final int totalCancelados;

  const DesempenhoSemanal({
    required this.semanaInicio,
    this.totalAgendamentos = 0,
    this.totalConcluidos = 0,
    this.totalPendentes = 0,
    this.totalConfirmados = 0,
    this.totalCancelados = 0,
    this.receitaConfirmada = 0.0,
    this.receitaPendente = 0.0,
  });
}
