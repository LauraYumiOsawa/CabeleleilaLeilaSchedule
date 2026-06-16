import '../entities/usuario.dart';

abstract interface class UsuarioRepository {
  Future<Usuario?> logar(String email, String senha);
  Future<Usuario?> getByEmail(String email);
  Future<Usuario?> getById(int id);
  Future<int> cadastrar(Usuario usuario);
  Future<void> atualizar(Usuario usuario);
}
