import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../viewmodels/app_view_model.dart';

class HistoricoAgendamentosPage extends StatefulWidget {
  final AppViewModel viewModel;

  const HistoricoAgendamentosPage({super.key, required this.viewModel});

  @override
  State<HistoricoAgendamentosPage> createState() =>
      _HistoricoAgendamentosPageState();
}

class _HistoricoAgendamentosPageState extends State<HistoricoAgendamentosPage> {
  DateTime? _filtroInicio;
  DateTime? _filtroFim;
  String _filtroCliente = '';
  String _filtroStatus = 'Todos';

  static const _statusOptions = [
    'Todos',
    'Concluído',
    'Cancelado',
  ];

  AgendamentoStatus? _statusEnum(String label) {
    switch (label) {
      case 'Concluído':
        return AgendamentoStatus.concluido;
      case 'Cancelado':
        return AgendamentoStatus.cancelado;
      default:
        return null;
    }
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

        var items = state.finalizados;

        if (_filtroInicio != null || _filtroFim != null) {
          final inicio = _filtroInicio ?? DateTime(2000);
          final fim = _filtroFim ?? DateTime(2099);
          items = items.where((a) {
            return a.dataAgendada.isAfter(
                  inicio.subtract(const Duration(days: 1)),
                ) &&
                a.dataAgendada.isBefore(fim.add(const Duration(days: 1)));
          }).toList();
        }

        if (_filtroCliente.isNotEmpty) {
          final query = _filtroCliente.toLowerCase();
          items = items
              .where(
                (a) => a.nomeCliente.toLowerCase().contains(query) ||
                    a.telefoneCliente.contains(_filtroCliente),
              )
              .toList();
        }

        if (_filtroStatus != 'Todos') {
          final statusEnum = _statusEnum(_filtroStatus);
          if (statusEnum != null) {
            items = items.where((a) => a.status == statusEnum).toList();
          }
        }

        items.sort((a, b) => b.dataAgendada.compareTo(a.dataAgendada));

        return Column(
          children: [
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
                          labelText: 'Filtrar por cliente',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (v) => setState(() => _filtroCliente = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _filtroStatus,
                      items: _statusOptions
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _filtroStatus = v);
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _selecionarPeriodo,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _filtroInicio != null
                            ? '${_filtroInicio!.day}/${_filtroInicio!.month}'
                            : 'Período',
                      ),
                    ),
                    if (_filtroInicio != null)
                      TextButton(
                        onPressed: () => setState(() {
                          _filtroInicio = null;
                          _filtroFim = null;
                        }),
                        child: const Icon(Icons.clear),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum agendamento finalizado ou cancelado',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemBuilder: (context, index) {
                        final ag = items[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 3,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(ag.nomeCliente),
                            subtitle: Text(
                              'Data: ${ag.dataAgendada.day}/${ag.dataAgendada.month}/${ag.dataAgendada.year}\n'
                              'Serviços: ${ag.servicos.map((s) => s.servicoNome).join(', ')}',
                            ),
                            trailing: Text(
                              'R\$ ${ag.valorTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () => _mostrarDetalhes(context, ag),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selecionarPeriodo() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _filtroInicio != null && _filtroFim != null
          ? DateTimeRange(start: _filtroInicio!, end: _filtroFim!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _filtroInicio = picked.start;
        _filtroFim = picked.end;
      });
    }
  }

  Future<void> _mostrarDetalhes(BuildContext context, Agendamento ag) async {
    await widget.viewModel.carregarDetalhe(ag.id!);
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => _DetalhesDialog(viewModel: widget.viewModel),
      );
    }
  }
}

class _DetalhesDialog extends StatelessWidget {
  final AppViewModel viewModel;

  const _DetalhesDialog({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final state = viewModel.state;
    if (state is! AppLoaded || state.selecionado == null) {
      return const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      );
    }

    final ag = state.selecionado!;

    return AlertDialog(
      title: const Text('Detalhes do Agendamento'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linha('Cliente', ag.nomeCliente),
            _linha('Telefone', ag.telefoneCliente),
            _linha(
              'Data agendada',
              '${ag.dataAgendada.day}/${ag.dataAgendada.month}/${ag.dataAgendada.year} '
                  '${ag.dataAgendada.hour.toString().padLeft(2, '0')}:${ag.dataAgendada.minute.toString().padLeft(2, '0')}',
            ),
            _linha('Status', ag.status.toLabel()),
            const Divider(),
            ...ag.servicos.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(s.servicoNome)),
                    Text(
                      'R\$ ${s.preco.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'R\$ ${ag.valorTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _linha(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
