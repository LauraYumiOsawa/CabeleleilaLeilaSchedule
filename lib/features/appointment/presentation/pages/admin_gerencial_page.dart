import 'package:flutter/material.dart';

import '../viewmodels/app_view_model.dart';

/// Painel gerencial — desempenho semanal do salão.
class PainelGerencialPage extends StatefulWidget {
  final AppViewModel viewModel;

  const PainelGerencialPage({super.key, required this.viewModel});

  @override
  State<PainelGerencialPage> createState() => _PainelGerencialPageState();
}

class _PainelGerencialPageState extends State<PainelGerencialPage> {
  int _semanaOffset = 0;

  DateTime get _semanaInicio {
    final now = DateTime.now();
    final diff = now.weekday - DateTime.monday;
    return DateTime(
      now.year,
      now.month,
      now.day - diff,
    ).subtract(Duration(days: _semanaOffset * 7));
  }

  @override
  void initState() {
    super.initState();
    widget.viewModel.carregarDesempenhoSemana(_semanaInicio);
  }

  void _navegarSemana(int delta) {
    setState(() {
      _semanaOffset += delta;
    });
    widget.viewModel.carregarDesempenhoSemana(_semanaInicio);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final state = widget.viewModel.state;
        final desempenho = state is AppLoaded ? state.desempenho : null;

        if (desempenho == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final inicioFormatado =
            '${_semanaInicio.day}/${_semanaInicio.month}/${_semanaInicio.year}';
        final fimFormatado =
            '${_semanaInicio.add(const Duration(days: 6)).day}/${_semanaInicio.add(const Duration(days: 6)).month}/${_semanaInicio.add(const Duration(days: 6)).year}';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _semanaOffset >= 0
                      ? () => _navegarSemana(1)
                      : null,
                ),
                Column(
                  children: [
                    Text(
                      'Semana de $inicioFormatado a $fimFormatado',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _semanaOffset = 0);
                        widget.viewModel.carregarDesempenhoSemana(_semanaInicio);
                      },
                      child: const Text(
                        'Semana atual',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _navegarSemana(-1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _cardMetrica(
              titulo: 'Total de Agendamentos',
              valor: '${desempenho.totalAgendamentos}',
              icon: Icons.calendar_month,
              cor: Colors.blue,
            ),
            _cardMetrica(
              titulo: 'Concluídos',
              valor: '${desempenho.totalConcluidos}',
              icon: Icons.check_circle,
              cor: Colors.green,
            ),
            _cardMetrica(
              titulo: 'Confirmados',
              valor: '${desempenho.totalConfirmados}',
              icon: Icons.schedule,
              cor: Colors.blue,
            ),
            _cardMetrica(
              titulo: 'Pendentes',
              valor: '${desempenho.totalPendentes}',
              icon: Icons.pending,
              cor: Colors.orange,
            ),
            _cardMetrica(
              titulo: 'Cancelados',
              valor: '${desempenho.totalCancelados}',
              icon: Icons.cancel,
              cor: Colors.red,
            ),
            _cardMetrica(
              titulo: 'Receita Confirmada',
              valor: 'R\$ ${desempenho.receitaConfirmada.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              cor: Colors.green,
              tamanhoValor: 22,
            ),
            _cardMetrica(
              titulo: 'Receita Pendente',
              valor: 'R\$ ${desempenho.receitaPendente.toStringAsFixed(2)}',
              icon: Icons.pending,
              cor: Colors.orange,
              tamanhoValor: 22,
            ),
            const SizedBox(height: 24),
            const Text(
              'Resumo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _barra(
                      label: 'Taxa de conclusão',
                      valor: desempenho.totalAgendamentos > 0
                          ? desempenho.totalConcluidos /
                                desempenho.totalAgendamentos
                          : 0.0,
                      cor: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _barra(
                      label: 'Taxa de confirmação',
                      valor: desempenho.totalAgendamentos > 0
                          ? desempenho.totalConfirmados /
                                desempenho.totalAgendamentos
                          : 0.0,
                      cor: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _barra(
                      label: 'Taxa de pendência',
                      valor: desempenho.totalAgendamentos > 0
                          ? desempenho.totalPendentes /
                                desempenho.totalAgendamentos
                          : 0.0,
                      cor: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _barra(
                      label: 'Taxa de cancelamento',
                      valor: desempenho.totalAgendamentos > 0
                          ? desempenho.totalCancelados /
                                desempenho.totalAgendamentos
                          : 0.0,
                      cor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _cardMetrica({
    required String titulo,
    required String valor,
    required IconData icon,
    required Color cor,
    double tamanhoValor = 28,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: cor, size: 32),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        trailing: Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: tamanhoValor,
            color: cor,
          ),
        ),
      ),
    );
  }

  Widget _barra({
    required String label,
    required double valor,
    required Color cor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              '${(valor * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: valor.clamp(0.0, 1.0),
          backgroundColor: cor.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(cor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
