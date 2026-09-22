import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../api/api_client.dart';
import '../database/database_service.dart';

enum SyncStatus { idle, syncing, completed, partial }

/// Sincroniza contra el backend las operaciones offline pendientes
/// (`pending_operations`), disparándose automáticamente al recuperar la
/// conexión (BP-159).
///
/// La cola se procesa en orden FIFO. Si una operación falla por un error de
/// red/servidor (5xx, timeout, etc.) se conserva para reintentar en la
/// siguiente reconexión y se detiene el lote ahí, para no desordenar
/// dependencias (ej. no intentar sincronizar un pesaje antes de que su
/// animal exista en el servidor). Si falla por un error del cliente (4xx,
/// ej. validación), se descarta: reintentar no lo arreglaría.
class SyncService {
  SyncService(this._apiClient) {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online) {
        syncPending();
      }
    });
  }

  final ApiClient _apiClient;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isSyncing = false;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// entity_type (usado en OfflineRepository) -> endpoint REST.
  /// Agrega aquí cada entidad a medida que migres sus providers a
  /// OfflineRepository.
  static const Map<String, String> _endpoints = {
    'animal': 'animales/',
    'lote': 'lotes/',
    'dieta': 'dietas/',
    'insumo': 'insumos/',
    'registro_peso': 'registros-peso/',
    'ciclo_reproductivo': 'ciclos-reproductivos/',
    'evento_sanitario': 'eventos-sanitarios/',
  };

  Future<Database> get _db async => DatabaseService.instance.database;

  /// Dispara la sincronización manualmente (ej. botón "Sincronizar ahora"
  /// en Configuración, o pull-to-refresh).
  Future<void> syncPending() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      final db = await _db;
      final ops = await db.query('pending_operations', orderBy: 'id ASC');

      var syncedCount = 0;
      for (final op in ops) {
        final ok = await _applyOperation(op);
        if (!ok) break;
        syncedCount++;
      }

      _statusController.add(
        syncedCount == ops.length ? SyncStatus.completed : SyncStatus.partial,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _applyOperation(Map<String, Object?> op) async {
    final db = await _db;
    final id = op['id'] as int;
    final entityType = op['entity_type'] as String;
    final localId = op['entity_local_id'] as String;
    final operation = op['operation'] as String;
    final payload = jsonDecode(op['payload'] as String) as Map<String, dynamic>;
    final endpoint = _endpoints[entityType];

    if (endpoint == null) {
      // Tipo de entidad sin endpoint registrado: descartar para no
      // bloquear la cola indefinidamente.
      await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
      return true;
    }

    try {
      switch (operation) {
        case 'create':
          final response = await _apiClient.dio.post(endpoint, data: payload);
          final serverId = response.data['id'];
          await _remapLocalId(entityType, localId, serverId.toString());
          break;
        case 'update':
          final realId = await _resolveServerId(entityType, localId);
          if (realId != null) {
            await _apiClient.dio.patch('$endpoint$realId/', data: payload);
          }
          break;
        case 'delete':
          final realId = await _resolveServerId(entityType, localId);
          if (realId != null) {
            await _apiClient.dio.delete('$endpoint$realId/');
          }
          break;
      }

      await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
        return true;
      }
      await db.update(
        'pending_operations',
        {
          'retry_count': (op['retry_count'] as int) + 1,
          'last_error': e.message,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return false;
    }
  }

  /// Cuando un registro creado offline (id local negativo) se confirma en
  /// el servidor, reemplaza su id local por el real en la caché, y
  /// actualiza cualquier operación pendiente que todavía lo referencie
  /// (ej. un update encolado sobre algo creado offline).
  Future<void> _remapLocalId(
    String entityType,
    String localId,
    String serverId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'cache',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, localId],
    );
    if (rows.isEmpty) return;

    final data =
        jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
    data['id'] = int.tryParse(serverId) ?? serverId;

    await db.transaction((txn) async {
      await txn.delete(
        'cache',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: [entityType, localId],
      );
      await txn.insert('cache', {
        'entity_type': entityType,
        'entity_id': serverId,
        'data': jsonEncode(data),
        'updated_at': DateTime.now().toIso8601String(),
        'is_dirty': 0,
      });
      await txn.update(
        'pending_operations',
        {'entity_local_id': serverId},
        where: 'entity_type = ? AND entity_local_id = ?',
        whereArgs: [entityType, localId],
      );
    });
  }

  /// Resuelve el id real de servidor para un id local. Si el id ya es
  /// positivo, es un id real. Si es negativo, busca en caché si ya fue
  /// remapeado (es decir, si su 'create' ya se sincronizó); si no, retorna
  /// null (todavía no se puede aplicar el update/delete).
  Future<String?> _resolveServerId(String entityType, String localId) async {
    if (!localId.startsWith('-')) return localId;
    final db = await _db;
    final rows = await db.query(
      'cache',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, localId],
    );
    if (rows.isEmpty) return null;
    final data =
        jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
    final idValue = data['id'];
    if (idValue == null) return null;
    final idStr = idValue.toString();
    return idStr.startsWith('-') ? null : idStr;
  }

  void dispose() {
    _sub?.cancel();
    _statusController.close();
  }
}
