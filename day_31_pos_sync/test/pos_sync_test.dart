import 'package:pos_sync_demo/ledger.dart';
import 'package:pos_sync_demo/sync.dart';
import 'package:test/test.dart';

LedgerEntry sale(String id, String register, {String sku = 'item-a', int qty = 1}) =>
    LedgerEntry(id: id, registerId: register, sku: sku, delta: -qty);

void main() {
  late Ledger registerA;
  late Ledger registerB;
  late InventoryServer server;

  setUp(() {
    registerA = Ledger.inMemory();
    registerB = Ledger.inMemory();
    server = InventoryServer({'item-a': 5});
  });
  tearDown(() {
    registerA.close();
    registerB.close();
  });

  test('stock is derived from the ledger, not stored', () {
    registerA.record(sale('t1', 'A'));
    registerA.record(sale('t2', 'A', qty: 2));
    registerA.record(const LedgerEntry(id: 't3', registerId: 'A', sku: 'item-a', delta: 10));
    expect(registerA.stock('item-a', base: 5), 5 - 1 - 2 + 10);
  });

  test('two offline registers each sell one: ledger replay ends with both sales counted', () async {
    registerA.record(sale('a1', 'A'));
    registerB.record(sale('b1', 'B'));
    expect(registerA.stock('item-a', base: 5), 4);
    expect(registerB.stock('item-a', base: 5), 4);

    await replay(registerA, (e) async => server.applyDelta(e));
    await replay(registerB, (e) async => server.applyDelta(e));
    expect(server.stock['item-a'], 3);
  });

  test('the same two sales with state overrides lose one sale', () {
    // Each register only knows "stock is 4" and pushes that number.
    registerA.record(sale('a1', 'A'));
    registerB.record(sale('b1', 'B'));
    server.overwriteStock('item-a', registerA.stock('item-a', base: 5));
    server.overwriteStock('item-a', registerB.stock('item-a', base: 5));
    expect(server.stock['item-a'], 4); // should be 3: one sale vanished
  });

  test('replay sends entries in the order they were recorded and marks them synced', () async {
    registerA.record(sale('a1', 'A'));
    registerA.record(sale('a2', 'A'));
    registerA.record(sale('a3', 'A'));
    final order = <String>[];
    final sent = await replay(registerA, (e) async => order.add(e.id));
    expect(sent, 3);
    expect(order, ['a1', 'a2', 'a3']);
    expect(registerA.pending(), isEmpty);
  });

  test('a failure stops the replay; the failed entry and later ones stay pending, then resume', () async {
    registerA.record(sale('a1', 'A'));
    registerA.record(sale('a2', 'A'));
    registerA.record(sale('a3', 'A'));

    var failOn = 'a2';
    Future<void> send(LedgerEntry e) async {
      if (e.id == failOn) throw Exception('offline again');
      server.applyDelta(e);
    }

    expect(await replay(registerA, send), 1);
    expect(registerA.pending().map((e) => e.id), ['a2', 'a3']);
    expect(server.stock['item-a'], 4);

    failOn = '';
    expect(await replay(registerA, send), 2);
    expect(registerA.pending(), isEmpty);
    expect(server.stock['item-a'], 2);
  });

  test('entries are append-only: recording the same id twice is rejected', () {
    registerA.record(sale('a1', 'A'));
    expect(() => registerA.record(sale('a1', 'A')), throwsA(isA<Exception>()));
  });
}
