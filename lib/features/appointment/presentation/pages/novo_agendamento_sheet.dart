import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../viewmodels/app_view_model.dart';

class NovoAgendamentoSheet extends StatefulWidget {
  final AppViewModel viewModel;
  final int? usuarioId;

  const NovoAgendamentoSheet({super.key, required this.viewModel, this.usuarioId});

  @override
  State<NovoAgendamentoSheet> createState() => _NovoAgendamentoSheetState();
}

class _NovoAgendamentoSheetState extends State<NovoAgendamentoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _telCtrl;
  final List<ServicoSelecionado> _servicosSelecionados = [];
  DateTime? _dataSelecionada;
  TimeOfDay? _horaSelecionada;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController();
    _telCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final firstDate = DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(2028),
    );
    if (picked != null && mounted) {
      final hora = await showTimePicker(
        context: context,
        initialTime:
            _horaSelecionada ??
            TimeOfDay(hour: picked.hour, minute: picked.minute),
      );
      if (hora != null) {
        setState(() {
          _dataSelecionada = DateTime(
            picked.year,
            picked.month,
            picked.day,
            hora.hour,
            hora.minute,
          );
          _horaSelecionada = hora;
        });
      }
    }
  }

  void _toggleServico(SalaoServico serv) {
    setState(() {
      final idx = _servicosSelecionados.indexWhere(
        (s) => s.servicoId == serv.id,
      );
      if (idx >= 0) {
        _servicosSelecionados.removeAt(idx);
      } else {
        _servicosSelecionados.add(
          ServicoSelecionado(
            agendamentoId: 0,
            servicoId: serv.id,
            servicoNome: serv.nome,
            preco: serv.preco,
          ),
        );
      }
    });
  }

  double get _total => _servicosSelecionados.fold(0, (s, sv) => s + sv.preco);

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() ||
        _servicosSelecionados.isEmpty ||
        _dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha todos os campos e selecione serviços e data/hora.',
          ),
        ),
      );
      return;
    }

    final ag = Agendamento(
      nomeCliente: _nomeCtrl.text.trim(),
      telefoneCliente: _telCtrl.text.trim(),
      dataAgendada: _dataSelecionada!,
      dataCriacao: DateTime.now(),
      status: AgendamentoStatus.pendente,
      servicos: List.from(_servicosSelecionados),
      valorTotal: _total,
      usuarioId: widget.usuarioId,
    );

    await widget.viewModel.criarAgendamento(ag);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Novo Agendamento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nomeCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome do cliente',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _telCtrl,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o telefone' : null,
            ),
            const SizedBox(height: 12),
            const Text(
              'Serviços:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _buildListaServicos(),
            const SizedBox(height: 12),
            const Text(
              'Data e hora:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ElevatedButton.icon(
              onPressed: _selecionarData,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _dataSelecionada == null
                    ? 'Selecionar data e hora'
                    : 'Data: ${_dataSelecionada!.day}/${_dataSelecionada!.month}/${_dataSelecionada!.year} ${_horaSelecionada!.hour.toString().padLeft(2, '0')}:${_horaSelecionada!.minute.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: R\$ ${_total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvar,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Agendar'),
            ),
          ],
        ),
      );
  }

  Widget _buildListaServicos() {
    final state = widget.viewModel.state;
    if (state is! AppLoaded) return const SizedBox.shrink();
    if (state.servicosDisponiveis.isEmpty) {
      return const Text('Nenhum serviço disponível');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.servicosDisponiveis.length,
      itemBuilder: (context, index) {
        final s = state.servicosDisponiveis[index];
        final selecionado = _servicosSelecionados.any(
          (sv) => sv.servicoId == s.id,
        );
        return CheckboxListTile(
          title: Text(s.nome),
          subtitle: Text(
            'R\$ ${s.preco.toStringAsFixed(2)}  \u00b7  ${s.duracaoMinutos}min',
          ),
          value: selecionado,
          onChanged: (_) => _toggleServico(s),
        );
      },
    );
  }
}
