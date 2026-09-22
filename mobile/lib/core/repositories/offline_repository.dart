import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../api/api_client.dart';
import '../database/database_service.dart';
import '../services/connectivity_service.dart';

/// Repositorio genérico offline-first para una entidad REST.
///
/// - Lecturas: intenta red primero; si no hay conexión o la petición falla,
///   retorna la caché local.
/// - Escrituras: si hay conexión, intenta aplicar de inmediato contra el
///   servidor. Si no hay conexión (o la petición falla), guarda el cambio en
///   caché local y encola una operación pendiente para sincronizar después
///   (ver [SyncService], BP-159).
///
/// Los registros creados offline reciben un id entero negativo temporal
/// (timestamp en milisegundos, negativo) en vez de un id real de servidor.
/// Esto evita tener que cambiar el tipo de `id` (int) en los modelos/UI
/// existentes: un id negativo simplemente significa "aún no sincronizado".
/// Cuando [SyncService] confirma la creación contra el servidor, reemplaza
/// el id local por el id real en la caché.
class OfflineRepository<T> {
  OfflineRepository({
    required this.entityType,
    required this.endpoint,
    required this.apiClient,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
    this.placeholderFields,
  });

  /// Identificador corto del tipo de entidad (ej. 'animal', 'lote'). Debe
  /// coincidir con la clave usada en el mapa de endpoints de [SyncService].
  final String entityType;

  /// Ruta del recurso REST, con slash final (ej. 'animales/').
  final String endpoint;

  final ApiClient apiClient;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final int Function(T item) idOf;

  /// Campos que el servidor normalmente asigna (ej. `usuario`,
  /// `fecha_registro`) y que el modelo requiere como no-nulos. Se usan solo
  /// para poder construir una instancia local válida mientras el registro
  /// no ha sido confirmado por el servidor.
  final Map<String, dynamic> Function()? placeholderFields;

  static int _nextLocalId() => -DateTime.now().millisecondsSinceEpoch;

  Future<Database> get _db async => DatabaseService.instance.database;

  /// Lista todas las entidades. Online: trae del servidor y refresca la
  /// caché (conservando registros locales aún no sincronizados). Offline (o
  /// si la petición falla): retorna lo último guardado en caché.
  Future<List<T>> getAll() async {
    final online = await isOnline();
    if (online) {
      try {
        final response = await apiClient.dio.get(endpoint);
        final items = (response.data as List)
            .map((j) => fromJson(j as Map<String, dynamic>))
            .toList();
        await _replaceCache(items);
        final pendingLocal = await _readDirtyCache();
        // Los registros creados offline aún no aparecen en la respuesta del
        // servidor: se anteponen para que no "desaparezcan" de la lista
        // mientras se sincronizan.
        return [...pendingLocal, ...items];
      } catch (_) {
        return _readCache();
      }
    }
    return _readCache();
  }

  /// Crea una entidad. `data` es el payload tal como lo espera el endpoint
  /// (igual que se usaba antes con `dio.post`).
  Future<T> create(Map<String, dynamic> data) async {
    final online = await isOnline();
    if (online) {
      try {
        final response = await apiClient.dio.post(endpoint, data: data);
        final item = fromJson(response.data as Map<String, dynamic>);
        await _upsertCache(item, dirty: false);
        return item;
      } catch (_) {
        return _createOffline(data);
      }
    }
    return _createOffline(data);
  }

  Future<T> _createOffline(Map<String, dynamic> data) async {
    final localId = _nextLocalId();
    final payload = {
      ...?placeholderFields?.call(),
      ...data,
      'id': localId,
    };
    final item = fromJson(payload);
    await _upsertCache(item, dirty: true);
    await _enqueue(
      operation: 'create',
      entityLocalId: localId.toString(),
      payload: data,
    );
    return item;
  }

  /// Actualiza una entidad existente (id real o local negativo).
  Future<void> update(int id, Map<String, dynamic> data) async {
    final online = await isOnline();
    if (online && id > 0) {
      try {
        await apiClient.dio.patch('$endpoint$id/', data: data);
        await _patchCache(id, data);
        return;
      } catch (_) {
        // Sin red útil en este momento: cae a modo offline abajo.
      }
    }
    await _patchCache(id, data);
    await _enqueue(
      operation: 'update',
      entityLocalId: id.toString(),
      payload: data,
    );
  }

  /// Elimina una entidad. Si nunca llegó a existir en el servidor (id
  /// local negativo, aún no sincronizada), simplemente descarta su
  /// operación 'create' pendiente en vez de encolar un delete.
  Future<void> delete(int id) async {
    final online = await isOnline();
    if (online && id > 0) {
      try {
        await apiClient.dio.delete('$endpoint$id/');
        await _removeCache(id);
        return;
      } catch (_) {
        // Sin red útil en este momento: cae a modo offline abajo.
      }
    }

    await _removeCache(id);
    if (id > 0) {
      await _enqueue(
        operation: 'delete',
        entityLocalId: id.toString(),
        payload: const {},
      );
    } else {
      await _discardPendingFor(id.toString());
    }
  }

  // ---- Caché local ----

  Future<List<T>> _readCache() async {
    final db = await _db;
    final rows = await db.query(
      'cache',
      where: 'entity_type = ?',
      whereArgs: [entityType],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_decodeRow).toList();
  }

  Future<List<T>> _readDirtyCache() async {
    final db = await _db;
    final rows = await db.query(
      'cache',
      where: 'entity_type = ? AND is_dirty = 1',
      whereArgs: [entityType],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_decodeRow).toList();
  }

  T _decodeRow(Map<String, Object?> row) =>
      fromJson(jsonDecode(row['data'] as String) as Map<String, dynamic>);

  Future<void> _replaceCache(List<T> items) async {
    final db = await _db;
    await db.transaction((txn) async {
      // No borrar registros dirty: son cambios locales aún no confirmados
      // por el servidor, se perderían si los pisamos con la respuesta.
      await txn.delete(
        'cache',
        where: 'entity_type = ? AND is_dirty = 0',
        whereArgs: [entityType],
      );
      final batch = txn.batch();
      for (final item in items) {
        batch.insert(
          'cache',
          _row(item, dirty: false),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> _upsertCache(T item, {required bool dirty}) async {
    final db = await _db;
    await db.insert(
      'cache',
      _row(item, dirty: dirty),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _patchCache(int id, Map<String, dynamic> data) async {
    final db = await _db;
    final rows = await db.query(
      'cache',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, id.toString()],
    );
    if (rows.isEmpty) return;
    final current =
        jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
    final merged = {...current, ...data};
    await _upsertCache(fromJson(merged), dirty: true);
  }

  Future<void> _removeCache(int id) async {
    final db = await _db;
    await db.delete(
      'cache',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, id.toString()],
    );
  }

  Map<String, dynamic> _row(T item, {required bool dirty}) => {
        'entity_type': entityType,
        'entity_id': idOf(item).toString(),
        'data': jsonEncode(toJson(item)),
        'updated_at': DateTime.now().toIso8601String(),
        'is_dirty': dirty ? 1 : 0,
      };

  // ---- Cola de operaciones pendientes ----

  Future<void> _enqueue({
    required String operation,
    required String entityLocalId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _db;
    await db.insert('pending_operations', {
      'entity_type': entityType,
      'entity_local_id': entityLocalId,
      'operation': operation,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<void> _discardPendingFor(String entityLocalId) async {
    final db = await _db;
    await db.delete(
      'pending_operations',
      where: 'entity_type = ? AND entity_local_id = ?',
      whereArgs: [entityType, entityLocalId],
    );
    await db.delete(
      'cache',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityLocalId],
    );
  }
}
