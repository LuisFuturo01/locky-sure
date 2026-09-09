import 'package:drift/drift.dart';

class LocalFolders extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get parentId => text().named('parent_id').nullable()();
  TextColumn get nameEncrypted => text().named('name_encrypted')();
  TextColumn get icon => text().withDefault(const Constant('folder'))();
  TextColumn get color => text().withDefault(const Constant('#6366F1'))();
  IntColumn get sortOrder => integer().named('sort_order').withDefault(const Constant(0))();
  TextColumn get iv => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  TextColumn get syncStatus => text().named('sync_status').withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}
