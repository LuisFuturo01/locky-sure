import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/folders_table.dart';
import 'tables/vault_items_table.dart';
import 'tables/item_links_table.dart';
import 'tables/outbox_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [LocalFolders, LocalVaultItems, LocalItemLinks, LocalOutbox])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'surething_local_v1.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
