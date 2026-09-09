import 'package:drift/drift.dart';

class LocalItemLinks extends Table {
  TextColumn get id => text()();
  TextColumn get sourceItemId => text().named('source_item_id')();
  TextColumn get targetItemId => text().named('target_item_id')();
  TextColumn get linkType => text().named('link_type').withDefault(const Constant('related'))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  TextColumn get syncStatus => text().named('sync_status').withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}
