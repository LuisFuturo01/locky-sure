import 'package:drift/drift.dart';

/// Outbox table for offline sync.
/// Each row represents a pending mutation that must be synced to Supabase.
class LocalOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text().named('table_name')();
  TextColumn get recordId => text().named('record_id')();
  TextColumn get operation => text()(); // 'insert', 'update', 'delete'
  TextColumn get payload => text()(); // JSON string of the data to sync
  IntColumn get retryCount => integer().named('retry_count').withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // 'pending', 'failed'
}
