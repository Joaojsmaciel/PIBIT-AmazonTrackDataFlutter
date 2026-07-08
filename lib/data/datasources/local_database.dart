import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:amazon_track_data/core/errors/failures.dart';
import 'package:amazon_track_data/data/models/location_model.dart';

/// Serviço de banco de dados local SQLite para armazenamento persistente de
/// pontos GPS no paradigma Store-Carry-and-Forward das Redes DTN.
///
/// Os dados sobrevivem a reinicializações do aplicativo e são sincronizados
/// com o Firestore quando a embarcação alcança um gateway com internet.
class LocalDatabaseService {
  static Database? _database;

  static const String _tableName = 'location_points';
  static const String _dbName = 'amazon_track.db';
  static const int _dbVersion = 1;

  // ---------------------------------------------------------------------------
  // Inicialização
  // ---------------------------------------------------------------------------

  Future<Database> get _db async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);

    debugPrint('[LocalDB] Abrindo banco em: $path');

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Colunas em camelCase para corresponder diretamente ao LocationModel.toMap()
    await db.execute('''
      CREATE TABLE $_tableName (
        id        TEXT    PRIMARY KEY,
        userId    TEXT    NOT NULL,
        tripId    TEXT    NOT NULL,
        boatId    TEXT    NOT NULL DEFAULT '',
        latitude  REAL    NOT NULL,
        longitude REAL    NOT NULL,
        speed     REAL    NOT NULL DEFAULT 0.0,
        accuracy  REAL    NOT NULL DEFAULT 0.0,
        altitude  REAL,
        bearing   REAL,
        userType  TEXT    NOT NULL DEFAULT '',
        userName  TEXT    NOT NULL DEFAULT '',
        timestamp INTEGER NOT NULL,
        synced    INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_synced_ts ON $_tableName (synced, timestamp)');

    debugPrint('[LocalDB] Tabela criada com sucesso.');
  }

  // ---------------------------------------------------------------------------
  // Operações de escrita
  // ---------------------------------------------------------------------------

  /// Persiste um ponto GPS.
  ///
  /// Usa [ConflictAlgorithm.ignore] para deduplicar por [id].
  Future<void> insertLocation(LocationModel location) async {
    try {
      final db = await _db;
      final id = '${location.userId}_${location.timestamp}';

      await db.insert(
        _tableName,
        {
          'id': id,
          ...location.toMap(),
          'synced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      throw LocalDatabaseFailure(message: 'Erro ao inserir localização: $e');
    }
  }

  /// Marca um ponto como sincronizado pelo seu [id] composto
  /// (`{userId}_{timestamp}`).
  Future<void> markAsSyncedById(String id) async {
    try {
      final db = await _db;
      await db.update(
        _tableName,
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDatabaseFailure(message: 'Erro ao marcar sincronizado: $e');
    }
  }

  /// Mantido para compatibilidade com código legado — sem efeito no SQLite.
  Future<void> markAsSynced(int index) async {}

  /// Remove todos os pontos **já sincronizados** com timestamp anterior a
  /// [cutoffTimestamp] (milissegundos epoch).
  Future<int> deleteOlderThan(int cutoffTimestamp) async {
    try {
      final db = await _db;
      final count = await db.delete(
        _tableName,
        where: 'timestamp < ? AND synced = 1',
        whereArgs: [cutoffTimestamp],
      );
      debugPrint('[LocalDB] Removidos $count pontos antigos.');
      return count;
    } catch (e) {
      throw LocalDatabaseFailure(message: 'Erro ao deletar antigos: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Consultas
  // ---------------------------------------------------------------------------

  /// Retorna até [limit] pontos pendentes de sincronização, em ordem
  /// cronológica (FIFO).
  Future<List<Map<String, dynamic>>> getAllUnsynced({int limit = 50}) async {
    try {
      final db = await _db;
      return db.query(
        _tableName,
        where: 'synced = 0',
        orderBy: 'timestamp ASC',
        limit: limit,
      );
    } catch (e) {
      throw LocalDatabaseFailure(message: 'Erro ao buscar pendentes: $e');
    }
  }

  /// Quantidade de pontos pendentes de sincronização.
  Future<int> getPendingCount() async {
    try {
      final db = await _db;
      final result = await db
          .rawQuery('SELECT COUNT(*) AS cnt FROM $_tableName WHERE synced = 0');
      return (result.first['cnt'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Apaga todos os registros (útil em testes e logout).
  Future<void> clearAll() async {
    try {
      final db = await _db;
      await db.delete(_tableName);
    } catch (e) {
      throw LocalDatabaseFailure(message: 'Erro ao limpar banco: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Ciclo de vida
  // ---------------------------------------------------------------------------

  Future<void> dispose() async {
    await _database?.close();
    _database = null;
  }
}
