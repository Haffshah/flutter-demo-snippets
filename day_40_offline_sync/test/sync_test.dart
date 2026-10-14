import 'package:drift/native.dart';
import 'package:offline_sync_demo/conflict.dart';
import 'package:offline_sync_demo/database.dart';
import 'package:offline_sync_demo/sync_engine.dart';
import 'package:test/test.dart';

/// Fake server. Keyed by idempotency key, so a repeated key never creates a second row.
class FakeApi implements OrderApi {
  final Map<String, double> stored = {};
  int calls = 0;
  bool offline = false;
  bool dropResponseOnce = false;

  @override
  Future<void> upsertOrder(Order order, {required String idempotencyKey}) async {
    calls++;
    if (offline) throw Exception('no network');
    stored.putIfAbsent(idempotencyKey, () => order.amount); // server-side idempotency
    if (dropResponseOnce) {
      dropResponseOnce = false;
      throw Exception('response lost'); // server saved it, client never heard back
    }
  }
}

void main() {
  late AppDatabase db;
  late FakeApi api;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi();
    engine = SyncEngine(db, api, maxRetries: 3);
  });
  tearDown(() => db.close());

  test('local write is visible immediately, with no network involved', () async {
    api.offline = true;
    await db.addOrder(id: 'a', amount: 49.99);
    final rows = await db.watchOrders().first;
    expect(rows.single.id, 'a');
    expect(rows.single.syncStatus, SyncStatus.pending);
    expect(api.calls, 0);
  });

  test('sync drains the outbox and marks rows synced', () async {
    await db.addOrder(id: 'a', amount: 10);
    await db.addOrder(id: 'b', amount: 20);
    expect(await engine.syncPending(), 2);
    expect(await db.pending(), isEmpty);
    expect(api.stored, {'a': 10, 'b': 20});
  });

  test('offline: rows stay pending and retry count goes up', () async {
    api.offline = true;
    await db.addOrder(id: 'a', amount: 10);
    expect(await engine.syncPending(), 0);
    final row = (await db.watchOrders().first).single;
    expect(row.syncStatus, SyncStatus.pending);
    expect(row.retryCount, 1);
  });

  test('after max retries the row is marked failed, not retried forever', () async {
    api.offline = true;
    await db.addOrder(id: 'a', amount: 10);
    for (var i = 0; i < 3; i++) {
      await engine.syncPending();
    }
    expect((await db.watchOrders().first).single.syncStatus, SyncStatus.failed);
    final callsBefore = api.calls;
    await engine.syncPending();
    expect(api.calls, callsBefore, reason: 'failed rows are not sent again');
  });

  test('lost response: retry with the same key creates no duplicate', () async {
    api.dropResponseOnce = true;
    await db.addOrder(id: 'a', amount: 10);
    expect(await engine.syncPending(), 0); // server saved it, client saw an error
    expect(await engine.syncPending(), 1); // retry, same idempotency key
    expect(api.stored.length, 1);
  });

  group('conflict strategies', () {
    final t0 = DateTime(2026, 1, 1);
    final t1 = DateTime(2026, 1, 2);
    final t2 = DateTime(2026, 1, 3);

    test('last write wins picks the newer value', () {
      final r = lastWriteWins(Versioned('local', t2), Versioned('remote', t1));
      expect(r.winner.value, 'local');
      final r2 = lastWriteWins(Versioned('local', t1), Versioned('remote', t2));
      expect(r2.winner.value, 'remote');
    });

    test('server authoritative: only the server changed, server wins quietly', () {
      final r = serverAuthoritative(Versioned('local', t0), Versioned('remote', t2), lastSyncedAt: t1);
      expect(r.winner.value, 'remote');
      expect(r.needsUserDecision, isFalse);
    });

    test('server authoritative: both changed, server wins and the user is asked', () {
      final r = serverAuthoritative(Versioned('local', t2), Versioned('remote', t2), lastSyncedAt: t1);
      expect(r.winner.value, 'remote');
      expect(r.needsUserDecision, isTrue);
    });
  });
}
