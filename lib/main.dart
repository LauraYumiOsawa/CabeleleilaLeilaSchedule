import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'features/appointment/data/repositories/agendamento_repository_impl.dart';
import 'features/appointment/presentation/pages/cliente_agendamentos_page.dart';
import 'features/appointment/presentation/pages/cliente_historico_page.dart';
import 'features/appointment/presentation/pages/novo_agendamento_sheet.dart';
import 'features/appointment/presentation/viewmodels/app_view_model.dart';
import 'features/auth/domain/entities/usuario.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/services/auth_manager.dart';
import 'shared/widgets/app_drawer.dart';

void main() {
  databaseFactory = databaseFactoryFfi;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final authManager = AuthManager();

  @override
  void initState() {
    super.initState();
    authManager.addListener(_rebuild);
  }

  @override
  void dispose() {
    authManager.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salão da Leila',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: authManager.isLoggedIn
          ? PaginaPrincipal(key: ValueKey('app-${authManager.currentUser!.id}'))
          : const LoginPage(key: ValueKey('login')),
    );
  }
}

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({super.key});

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal>
    with SingleTickerProviderStateMixin {
  late final AppViewModel _viewModel;
  late final TabController _tabController;
  final authManager = AuthManager();

  @override
  void initState() {
    super.initState();
    _viewModel = AppViewModel(AgendamentoRepositoryImpl());
    _tabController = TabController(length: 2, vsync: this);
    _viewModel.carregarTudo();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = authManager.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salão da Leila'),
        backgroundColor: Colors.purple,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Agendamentos'),
            Tab(icon: Icon(Icons.history), text: 'Histórico'),
          ],
        ),
      ),
      drawer: AppDrawer(
        user: user,
        viewModel: _viewModel,
        onLogout: () => setState(() {}),
      ),
      floatingActionButton: authManager.isAdmin
          ? null
          : FloatingActionButton(
              onPressed: () => _abrirNovoAgendamento(),
              backgroundColor: Colors.purple,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListaAgendamentosPage(viewModel: _viewModel),
          HistoricoAgendamentosPage(viewModel: _viewModel),
        ],
      ),
    );
  }

  void _abrirNovoAgendamento() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: NovoAgendamentoSheet(
              viewModel: _viewModel,
              usuarioId: authManager.currentUser!.id,
            ),
          ),
        ),
      ),
    );
  }
}
