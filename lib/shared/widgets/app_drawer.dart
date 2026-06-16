import 'package:flutter/material.dart';

import '../../features/appointment/presentation/pages/admin_gerencial_page.dart';
import '../../features/appointment/presentation/pages/admin_operacional_page.dart';
import '../../features/appointment/presentation/viewmodels/app_view_model.dart';
import '../../features/auth/domain/entities/usuario.dart';
import '../../features/auth/presentation/pages/edit_profile_page.dart';
import '../../features/auth/presentation/services/auth_manager.dart';

class AppDrawer extends StatelessWidget {
  final Usuario user;
  final AppViewModel viewModel;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.user,
    required this.viewModel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade800,
              Colors.purple.shade500,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildDrawerHeader(context),
            if (user.isAdmin) ...[
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.amber,
                ),
                title: const Text(
                  'Painel Administrativo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => _AdminPanel(viewModel: viewModel),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Colors.white24),
            ],
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white),
              title: const Text(
                'Editar Perfil',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                );
              },
            ),
            const Divider(height: 1, color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('Sobre', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                _showAboutDialog(context);
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text('Sair', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.of(context).pop();
                _handleLogout(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.shade900,
            Colors.purple.shade700,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Text(
                user.nome.isNotEmpty ? user.nome[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.nome,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              user.email,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (user.isAdmin) ...[
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Salão da Leila',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.local_shipping_rounded,
        size: 48,
        color: Colors.purple,
      ),
      children: const [
        Text('Sistema de agendamento para salão de beleza.'),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authManager = AuthManager();
      await authManager.logout();
      onLogout();
    }
  }
}

class _AdminPanel extends StatefulWidget {
  final AppViewModel viewModel;

  const _AdminPanel({required this.viewModel});

  @override
  State<_AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<_AdminPanel> {
  int _adminTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        backgroundColor: Colors.purple,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Operacional'),
                  icon: Icon(Icons.settings),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Gerencial'),
                  icon: Icon(Icons.bar_chart),
                ),
              ],
              selected: {_adminTab},
              onSelectionChanged: (set) =>
                  setState(() => _adminTab = set.first),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _adminTab,
        children: [
          PainelOperacionalPage(viewModel: widget.viewModel),
          PainelGerencialPage(viewModel: widget.viewModel),
        ],
      ),
    );
  }
}
