class Usuario {
  final int? id;
  final String nome;
  final String email;
  final String senha;
  final String telefone;
  final String tipo;
  final DateTime dataCriacao;

  const Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.senha,
    required this.telefone,
    this.tipo = 'cliente',
    required this.dataCriacao,
  });

  bool get isAdmin => tipo == 'admin';

  Usuario copyWith({
    int? id,
    String? nome,
    String? email,
    String? senha,
    String? telefone,
    String? tipo,
    DateTime? dataCriacao,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      telefone: telefone ?? this.telefone,
      tipo: tipo ?? this.tipo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }

  Usuario get semSenha => Usuario(
        id: id,
        nome: nome,
        email: email,
        senha: '',
        telefone: telefone,
        tipo: tipo,
        dataCriacao: dataCriacao,
      );
}
