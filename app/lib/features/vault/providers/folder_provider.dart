import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/folder_model.dart';

class FolderProvider extends ChangeNotifier {
  final AppDatabase db;
  final CryptoService cryptoService;
  final SyncEngine syncEngine;

  List<FolderModel> _folders = [];
  List<FolderModel> get folders => _folders;

  String? _selectedFolderId;
  String? get selectedFolderId => _selectedFolderId;

  FolderProvider({
    required this.db,
    required this.cryptoService,
    required this.syncEngine,
  }) {
    loadFolders();
    syncEngine.onItemSynced.listen((event) {
      if (event.table == AppConstants.foldersTable) {
        markFolderSynced(event.id, event.status);
      }
    });
  }

  void markFolderSynced(String id, [String status = AppConstants.syncSynced]) {
    final idx = _folders.indexWhere((f) => f.id == id);
    if (idx != -1) {
      final f = _folders[idx];
      _folders[idx] = FolderModel(
        id: f.id,
        userId: f.userId,
        parentId: f.parentId,
        name: f.name,
        icon: f.icon,
        color: f.color,
        sortOrder: f.sortOrder,
        syncStatus: status,
        createdAt: f.createdAt,
        updatedAt: f.updatedAt,
      );
      notifyListeners();
    }
  }

  void selectFolder(String? folderId) {
    _selectedFolderId = folderId;
    notifyListeners();
  }

  Future<void> loadFolders() async {
    final localRows = await db.select(db.localFolders).get();
    List<FolderModel> loaded = [];

    for (var row in localRows) {
      String name = row.nameEncrypted;
      try {
        if (row.iv.isNotEmpty) {
          name = await cryptoService.decryptText(row.nameEncrypted, row.iv);
        }
      } catch (e) {
        // Fallback if decryption fails
      }

      loaded.add(FolderModel(
        id: row.id,
        userId: row.userId,
        parentId: row.parentId,
        name: name,
        icon: row.icon,
        color: row.color,
        sortOrder: row.sortOrder,
        syncStatus: row.syncStatus,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      ));
    }

    _folders = loaded;
    notifyListeners();
  }

  Future<void> createFolder({
    required String name,
    String? parentId,
    String icon = 'folder',
    String color = '#6366F1',
  }) async {
    final userId = SupabaseService.currentUser?.id ?? AppConstants.defaultLocalUserId;
    final encResult = await cryptoService.encryptText(name);
    final id = const Uuid().v4();
    final now = DateTime.now();

    await db.into(db.localFolders).insert(
      LocalFoldersCompanion.insert(
        id: id,
        userId: userId,
        parentId: drift.Value(parentId),
        nameEncrypted: encResult['cipherText']!,
        icon: drift.Value(icon),
        color: drift.Value(color),
        iv: drift.Value(encResult['iv']!),
        createdAt: now,
        updatedAt: now,
        syncStatus: const drift.Value(AppConstants.syncPending),
      ),
    );

    final payload = {
      'id': id,
      'user_id': userId,
      'parent_id': parentId,
      'name_encrypted': encResult['cipherText'],
      'icon': icon,
      'color': color,
      'iv': encResult['iv'],
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    await syncEngine.queueMutation(
      tableName: AppConstants.foldersTable,
      recordId: id,
      operation: 'insert',
      payload: payload,
    );

    await loadFolders();
  }

  Future<void> deleteFolder(String folderId) async {
    if (_selectedFolderId == folderId) {
      _selectedFolderId = null;
    }

    _folders.removeWhere((f) => f.id == folderId);
    notifyListeners();

    try {
      await (db.delete(db.localFolders)..where((tbl) => tbl.id.equals(folderId))).go();
      await syncEngine.queueMutation(
        tableName: AppConstants.foldersTable,
        recordId: folderId,
        operation: 'delete',
        payload: {'id': folderId},
      );
    } catch (e) {
      print('Folder delete error: $e');
    }
  }
}
