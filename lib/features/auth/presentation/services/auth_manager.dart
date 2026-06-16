import 'package:flutter/foundation.dart';

import '../../data/repositories/usuario_repository_impl.dart';
import '../../domain/entities/usuario.dart';

class AuthManager extends ChangeNotifier {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  final UsuarioRepositoryImpl _repository = UsuarioRepositoryImpl();

  Usuario? _currentUser;

  Usuario? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<bool> login(String email, String senha) async {
    final user = await _repository.logar(email, senha);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String nome, String email, String senha, String telefone) async {
    final existing = await _repository.getByEmail(email);
    if (existing != null) return false;

    final newUsuario = Usuario(
      nome: nome,
      email: email,
      senha: senha,
      telefone: telefone,
      dataCriacao: DateTime.now(),
    );
    await _repository.cadastrar(newUsuario);
    return login(email, senha);
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? nome,
    String? email,
    String? telefone,
    String? novaSenha,
  }) async {
    if (_currentUser == null) return false;

    final user = _currentUser!;
    final updatedEmail = email?.trim() ?? user.email;

    if (email != null && email.trim() != user.email) {
      final existing = await _repository.getByEmail(updatedEmail);
      if (existing != null && existing.id != user.id) return false;
    }

    final updated = user.copyWith(
      nome: nome ?? user.nome,
      email: updatedEmail,
      telefone: telefone ?? user.telefone,
      senha: novaSenha ?? user.senha,
    );

    await _repository.atualizar(updated);
    _currentUser = updated;
    notifyListeners();
    return true;
  }
}
