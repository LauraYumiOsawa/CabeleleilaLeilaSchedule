import '../../domain/entities/usuario.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../services/usuario_service.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  final UsuarioService _service;

  UsuarioRepositoryImpl({UsuarioService? service})
    : _service = service ?? UsuarioService();

  Usuario? _fromMap(Map<String, dynamic> m) {
    return Usuario(
      id: (m['id'] as num?)?.toInt(),
      nome: m['nome'] as String? ?? '',
      email: m['email'] as String? ?? '',
      senha: m['senha'] as String? ?? '',
      telefone: m['telefone'] as String? ?? '',
      tipo: m['tipo'] as String? ?? 'cliente',
      dataCriacao: DateTime.parse(m['data_criacao'] as String),
    );
  }

  @override
  Future<Usuario?> logar(String email, String senha) async {
    final row = await _service.findByEmailSenha(email, senha);
    return row != null ? _fromMap(row) : null;
  }

  @override
  Future<Usuario?> getByEmail(String email) async {
    final row = await _service.getByEmail(email);
    return row != null ? _fromMap(row) : null;
  }

  @override
  Future<Usuario?> getById(int id) async {
    final row = await _service.getById(id);
    return row != null ? _fromMap(row) : null;
  }

  @override
  Future<int> cadastrar(Usuario usuario) async {
    await _service.cadastrar(
      usuario.nome,
      usuario.email,
      usuario.senha,
      usuario.telefone,
    );
    return usuario.id ?? -1;
  }

  @override
  Future<void> atualizar(Usuario usuario) async {
    if (usuario.id == null) return;
    await _service.atualizar(usuario.id!, {
      'nome': usuario.nome,
      'email': usuario.email,
      'senha': usuario.senha,
      'telefone': usuario.telefone,
    });
  }
}
