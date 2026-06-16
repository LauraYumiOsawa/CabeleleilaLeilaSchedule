import 'package:sqflite/sqflite.dart' as sql;

import '../../../../core/database/app_database.dart';

class UsuarioService {
  final AppDatabase _appDb;

  UsuarioService({AppDatabase? appDb})
    : _appDb = appDb ?? AppDatabase.instance;

  Future<sql.Database> get _db => _appDb.database;

  Future<UsuarioService> cadastrar(
    String nome,
    String email,
    String senha,
    String telefone,
  ) async {
    final db = await _db;
    await db.insert('usuarios', {
      'nome': nome,
      'email': email,
      'senha': senha,
      'telefone': telefone,
      'data_criacao': DateTime.now().toIso8601String(),
    });
    return this;
  }

  Future<Map<String, dynamic>?> findByEmailSenha(
    String email,
    String senha,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'usuarios',
      where: 'email = ? AND senha = ?',
      whereArgs: [email, senha],
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await _db;
    final rows = await db.query('usuarios', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<Map<String, dynamic>?> getByEmail(String email) async {
    final db = await _db;
    final rows = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<int> atualizar(int id, Map<String, Object?> row) async {
    final db = await _db;
    return db.update(
      'usuarios',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
