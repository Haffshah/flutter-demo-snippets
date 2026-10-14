import 'package:drift/drift.dart';

part 'database.g.dart';

enum SyncStatus { pending, synced, failed }

/// Orders written locally first. The id is generated ON THE DEVICE (a UUID),
/// so it can double as the idempotency key when syncing.
class Orders extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(Constant(SyncStatus.pending.index))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Orders])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  /// Step 1: local write. The UI watches this table, so it updates immediately, online or not.
  Future<void> addOrder({required String id, required double amount, DateTime? now}) =>
      into(orders).insert(OrdersCompanion.insert(id: id, amount: amount, updatedAt: now ?? DateTime.now()));

  Stream<List<Order>> watchOrders() => (select(orders)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<List<Order>> pending() =>
      (select(orders)..where((t) => t.syncStatus.equals(SyncStatus.pending.index))).get();

  Future<void> markSynced(String id) => (update(orders)..where((t) => t.id.equals(id)))
      .write(OrdersCompanion(syncStatus: Value(SyncStatus.synced)));

  Future<void> markFailed(String id) => (update(orders)..where((t) => t.id.equals(id)))
      .write(OrdersCompanion(syncStatus: Value(SyncStatus.failed)));

  Future<void> incrementRetry(String id) async {
    await customUpdate(
      'UPDATE orders SET retry_count = retry_count + 1 WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {orders},
    );
  }
}
