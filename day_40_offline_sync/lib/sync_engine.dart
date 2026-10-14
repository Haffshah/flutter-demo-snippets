import 'database.dart';

/// What the server side looks like to the engine. Implement with your HTTP client.
abstract class OrderApi {
  /// Must treat [idempotencyKey] as "create at most once": if the same key arrives again
  /// (for example because the response was lost), return success without creating a duplicate.
  Future<void> upsertOrder(Order order, {required String idempotencyKey});
}

/// Step 3: drain the outbox. Each pending row is sent with its own id as the idempotency key.
class SyncEngine {
  SyncEngine(this._db, this._api, {this.maxRetries = 3});

  final AppDatabase _db;
  final OrderApi _api;
  final int maxRetries;

  /// Returns how many rows were synced in this pass.
  Future<int> syncPending() async {
    var synced = 0;
    for (final order in await _db.pending()) {
      try {
        await _api.upsertOrder(order, idempotencyKey: order.id);
        await _db.markSynced(order.id);
        synced++;
      } catch (_) {
        await _db.incrementRetry(order.id);
        if (order.retryCount + 1 >= maxRetries) {
          await _db.markFailed(order.id); // stop retrying forever; surface it to the user
        }
      }
    }
    return synced;
  }
}
