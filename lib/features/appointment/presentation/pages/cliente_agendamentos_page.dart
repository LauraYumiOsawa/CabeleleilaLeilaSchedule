import 'package:flutter/material.dart';

import '../../../auth/presentation/services/auth_manager.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../viewmodels/app_view_model.dart';

class ListaAgendamentosPage extends StatelessWidget {
  final AppViewModel viewModel;

  const ListaAgendamentosPage({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        final state = viewModel.state;
        if (state is AppLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AppError) {
          return Center(child: Text('Erro: ${state.message}'));
        }
        if (state is! AppLoaded) {
          return const Center(child: Text('Estado desconhecido'));
        }

        if (state.ativos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum agendamento ativo',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: state.ativos.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final ag = state.ativos[index];
            return _AgendamentoCard(
              agendamento: ag,
              onTap: () => _mostrarDetalhes(context, ag),
              viewModel: viewModel,
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDetalhes(BuildContext context, Agendamento ag) async {
    await viewModel.carregarDetalhe(ag.id!);
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _DetalhesModal(viewModel: viewModel),
      );
    }
  }
}

class _AgendamentoCard extends StatelessWidget {
  final Agendamento agendamento;
  final VoidCallback onTap;
  final AppViewModel viewModel;

  const _AgendamentoCard({
    required this.agendamento,
    required this.onTap,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _corStatus(agendamento.status),
          child: Text(
            agendamento.nomeCliente[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(agendamento.nomeCliente),
        subtitle: Text(
          '${_formatarData(agendamento.dataAgendada)} - '
          '${agendamento.servicos.length} serviço(s) - '
          'R\$ ${agendamento.valorTotal.toStringAsFixed(2)}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _corStatus(agendamento.status).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            agendamento.status.toLabel(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _corStatus(agendamento.status),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        onTap: onTap,
        isThreeLine: true,
      ),
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

  String _formatarData(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}

class _DetalhesModal extends StatelessWidget {
  final AppViewModel viewModel;

  const _DetalhesModal({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final state = viewModel.state;
    if (state is! AppLoaded || state.selecionado == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final ag = state.selecionado!;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ag.nomeCliente,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Telefone: ${ag.telefoneCliente}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Data: '
              '${ag.dataAgendada.day}/${ag.dataAgendada.month}/${ag.dataAgendada.year} '
              '${ag.dataAgendada.hour.toString().padLeft(2, '0')}:/'
              '${ag.dataAgendada.minute.toString().padLeft(2, '0')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Status: ${ag.status.toLabel()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Valor total: R\$ ${ag.valorTotal.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 24),
            const Text(
              'Serviços:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...ag.servicos.map(
              (s) => ListTile(
                dense: true,
                title: Text(
                  s.servicoNome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'R\$ ${s.preco.toStringAsFixed(2)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          s.status.toLabel(),
                          style: TextStyle(
                            fontSize: 11,
                            color: _corServicoStatus(s.status),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PermissaoAcaoWidget(
              agendamento: ag,
              viewModel: viewModel,
              onCancelado: () {},
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _corServicoStatus(ServicoStatus s) {
    switch (s) {
      case ServicoStatus.pendente:
        return Colors.orange;
      case ServicoStatus.em_andamento:
        return Colors.purple;
      case ServicoStatus.concluido:
        return Colors.green;
    }
  }
}

class _PermissaoAcaoWidget extends StatelessWidget {
  final Agendamento agendamento;
  final AppViewModel viewModel;
  final VoidCallback onCancelado;

  const _PermissaoAcaoWidget({
    required this.agendamento,
    required this.viewModel,
    required this.onCancelado,
  });

  @override
  Widget build(BuildContext context) {
    final authManager = AuthManager();

    if (authManager.isAdmin) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Administradores devem usar o Painel Operacional para modificar agendamentos.',
                style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
              ),
            ),
          ],
        ),
      );
    }

    final mensagemErro = viewModel.validarAlteracaoAgendamento(agendamento);

    if (mensagemErro != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mensagemErro,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Você pode alterar este agendamento.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () => _confirmarCancelamento(context),
              icon: const Icon(Icons.close),
              label: const Text('Cancelar Agendamento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmarCancelamento(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: const Text(
          'Tem certeza que deseja cancelar este agendamento? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Cancelamento'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await viewModel.cancelarAgendamento(agendamento.id!);
      Navigator.pop(context);
      onCancelado();
    }
  }
}
