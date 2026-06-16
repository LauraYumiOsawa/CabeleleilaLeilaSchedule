import 'package:sqflite/sqflite.dart' as sql;

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  sql.Database? _db;

  Future<sql.Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<sql.Database> _open() {
    return sql.openDatabase(
      'todo.db',
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(sql.Database db, int version) async {
    await db.execute('''
      CREATE TABLE servicos_disponiveis (
        id               INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        nome            TEXT NOT NULL,
        preco           REAL NOT NULL DEFAULT 0.0,
        duracao_minutos INTEGER NOT NULL DEFAULT 30
      )
    ''');

    await db.execute('''
      CREATE TABLE agendamentos (
        id              INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        nome_cliente    TEXT NOT NULL,
        telefone        TEXT NOT NULL,
        data_agendada   TEXT NOT NULL,
        data_criacao    TEXT NOT NULL,
        status          CHARACTER(1) NOT NULL DEFAULT 'P',
        valor_total     REAL NOT NULL DEFAULT 0.0,
        usuario_id      INTEGER,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE servicos_agendamento (
        id               INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        agendamento_id   INTEGER NOT NULL,
        servico_id       INTEGER NOT NULL,
        servico_nome     TEXT NOT NULL,
        preco            REAL NOT NULL DEFAULT 0.0,
        status_servico   CHARACTER(1) NOT NULL DEFAULT 'P',
        FOREIGN KEY (agendamento_id) REFERENCES agendamentos(id) ON DELETE CASCADE
      )
    ''');

    await _seedServicos(db);
    await _onCreateUsuarios(db);
    await _seedAdminUser(db);
  }

  Future<void> _onUpgrade(
    sql.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS tarefas');
      await _onCreate(db, newVersion);
    }
    if (oldVersion < 3) {
      await _onCreateUsuarios(db);
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE usuarios ADD COLUMN tipo TEXT NOT NULL DEFAULT "cliente"',
      );
      await _seedAdminUser(db);
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE agendamentos ADD COLUMN faturado CHARACTER(1) NOT NULL DEFAULT "N"',
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE agendamentos ADD COLUMN usuario_id INTEGER',
      );
    }
  }

  Future<void> _onCreateUsuarios(sql.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id           INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        nome         TEXT NOT NULL,
        email        TEXT NOT NULL UNIQUE,
        senha        TEXT NOT NULL,
        telefone     TEXT NOT NULL DEFAULT '',
        tipo         TEXT NOT NULL DEFAULT 'cliente',
        data_criacao TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
  }

  Future<void> _seedAdminUser(sql.Database db) async {
    final existing = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: ['leila@salao.com'],
    );
    if (existing.isEmpty) {
      await db.insert('usuarios', {
        'nome': 'Leila',
        'email': 'leila@salao.com',
        'senha': 'leila',
        'telefone': '',
        'tipo': 'admin',
        'data_criacao': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _seedServicos(sql.Database db) async {
    final servicos = [
      ('Corte Feminino', 45.0, 30),
      ('Corte Masculino', 35.0, 20),
      ('Colora\u00e7\u00e3o', 120.0, 60),
      ('Escova Progressiva', 80.0, 45),
      ('Hidrata\u00e7\u00e3o', 60.0, 30),
      ('Manicure', 25.0, 20),
      ('Pedicure', 30.0, 25),
      ('Barba', 20.0, 15),
    ];
    for (final s in servicos) {
      await db.insert('servicos_disponiveis', {
        'nome': s.$1,
        'preco': s.$2,
        'duracao_minutos': s.$3,
      });
    }
  }
}
