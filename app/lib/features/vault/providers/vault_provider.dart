import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/vault_item_model.dart';
import '../models/item_link_model.dart';

class VaultProvider extends ChangeNotifier {
  final AppDatabase db;
  final CryptoService cryptoService;
  final SyncEngine syncEngine;

  List<VaultItemModel> _items = [];
  List<VaultItemModel> get items => _items;

  List<ItemLinkModel> _links = [];
  List<ItemLinkModel> get links => _links;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  VaultProvider({
    required this.db,
    required this.cryptoService,
    required this.syncEngine,
  }) {
    loadItems();
    syncEngine.onItemSynced.listen((event) {
      if (event.table == AppConstants.vaultItemsTable) {
        markItemSynced(event.id, event.status);
      }
    });
  }

  void markItemSynced(String id, [String status = AppConstants.syncSynced]) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final item = _items[idx];
      _items[idx] = VaultItemModel(
        id: item.id,
        userId: item.userId,
        folderId: item.folderId,
        itemType: item.itemType,
        title: item.title,
        data: item.data,
        isFavorite: item.isFavorite,
        sortOrder: item.sortOrder,
        syncStatus: status,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      );
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<VaultItemModel> get filteredItems {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((i) => i.title.toLowerCase().contains(q) || i.itemType.toLowerCase().contains(q)).toList();
  }

  Future<void> loadItems() async {
    final localRows = await db.select(db.localVaultItems).get();
    List<VaultItemModel> loaded = [];

    for (var row in localRows) {
      String title = row.titleEncrypted;
      Map<String, dynamic> data = {};

      try {
        title = await cryptoService.decryptText(row.titleEncrypted, row.iv);
        final rawData = await cryptoService.decryptText(row.dataEncrypted, row.iv);
        data = jsonDecode(rawData);
      } catch (e) {
        // Fallback
      }

      loaded.add(VaultItemModel(
        id: row.id,
        userId: row.userId,
        folderId: row.folderId,
        itemType: row.itemType,
        title: title,
        data: data,
        isFavorite: row.isFavorite,
        sortOrder: row.sortOrder,
        syncStatus: row.syncStatus,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      ));
    }

    _items = loaded;

    final linkRows = await db.select(db.localItemLinks).get();
    _links = linkRows
        .map((r) => ItemLinkModel(
              id: r.id,
              sourceItemId: r.sourceItemId,
              targetItemId: r.targetItemId,
              linkType: r.linkType,
              createdAt: r.createdAt,
            ))
        .toList();

    notifyListeners();
  }

  Future<void> createItem({
    required String title,
    required String itemType,
    required Map<String, dynamic> data,
    String? folderId,
    bool isFavorite = false,
  }) async {
    final userId = SupabaseService.currentUser?.id ?? AppConstants.defaultLocalUserId;
    final encTitle = await cryptoService.encryptText(title);
    final sharedIv = encTitle['iv']!;
    final encData = await cryptoService.encryptText(jsonEncode(data), sharedIv);
    final id = const Uuid().v4();
    final now = DateTime.now();

    final newItem = VaultItemModel(
      id: id,
      userId: userId,
      folderId: folderId,
      itemType: itemType,
      title: title,
      data: data,
      isFavorite: isFavorite,
      sortOrder: 0,
      syncStatus: AppConstants.syncPending,
      createdAt: now,
      updatedAt: now,
    );

    // Instant UI update
    _items.insert(0, newItem);
    notifyListeners();

    // Persist in SQLite & Outbox
    await db.into(db.localVaultItems).insert(
      LocalVaultItemsCompanion.insert(
        id: id,
        userId: userId,
        folderId: drift.Value(folderId),
        itemType: drift.Value(itemType),
        titleEncrypted: encTitle['cipherText']!,
        dataEncrypted: encData['cipherText']!,
        iv: encTitle['iv']!,
        isFavorite: drift.Value(isFavorite),
        createdAt: now,
        updatedAt: now,
        syncStatus: const drift.Value(AppConstants.syncPending),
      ),
    );

    final payload = {
      'id': id,
      'user_id': userId,
      'folder_id': folderId,
      'item_type': itemType,
      'title_encrypted': encTitle['cipherText'],
      'data_encrypted': encData['cipherText'],
      'iv': encTitle['iv'],
      'is_favorite': isFavorite,
      'created_at': now.toUtc().toIso8601String(),
      'updated_at': now.toUtc().toIso8601String(),
    };

    await syncEngine.queueMutation(
      tableName: AppConstants.vaultItemsTable,
      recordId: id,
      operation: 'insert',
      payload: payload,
    );
  }

  Future<void> updateItem({
    required String id,
    required String title,
    required String itemType,
    required Map<String, dynamic> data,
    String? folderId,
    bool? isFavorite,
  }) async {
    final userId = SupabaseService.currentUser?.id ?? AppConstants.defaultLocalUserId;
    final encTitle = await cryptoService.encryptText(title);
    final sharedIv = encTitle['iv']!;
    final encData = await cryptoService.encryptText(jsonEncode(data), sharedIv);
    final now = DateTime.now();

    // Instant UI update in memory
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      final old = _items[index];
      _items[index] = VaultItemModel(
        id: id,
        userId: userId,
        folderId: folderId,
        itemType: itemType,
        title: title,
        data: data,
        isFavorite: isFavorite ?? old.isFavorite,
        sortOrder: old.sortOrder,
        syncStatus: AppConstants.syncPending,
        createdAt: old.createdAt,
        updatedAt: now,
      );
      notifyListeners();
    }

    // SQLite update
    await (db.update(db.localVaultItems)..where((tbl) => tbl.id.equals(id))).write(
      LocalVaultItemsCompanion(
        userId: drift.Value(userId),
        folderId: drift.Value(folderId),
        itemType: drift.Value(itemType),
        titleEncrypted: drift.Value(encTitle['cipherText']!),
        dataEncrypted: drift.Value(encData['cipherText']!),
        iv: drift.Value(encTitle['iv']!),
        isFavorite: isFavorite != null ? drift.Value(isFavorite) : const drift.Value.absent(),
        updatedAt: drift.Value(now),
        syncStatus: const drift.Value(AppConstants.syncPending),
      ),
    );

    // Payload for Supabase Update (Must NOT contain 'id' or invalid user_id)
    final Map<String, dynamic> payload = {
      'folder_id': folderId,
      'item_type': itemType,
      'title_encrypted': encTitle['cipherText'],
      'data_encrypted': encData['cipherText'],
      'iv': encTitle['iv'],
      'updated_at': now.toUtc().toIso8601String(),
    };
    if (isFavorite != null) payload['is_favorite'] = isFavorite;
    if (SupabaseService.currentUser != null) {
      payload['user_id'] = SupabaseService.currentUser!.id;
    }

    await syncEngine.queueMutation(
      tableName: AppConstants.vaultItemsTable,
      recordId: id,
      operation: 'update',
      payload: payload,
    );
  }

  Future<void> deleteItem(String id) async {
    final item = _items.firstWhere((i) => i.id == id, orElse: () => VaultItemModel(
      id: id, userId: '', itemType: 'password', title: '', data: {}, isFavorite: false, sortOrder: 0, syncStatus: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
    ));
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    await _permanentlyDeleteItem(id);
  }

  Future<void> deleteItemWithUndo(VaultItemModel item, BuildContext context) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    _items.removeAt(index);
    notifyListeners();

    bool undone = false;
    final snackBar = SnackBar(
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      content: Text('"${item.title}" eliminada'),
      action: SnackBarAction(
        label: 'DESHACER',
        textColor: Colors.amber,
        onPressed: () {
          undone = true;
          _items.insert(index <= _items.length ? index : _items.length, item);
          notifyListeners();
        },
      ),
    );

    final controller = ScaffoldMessenger.of(context).showSnackBar(snackBar);

    controller.closed.then((reason) async {
      if (!undone && reason != SnackBarClosedReason.action) {
        await _permanentlyDeleteItem(item.id);
      }
    });
  }

  Future<void> deleteMultipleItemsWithUndo(List<VaultItemModel> itemsToDelete, BuildContext context) async {
    if (itemsToDelete.isEmpty) return;

    _items.removeWhere((i) => itemsToDelete.any((t) => t.id == i.id));
    notifyListeners();

    bool undone = false;
    final snackBar = SnackBar(
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      content: Text('${itemsToDelete.length} elementos eliminados'),
      action: SnackBarAction(
        label: 'DESHACER',
        textColor: Colors.amber,
        onPressed: () {
          undone = true;
          for (final item in itemsToDelete) {
            if (!_items.any((i) => i.id == item.id)) {
              _items.add(item);
            }
          }
          notifyListeners();
        },
      ),
    );

    final controller = ScaffoldMessenger.of(context).showSnackBar(snackBar);

    controller.closed.then((reason) async {
      if (!undone && reason != SnackBarClosedReason.action) {
        for (final item in itemsToDelete) {
          await _permanentlyDeleteItem(item.id);
        }
      }
    });
  }

  Future<void> _permanentlyDeleteItem(String id) async {
    try {
      await (db.delete(db.localVaultItems)..where((tbl) => tbl.id.equals(id))).go();
      await syncEngine.queueMutation(
        tableName: AppConstants.vaultItemsTable,
        recordId: id,
        operation: 'delete',
        payload: {'id': id},
      );
    } catch (e) {
      print('Permanent delete error: $e');
    }
  }

  Future<void> linkItems({
    required String sourceItemId,
    required String targetItemId,
    String linkType = 'related',
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    await db.into(db.localItemLinks).insert(
      LocalItemLinksCompanion.insert(
        id: id,
        sourceItemId: sourceItemId,
        targetItemId: targetItemId,
        linkType: drift.Value(linkType),
        createdAt: now,
        syncStatus: const drift.Value(AppConstants.syncPending),
      ),
    );

    await syncEngine.queueMutation(
      tableName: AppConstants.itemLinksTable,
      recordId: id,
      operation: 'insert',
      payload: {
        'id': id,
        'source_item_id': sourceItemId,
        'target_item_id': targetItemId,
        'link_type': linkType,
        'created_at': now.toIso8601String(),
      },
    );

    await loadItems();
  }
}
