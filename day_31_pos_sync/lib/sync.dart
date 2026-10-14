import 'ledger.dart';

/// Stand-in for the central inventory.
class InventoryServer {
  InventoryServer(Map<String, int> initialStock) : stock = Map.of(initialStock);

  final Map<String, int> stock;

  /// Ledger style: apply a change. Two registers' changes add up.
  void applyDelta(LedgerEntry e) => stock[e.sku] = (stock[e.sku] ?? 0) + e.delta;

  /// State-override style: replace the number. Whoever syncs last wins.
  void overwriteStock(String sku, int value) => stock[sku] = value;
}

/// Replays pending entries one at a time, in the order the register recorded them.
/// If one fails, it stops there. The failed entry and everything after it stay pending.
/// Returns how many entries were sent.
///
/// Note: if the server applies an entry but the response is lost, a retry would apply it twice.
/// See `day_40_offline_sync` for idempotency keys, which solve that.
Future<int> replay(Ledger ledger, Future<void> Function(LedgerEntry) send) async {
  var sent = 0;
  for (final entry in ledger.pending()) {
    try {
      await send(entry);
    } catch (_) {
      break;
    }
    ledger.markSynced(entry.id);
    sent++;
  }
  return sent;
}
