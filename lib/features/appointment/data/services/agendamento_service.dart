import 'package:sqflite/sqflite.dart' as sql;

import '../../../../core/database/app_database.dart';

class AgendamentoService {
  final AppDatabase _appDb;

  AgendamentoService({AppDatabase? appDb})
    : _appDb = appDb ?? AppDatabase.instance;

  Future<sql.Database> get _db => _appDb.database;

  Future<int> insertAgendamento(Map<String, Object?> row) async {
    final db = await _db;
    return db.insert('agendamentos', row);
  }

  Future<int> insertServico(Map<String, Object?> row) async {
    final db = await _db;
    return db.insert('servicos_agendamento', row);
  }

  Future<List<Map<String, dynamic>>> queryAgendamentos({
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await _db;
    return db.query(
      'agendamentos',
      where: where?.isNotEmpty == true ? where : null,
      whereArgs: whereArgs != null && whereArgs.isNotEmpty ? whereArgs : null,
    );
  }

  Future<List<Map<String, dynamic>>> queryServicosByAgendamento(
    int agendamentoId,
  ) async {
    final db = await _db;
    return db.query(
      'servicos_agendamento',
      where: 'agendamento_id = ?',
      whereArgs: [agendamentoId],
    );
  }

  Future<List<Map<String, dynamic>>> queryServicosDisponiveis() async {
    final db = await _db;
    return db.query('servicos_disponiveis');
  }

  Future<int> updateAgendamento(int id, Map<String, Object?> row) async {
    final db = await _db;
    return db.update('agendamentos', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateServico(int id, Map<String, Object?> row) async {
    final db = await _db;
    return db.update(
      'servicos_agendamento',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAgendamento(int id) async {
    final db = await _db;
    await db.delete(
      'servicos_agendamento',
      where: 'agendamento_id = ?',
      whereArgs: [id],
    );
    return db.delete('agendamentos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAgendamentosPorData(
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    final db = await _db;
    return db.query(
      'agendamentos',
      where: 'data_agendada >= ? AND data_agendada < ? AND status NOT IN (?, ?)',
      whereArgs: [
        dataInicio.toIso8601String(),
        dataFim.toIso8601String(),
        'F',
        'X',
      ],
    );
  }

  Future<Map<String, Object?>> queryCountReceita(
    DateTime inicio,
    DateTime fim,
  ) async {
    final db = await _db;
    final results = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN status = 'F' THEN 1 ELSE 0 END) as concluidos,
        SUM(CASE WHEN status = 'P' THEN 1 ELSE 0 END) as pendentes,
        SUM(CASE WHEN status IN ('C', 'E') THEN 1 ELSE 0 END) as confirmados,
        SUM(CASE WHEN status = 'X' THEN 1 ELSE 0 END) as cancelados,
        COALESCE(SUM(CASE WHEN status = 'F' THEN valor_total ELSE 0 END), 0) as receitaConfirmada,
        COALESCE(SUM(CASE WHEN status IN ('P', 'C', 'E') THEN valor_total ELSE 0 END), 0) as receitaPendente
      FROM agendamentos
      WHERE data_agendada >= ? AND data_agendada < ?
    ''',
      [inicio.toIso8601String(), fim.toIso8601String()],
    );
    return results.isNotEmpty
        ? results.first
        : {
            'total': 0,
            'concluidos': 0,
            'pendentes': 0,
            'confirmados': 0,
            'cancelados': 0,
            'receitaConfirmada': 0.0,
            'receitaPendente': 0.0,
          };
  }
}
