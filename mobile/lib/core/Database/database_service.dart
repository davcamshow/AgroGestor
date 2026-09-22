import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Base de datos SQLite local para modo offline.
///
/// Esquema:
/// - `cache`: última copia local conocida de cada entidad (por tipo + id).
///   `is_dirty = 1` significa que tiene cambios locales aún no sincronizados
///   con el servidor.
/// - `pending_operations`: cola FIFO de operaciones (create/update/delete)
///   generadas mientras la app estaba sin conexión, pendientes de replicar
///   al backend.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bovion_offline.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cache (
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_dirty INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (entity_type, entity_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE pending_operations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            entity_local_id TEXT NOT NULL,
            operation TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_pending_entity ON pending_operations (entity_type, entity_local_id)',
        );
      },
    );
  }

  /// Borra toda la caché y la cola de sincronización. Útil en logout, para
  /// no dejar datos de un usuario visibles/pendientes para el siguiente.
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('cache');
    await db.delete('pending_operations');
  }
}
