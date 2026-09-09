import 'package:flutter/foundation.dart';
import '../../vault/models/vault_item_model.dart';
import '../../vault/providers/vault_provider.dart';
import '../../vault/providers/folder_provider.dart';
import '../../../core/sync/sync_engine.dart';

class DashboardProvider extends ChangeNotifier {
  final VaultProvider vaultProvider;
  final FolderProvider folderProvider;
  final SyncEngine syncEngine;

  DashboardProvider({
    required this.vaultProvider,
    required this.folderProvider,
    required this.syncEngine,
  });

  int get totalItems => vaultProvider.items.length;
  int get totalFolders => folderProvider.folders.length;
  int get pendingSyncItems =>
      vaultProvider.items.where((i) => i.syncStatus == 'pending').length;

  int get passwordCount =>
      vaultProvider.items.where((i) => i.itemType == 'password').length;
  int get cardCount =>
      vaultProvider.items.where((i) => i.itemType == 'card').length;
  int get noteCount =>
      vaultProvider.items.where((i) => i.itemType == 'note').length;

  List<VaultItemModel> get recentItems =>
      vaultProvider.items.take(5).toList();
}
