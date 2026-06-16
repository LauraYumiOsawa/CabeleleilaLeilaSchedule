import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../viewmodels/app_view_model.dart';

/// Painel operacional da Leila — confirma, inicia, conclui, altera status de serviços.
class PainelOperacionalPage extends StatefulWidget {
  final AppViewModel viewModel;

  const PainelOperacionalPage({super.key, required this.viewModel});

  @override
  State<PainelOperacionalPage> createState() => _PainelOperacionalPageState();
}

class _PainelOperacionalPageState extends State<PainelOperacionalPage> {
  String _filtroStatus = 'Todos';
  String _filtroNome = '';
  int _semanaOffset = 0;

  final List<String> _statusFiltros = [
    'Todos',
    AgendamentoStatus.pendente.toLabel(),
    AgendamentoStatus.confirmado.toLabel(),
    AgendamentoStatus.em_andamento.toLabel(),
    AgendamentoStatus.concluido.toLabel(),
    AgendamentoStatus.cancelado.toLabel(),
  ];

  AgendamentoStatus? _statusEnum(String label) {
    switch (label) {
      case 'Todos':
        return null;
      case 'Pendente':
        return AgendamentoStatus.pendente;
      case 'Confirmado':
        return AgendamentoStatus.confirmado;
      case 'Em Andamento':
        return AgendamentoStatus.em_andamento;
      case 'Cancelado':
        return AgendamentoStatus.cancelado;
      case 'Concluído':
        return AgendamentoStatus.concluido;
      default:
        return null;
    }
  }

  DateTime get _semanaInicio {
    final now = DateTime.now();
    final diff = now.weekday - DateTime.monday;
    return DateTime(
      now.year,
      now.month,
      now.day - diff,
    ).subtract(Duration(days: _semanaOffset * 7));
  }

  void _navegarSemana(int delta) {
    setState(() {
      _semanaOffset += delta;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final state = widget.viewModel.state;
        if (state is! AppLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        var items = state.ativos;
        final statusFilter = _statusEnum(_filtroStatus);
        if (statusFilter != null) {
          items = items.where((a) => a.status == statusFilter).toList();
        }
        if (_filtroNome.isNotEmpty) {
          final query = _filtroNome.toLowerCase();
          items = items
              .where(
                (a) => a.nomeCliente.toLowerCase().contains(query) ||
                    a.telefoneCliente.contains(_filtroNome),
              )
              .toList();
        }

        if (_semanaOffset != 0) {
          final inicio = _semanaInicio;
          final fim = inicio.add(const Duration(days: 7));
          items = items
              .where(
                (a) => a.dataAgendada.isAfter(inicio.subtract(const Duration(days: 1))) &&
                    a.dataAgendada.isBefore(fim.add(const Duration(days: 1))),
              )
              .toList();
        }

        items.sort((a, b) => a.dataAgendada.compareTo(b.dataAgendada));

        final inicioFormatado =
            '${_semanaInicio.day}/${_semanaInicio.month}/${_semanaInicio.year}';
        final fimFormatado =
            '${_semanaInicio.add(const Duration(days: 6)).day}/${_semanaInicio.add(const Duration(days: 6)).month}/${_semanaInicio.add(const Duration(days: 6)).year}';

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _semanaOffset <= 0
                        ? null
                        : () => _navegarSemana(-1),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Semana de $inicioFormatado a $fimFormatado',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_semanaOffset > 0)
                          TextButton(
                            onPressed: () => setState(() => _semanaOffset = 0),
                            child: const Text(
                              'Semana atual',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _navegarSemana(1),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 180,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Buscar cliente',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (v) => setState(() => _filtroNome = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _filtroStatus,
                      items: _statusFiltros
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _filtroStatus = v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum agendamento encontrado',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemBuilder: (context, index) {
                        final ag = items[index];
                        return _AdminAgendamentoCard(
                          agendamento: ag,
                          viewModel: widget.viewModel,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminAgendamentoCard extends StatelessWidget {
  final Agendamento agendamento;
  final AppViewModel viewModel;

  const _AdminAgendamentoCard({
    required this.agendamento,
    required this.viewModel,
  });

  void _confirmarExclusao(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Agendamento'),
        content: Text(
          'Deseja realmente excluir o agendamento de "${agendamento.nomeCliente}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.excluirAgendamento(agendamento.id!);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final podeAlterar = agendamento.getPodeAlterar();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _corStatus(agendamento.status),
          child: Text(
            agendamento.nomeCliente[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          agendamento.nomeCliente,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${agendamento.dataAgendada.day}/${agendamento.dataAgendada.month}/${agendamento.dataAgendada.year} '
          '${agendamento.dataAgendada.hour.toString().padLeft(2, '0')}:${agendamento.dataAgendada.minute.toString().padLeft(2, '0')}} - '
          'R\$ ${agendamento.valorTotal.toStringAsFixed(2)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: 80,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _corStatus(agendamento.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              agendamento.status.toLabel(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _corStatus(agendamento.status),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Telefone: ${agendamento.telefoneCliente}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!podeAlterar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Falta menos de 2 dias — alteração apenas por telefone.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ),
                const Text(
                  'Serviços:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                ...agendamento.servicos.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.style, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.servicoNome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'R\$ ${s.preco.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                    if (agendamento.status == AgendamentoStatus.pendente)
                      _btn(
                        label: 'Confirmar',
                        icon: Icons.check,
                        color: Colors.blue,
                      onTap: () async {
                        final erro =
                            await viewModel.confirmarAgendamento(agendamento.id!);
                        if (erro != null && context.mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Conflito de Horário'),
                              content: Text(erro),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      ),
                    if (agendamento.status == AgendamentoStatus.confirmado)
                      _btn(
                        label: 'Iniciar',
                        icon: Icons.play_arrow,
                        color: Colors.purple,
                        onTap: () =>
                            viewModel.iniciarAgendamento(agendamento.id!),
                      ),
                    if (agendamento.status == AgendamentoStatus.em_andamento)
                      _btn(
                        label: 'Concluir',
                        icon: Icons.done_all,
                        color: Colors.green,
                        onTap: () =>
                            viewModel.concluirAgendamento(agendamento.id!),
                      ),
                    if (agendamento.status == AgendamentoStatus.confirmado ||
                        agendamento.status == AgendamentoStatus.em_andamento)
                      _btn(
                        label: 'Voltar',
                        icon: Icons.arrow_back,
                        color: Colors.red,
                        onTap: () =>
                            viewModel.reverterAgendamento(agendamento.id!),
                      ),
                    if (agendamento.status == AgendamentoStatus.pendente)
                      _btn(
                        label: 'Cancelar',
                        icon: Icons.close,
                        color: Colors.red,
                        onTap: () =>
                            viewModel.cancelarAgendamento(agendamento.id!),
                      ),
                    if (agendamento.status == AgendamentoStatus.pendente ||
                        agendamento.status == AgendamentoStatus.cancelado)
                      _btn(
                        label: 'Excluir',
                        icon: Icons.delete,
                        color: Colors.black,
                        onTap: () => _confirmarExclusao(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return IconButton.filled(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      tooltip: label,
      style: IconButton.styleFrom(backgroundColor: color),
    );
  }

  Color _corStatus(AgendamentoStatus s) {
    switch (s) {
      case AgendamentoStatus.pendente:
        return Colors.orange;
      case AgendamentoStatus.confirmado:
        return Colors.blue;
      case AgendamentoStatus.em_andamento:
        return Colors.purple;
      case AgendamentoStatus.concluido:
        return Colors.green;
      case AgendamentoStatus.cancelado:
        return Colors.red;
    }
  }
}

