import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../network/connectivity_service.dart';
import '../supabase/supabase_service.dart';
import '../constants/app_constants.dart';

class SyncEngine {
  final AppDatabase db;
  final ConnectivityService connectivity;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final _syncStatusController = StreamController<String>.broadcast();
  Stream<String> get syncStatusStream => _syncStatusController.stream;

  final _itemSyncedController = StreamController<({String table, String id, String status})>.broadcast();
  Stream<({String table, String id, String status})> get onItemSynced => _itemSyncedController.stream;

  SyncEngine({required this.db, required this.connectivity}) {
    connectivity.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        processOutboxQueue();
      }
    });
  }

  Future<void> queueMutation({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // Clean up previous pending mutations for the same record to avoid constraint errors or duplicate tasks
      await (db.delete(db.localOutbox)
            ..where((tbl) => tbl.targetTable.equals(tableName) & tbl.recordId.equals(recordId)))
          .go();

      await db.into(db.localOutbox).insert(
        LocalOutboxCompanion.insert(
          targetTable: tableName,
          recordId: recordId,
          operation: operation,
          payload: jsonEncode(payload),
          createdAt: DateTime.now(),
          status: const Value(AppConstants.syncPending),
        ),
      );
    } catch (e) {
      print('Outbox queue error: $e');
    }

    if (connectivity.isConnected && SupabaseService.isAuthenticated) {
      processOutboxQueue();
    }
  }

  Future<void> syncAll({
    Function()? onComplete,
  }) async {
    if (_isSyncing || !connectivity.isConnected) {
      _syncStatusController.add('failed');
      return;
    }

    _isSyncing = true;
    _syncStatusController.add('syncing');

    try {
      if (SupabaseService.isAuthenticated) {
        await processOutboxQueue();
      }
      _syncStatusController.add('synced');
    } catch (e) {
      print('SyncAll error: $e');
      _syncStatusController.add('failed');
    } finally {
      _isSyncing = false;
      if (onComplete != null) onComplete();
    }
  }

  Future<void> processOutboxQueue() async {
    if (!connectivity.isConnected || !SupabaseService.isAuthenticated) return;
    _isSyncing = true;
    _syncStatusController.add('syncing');

    try {
      // 1. Auto-recover any local vault items marked 'pending' or 'failed' missing from outbox
      final pendingVaultItems = await (db.select(db.localVaultItems)
            ..where((tbl) => tbl.syncStatus.equals(AppConstants.syncPending) | tbl.syncStatus.equals(AppConstants.syncFailed)))
          .get();

      for (final item in pendingVaultItems) {
        final existingOutbox = await (db.select(db.localOutbox)
              ..where((tbl) => tbl.targetTable.equals(AppConstants.vaultItemsTable) & tbl.recordId.equals(item.id)))
            .getSingleOrNull();

        if (existingOutbox == null) {
          final payload = {
            'id': item.id,
            'user_id': item.userId,
            'folder_id': item.folderId,
            'item_type': item.itemType,
            'title_encrypted': item.titleEncrypted,
            'data_encrypted': item.dataEncrypted,
            'iv': item.iv,
            'is_favorite': item.isFavorite,
            'created_at': item.createdAt.toIso8601String(),
            'updated_at': item.updatedAt.toIso8601String(),
          };
          await db.into(db.localOutbox).insert(
            LocalOutboxCompanion.insert(
              targetTable: AppConstants.vaultItemsTable,
              recordId: item.id,
              operation: 'insert',
              payload: jsonEncode(payload),
              createdAt: DateTime.now(),
              status: const Value(AppConstants.syncPending),
            ),
          );
        }
      }

      // 2. Auto-recover any local folders marked 'pending' or 'failed' missing from outbox
      final pendingFolders = await (db.select(db.localFolders)
            ..where((tbl) => tbl.syncStatus.equals(AppConstants.syncPending) | tbl.syncStatus.equals(AppConstants.syncFailed)))
          .get();

      for (final f in pendingFolders) {
        final existingOutbox = await (db.select(db.localOutbox)
              ..where((tbl) => tbl.targetTable.equals(AppConstants.foldersTable) & tbl.recordId.equals(f.id)))
            .getSingleOrNull();

        if (existingOutbox == null) {
          final payload = {
            'id': f.id,
            'user_id': f.userId,
            'parent_id': f.parentId,
            'name_encrypted': f.nameEncrypted,
            'icon': f.icon,
            'color': f.color,
            'iv': f.iv,
            'created_at': f.createdAt.toIso8601String(),
            'updated_at': f.updatedAt.toIso8601String(),
          };
          await db.into(db.localOutbox).insert(
            LocalOutboxCompanion.insert(
              targetTable: AppConstants.foldersTable,
              recordId: f.id,
              operation: 'insert',
              payload: jsonEncode(payload),
              createdAt: DateTime.now(),
              status: const Value(AppConstants.syncPending),
            ),
          );
        }
      }

      // 3. Process all pending items in outbox queue
      final pendingItems = await (db.select(db.localOutbox)
            ..where((tbl) => tbl.status.equals(AppConstants.syncPending))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
          .get();

      for (final item in pendingItems) {
        bool success = await _processSingleItem(item);
        if (success) {
          await (db.delete(db.localOutbox)..where((tbl) => tbl.id.equals(item.id))).go();
        } else {
          await (db.update(db.localOutbox)..where((tbl) => tbl.id.equals(item.id)))
              .write(LocalOutboxCompanion(
            retryCount: Value(item.retryCount + 1),
            status: Value(item.retryCount >= 3 ? AppConstants.syncFailed : AppConstants.syncPending),
          ));
        }
      }
      _syncStatusController.add('synced');
    } catch (e) {
      _syncStatusController.add('failed');
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _processSingleItem(LocalOutboxData item) async {
    final client = SupabaseService.client;
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;

    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId != null &&
        (payload['user_id'] == null || payload['user_id'] == AppConstants.defaultLocalUserId)) {
      payload['user_id'] = currentUserId;
    }

    try {
      if (item.operation == 'insert' || item.operation == 'update') {
        payload['id'] = item.recordId;
        await client.from(item.targetTable).upsert(payload);
      } else if (item.operation == 'delete') {
        await client.from(item.targetTable).delete().eq('id', item.recordId);
      }

      _updateLocalSyncStatus(item.targetTable, item.recordId, AppConstants.syncSynced);
      return true;
    } catch (e) {
      print('Sync failure for item ${item.recordId} on ${item.targetTable}: $e');
      return false;
    }
  }

  void _updateLocalSyncStatus(String table, String id, String status) async {
    if (table == AppConstants.foldersTable) {
      await (db.update(db.localFolders)..where((tbl) => tbl.id.equals(id)))
          .write(LocalFoldersCompanion(syncStatus: Value(status)));
    } else if (table == AppConstants.vaultItemsTable) {
      await (db.update(db.localVaultItems)..where((tbl) => tbl.id.equals(id)))
          .write(LocalVaultItemsCompanion(syncStatus: Value(status)));
    }
    _itemSyncedController.add((table: table, id: id, status: status));
  }
}
