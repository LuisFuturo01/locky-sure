import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../network/connectivity_service.dart';
import '../supabase/supabase_service.dart';
import '../constants/app_constants.dart';

class SyncEngine extends ChangeNotifier {
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
        syncAll();
      } else {
        _isSyncing = false;
        _syncStatusController.add('offline');
        notifyListeners();
      }
    });
  }

  int _nextOutboxId() {
    return DateTime.now().microsecondsSinceEpoch;
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
        LocalOutboxCompanion(
          id: Value(_nextOutboxId()),
          targetTable: Value(tableName),
          recordId: Value(recordId),
          operation: Value(operation),
          payload: Value(jsonEncode(payload)),
          createdAt: Value(DateTime.now()),
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

  String? _lastError;
  String? get lastError => _lastError;

  /// Main entry point: sync everything and call onComplete when done.
  /// Returns true if all items were successfully synced, false if errors occurred or offline.
  Future<bool> syncAll({
    Future<void> Function()? onComplete,
  }) async {
    _lastError = null;
    if (!connectivity.isConnected) {
      _lastError = 'Sin conexión a Internet';
      _isSyncing = false;
      _syncStatusController.add('failed');
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _syncStatusController.add('syncing');
    notifyListeners();

    bool overallSuccess = false;
    try {
      if (SupabaseService.isAuthenticated) {
        overallSuccess = await _doProcessOutboxQueue().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            _lastError = 'La sincronización tardó demasiado (Timeout)';
            return false;
          },
        );
        if (overallSuccess) {
          await _pullAndReconcile();
        }
      } else {
        _lastError = 'No hay una sesión activa de usuario. Vuelve a iniciar sesión.';
        overallSuccess = false;
      }
      _syncStatusController.add(overallSuccess ? 'synced' : 'failed');
    } catch (e) {
      _lastError = '$e';
      print('SyncAll error: $e');
      _syncStatusController.add('failed');
      overallSuccess = false;
    } finally {
      _isSyncing = false;
      notifyListeners();
      if (onComplete != null) await onComplete();
    }

    return overallSuccess;
  }

  Future<void> processOutboxQueue() async {
    if (!connectivity.isConnected || !SupabaseService.isAuthenticated) {
      _isSyncing = false;
      notifyListeners();
      return;
    }
    if (_isSyncing) return; // prevent re-entrancy
    _isSyncing = true;
    _syncStatusController.add('syncing');
    notifyListeners();

    try {
      final success = await _doProcessOutboxQueue().timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
      if (success) {
        await _pullAndReconcile();
      }
      _syncStatusController.add('synced');
    } catch (e) {
      _syncStatusController.add('failed');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Internal: does the actual outbox processing. Returns true if all items processed successfully.
  Future<bool> _doProcessOutboxQueue() async {
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
          'created_at': item.createdAt.toUtc().toIso8601String(),
          'updated_at': item.updatedAt.toUtc().toIso8601String(),
        };
        await db.into(db.localOutbox).insert(
          LocalOutboxCompanion(
            id: Value(_nextOutboxId()),
            targetTable: const Value(AppConstants.vaultItemsTable),
            recordId: Value(item.id),
            operation: const Value('insert'),
            payload: Value(jsonEncode(payload)),
            createdAt: Value(DateTime.now()),
            status: const Value(AppConstants.syncPending),
          ),
        );
      }
    }

    // 2. Auto-recover ONLY local folders marked 'pending' or 'failed' (NOT 'synced')
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
          'created_at': f.createdAt.toUtc().toIso8601String(),
          'updated_at': f.updatedAt.toUtc().toIso8601String(),
        };
        await db.into(db.localOutbox).insert(
          LocalOutboxCompanion(
            id: Value(_nextOutboxId()),
            targetTable: const Value(AppConstants.foldersTable),
            recordId: Value(f.id),
            operation: const Value('insert'),
            payload: Value(jsonEncode(payload)),
            createdAt: Value(DateTime.now()),
            status: const Value(AppConstants.syncPending),
          ),
        );
      }
    }

    // 3. Process all pending or failed items in outbox queue (folders FIRST, then vault items)
    final pendingItems = await (db.select(db.localOutbox)
          ..where((tbl) => tbl.status.equals(AppConstants.syncPending) | tbl.status.equals(AppConstants.syncFailed))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();

    if (pendingItems.isEmpty) return true;

    // Sort folders before vault_items to avoid FK folder_id mismatch
    final folderItems = pendingItems.where((i) => i.targetTable == AppConstants.foldersTable).toList();
    final otherItems = pendingItems.where((i) => i.targetTable != AppConstants.foldersTable).toList();
    final orderedPendingItems = [...folderItems, ...otherItems];

    bool allSuccess = true;
    for (final item in orderedPendingItems) {
      bool success = await _processSingleItem(item);
      if (success) {
        await (db.delete(db.localOutbox)..where((tbl) => tbl.id.equals(item.id))).go();
      } else {
        allSuccess = false;
        await (db.update(db.localOutbox)..where((tbl) => tbl.id.equals(item.id)))
            .write(LocalOutboxCompanion(
          retryCount: Value(item.retryCount + 1),
          status: Value(item.retryCount >= 3 ? AppConstants.syncFailed : AppConstants.syncPending),
        ));
      }
    }

    return allSuccess;
  }

  /// Pulls all remote data from Supabase and reconciles with local SQLite cache.
  /// Any local item marked 'synced' that is missing from Supabase will be deleted locally.
  /// Any remote item from Supabase will be upserted into local SQLite.
  Future<void> _pullAndReconcile() async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == null) return;
    final client = SupabaseService.client;

    try {
      // 1. Fetch remote folders
      final List<dynamic> remoteFolders = await client
          .from(AppConstants.foldersTable)
          .select()
          .eq('user_id', currentUserId);

      final remoteFolderIds = remoteFolders.map((f) => f['id'].toString()).toSet();
      final localFolders = await db.select(db.localFolders).get();

      // Delete local folders deleted on server (only if marked 'synced')
      for (final localF in localFolders) {
        if (localF.syncStatus == AppConstants.syncSynced && !remoteFolderIds.contains(localF.id)) {
          await (db.delete(db.localFolders)..where((tbl) => tbl.id.equals(localF.id))).go();
        }
      }

      // Upsert remote folders into local SQLite
      for (final rFolder in remoteFolders) {
        final id = rFolder['id'].toString();
        final nameEnc = rFolder['name_encrypted']?.toString() ?? '';
        final icon = rFolder['icon']?.toString() ?? 'folder';
        final color = rFolder['color']?.toString() ?? '#6366F1';
        final iv = rFolder['iv']?.toString() ?? '';
        final parentId = rFolder['parent_id']?.toString();
        final createdAtStr = rFolder['created_at']?.toString();
        final updatedAtStr = rFolder['updated_at']?.toString();

        final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr).toLocal() : DateTime.now();
        final updatedAt = updatedAtStr != null ? DateTime.parse(updatedAtStr).toLocal() : DateTime.now();

        await db.into(db.localFolders).insertOnConflictUpdate(
          LocalFoldersCompanion(
            id: Value(id),
            userId: Value(currentUserId),
            parentId: Value(parentId),
            nameEncrypted: Value(nameEnc),
            icon: Value(icon),
            color: Value(color),
            iv: Value(iv),
            createdAt: Value(createdAt),
            updatedAt: Value(updatedAt),
            syncStatus: const Value(AppConstants.syncSynced),
          ),
        );
      }

      // 2. Fetch remote vault items
      final List<dynamic> remoteVaultItems = await client
          .from(AppConstants.vaultItemsTable)
          .select()
          .eq('user_id', currentUserId);

      final remoteItemIds = remoteVaultItems.map((i) => i['id'].toString()).toSet();
      final localVaultItems = await db.select(db.localVaultItems).get();

      // Delete local vault items deleted on server (only if marked 'synced')
      for (final localItem in localVaultItems) {
        if (localItem.syncStatus == AppConstants.syncSynced && !remoteItemIds.contains(localItem.id)) {
          await (db.delete(db.localVaultItems)..where((tbl) => tbl.id.equals(localItem.id))).go();
        }
      }

      // Upsert remote vault items into local SQLite
      for (final rItem in remoteVaultItems) {
        final id = rItem['id'].toString();
        final folderId = rItem['folder_id']?.toString();
        final itemType = rItem['item_type']?.toString() ?? 'password';
        final titleEnc = rItem['title_encrypted']?.toString() ?? '';
        final dataEnc = rItem['data_encrypted']?.toString() ?? '';
        final iv = rItem['iv']?.toString() ?? '';
        final isFavorite = rItem['is_favorite'] == true;
        final createdAtStr = rItem['created_at']?.toString();
        final updatedAtStr = rItem['updated_at']?.toString();

        final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr).toLocal() : DateTime.now();
        final updatedAt = updatedAtStr != null ? DateTime.parse(updatedAtStr).toLocal() : DateTime.now();

        await db.into(db.localVaultItems).insertOnConflictUpdate(
          LocalVaultItemsCompanion(
            id: Value(id),
            userId: Value(currentUserId),
            folderId: Value(folderId),
            itemType: Value(itemType),
            titleEncrypted: Value(titleEnc),
            dataEncrypted: Value(dataEnc),
            iv: Value(iv),
            isFavorite: Value(isFavorite),
            createdAt: Value(createdAt),
            updatedAt: Value(updatedAt),
            syncStatus: const Value(AppConstants.syncSynced),
          ),
        );
      }

      // 3. Fetch remote item links
      try {
        final List<dynamic> remoteLinks = await client
            .from(AppConstants.itemLinksTable)
            .select();

        final remoteLinkIds = remoteLinks.map((l) => l['id'].toString()).toSet();
        final localLinks = await db.select(db.localItemLinks).get();

        for (final localL in localLinks) {
          if (localL.syncStatus == AppConstants.syncSynced && !remoteLinkIds.contains(localL.id)) {
            await (db.delete(db.localItemLinks)..where((tbl) => tbl.id.equals(localL.id))).go();
          }
        }

        for (final rLink in remoteLinks) {
          final id = rLink['id'].toString();
          final sourceId = rLink['source_item_id'].toString();
          final targetId = rLink['target_item_id'].toString();
          final linkType = rLink['link_type']?.toString() ?? 'related';
          final createdAtStr = rLink['created_at']?.toString();
          final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr).toLocal() : DateTime.now();

          await db.into(db.localItemLinks).insertOnConflictUpdate(
            LocalItemLinksCompanion(
              id: Value(id),
              sourceItemId: Value(sourceId),
              targetItemId: Value(targetId),
              linkType: Value(linkType),
              createdAt: Value(createdAt),
              syncStatus: const Value(AppConstants.syncSynced),
            ),
          );
        }
      } catch (e) {
        print('Warning fetching item_links: $e');
      }

    } catch (e) {
      print('Pull and reconcile error: $e');
      _lastError = 'Error al conciliar datos con el servidor: $e';
    }
  }

  Future<bool> _processSingleItem(LocalOutboxData item) async {
    final client = SupabaseService.client;
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;

    // Always enforce active user_id to satisfy Supabase RLS policy auth.uid() = user_id
    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == null) {
      _lastError = 'No se encontró un usuario activo logueado en Supabase.';
      print('❌ Sync failed: No active user logged in.');
      return false;
    }

    if (item.targetTable == AppConstants.itemLinksTable) {
      payload.remove('user_id');
    } else {
      payload['user_id'] = currentUserId;
    }

    // Auto-ensure user profile exists in public.profiles to prevent foreign key constraint failures
    try {
      final email = SupabaseService.currentUser?.email ?? 'user';
      final displayName = email.contains('@') ? email.split('@').first : email;
      await client.from('profiles').upsert({
        'id': currentUserId,
        'display_name': displayName,
      }, onConflict: 'id');
    } catch (e) {
      print('⚠️ Warning auto-upserting profile: $e');
    }

    // Clean null or empty string values from payload (e.g. folder_id: null or "")
    payload.removeWhere((key, value) => value == null);

    payload.remove('sync_status');
    payload.remove('syncStatus');

    if (payload['folder_id'] == '' || payload['folder_id'] == 'null') {
      payload.remove('folder_id');
    }
    if (payload['parent_id'] == '' || payload['parent_id'] == 'null') {
      payload.remove('parent_id');
    }

    // If item references a folder_id, ensure folder exists locally or strip folder_id to avoid FK error
    if (payload.containsKey('folder_id')) {
      final fid = payload['folder_id'].toString();
      final localFolder = await (db.select(db.localFolders)..where((tbl) => tbl.id.equals(fid))).getSingleOrNull();
      if (localFolder == null) {
        payload.remove('folder_id');
      }
    }

    // Fix timestamps — ensure they include UTC timezone for Supabase TIMESTAMPTZ
    for (final tsKey in ['created_at', 'updated_at']) {
      if (payload.containsKey(tsKey) && payload[tsKey] is String) {
        final ts = payload[tsKey] as String;
        if (!ts.endsWith('Z') && !ts.contains('+')) {
          payload[tsKey] = '${ts}Z';
        }
      }
    }

    try {
      if (item.operation == 'insert' || item.operation == 'update') {
        payload['id'] = item.recordId;
        await client.from(item.targetTable).upsert(payload);
      } else if (item.operation == 'delete') {
        await client.from(item.targetTable).delete().eq('id', item.recordId);
      }

      // AWAIT the local status update so SQLite is up-to-date before we return
      await _updateLocalSyncStatus(item.targetTable, item.recordId, AppConstants.syncSynced);
      return true;
    } catch (e) {
      _lastError = '$e';
      print('❌ Sync failure for ${item.targetTable}/${item.recordId} [${item.operation}]: $e');
      print('   Payload keys: ${payload.keys.toList()}');
      return false;
    }
  }

  Future<void> _updateLocalSyncStatus(String table, String id, String status) async {
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
