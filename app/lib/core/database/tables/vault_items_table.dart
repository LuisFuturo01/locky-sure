import 'package:drift/drift.dart';

class LocalVaultItems extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get folderId => text().named('folder_id').nullable()();
  TextColumn get itemType => text().named('item_type').withDefault(const Constant('password'))();
  TextColumn get titleEncrypted => text().named('title_encrypted')();
  TextColumn get dataEncrypted => text().named('data_encrypted')();
  TextColumn get iv => text()();
  BoolColumn get isFavorite => boolean().named('is_favorite').withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().named('sort_order').withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  TextColumn get syncStatus => text().named('sync_status').withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}
