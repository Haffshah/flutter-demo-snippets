# Offline-first writes with a Drift outbox

> From the carousel on Instagram: [Day 40, @_letsbuildapps](https://www.instagram.com/p/DdsSI5pDONB/)

Offline-first doesn't mean always offline. It means the app writes locally first, shows the result immediately, and syncs when it can.

```
tap "Place order"
  1. write to local SQLite (Drift) with sync_status = pending   -> UI updates now
  2. UI watches the table (a Drift stream)                       -> no spinner, no timeout
  3. SyncEngine drains the pending rows in the background
       success -> markSynced
       failure -> retry_count + 1, and after N tries -> failed
```

| File | What it shows |
|---|---|
| [`lib/database.dart`](lib/database.dart) | Drift table, local write, `watchOrders()` stream, outbox queries |
| [`lib/sync_engine.dart`](lib/sync_engine.dart) | Draining the outbox, retries, giving up after `maxRetries` |
| [`lib/conflict.dart`](lib/conflict.dart) | Two conflict strategies: last-write-wins and server-authoritative |
| [`test/sync_test.dart`](test/sync_test.dart) | 8 tests |

## Idempotency keys

The order id is a client-generated UUID, sent as the idempotency key. If the server saves an order but the response is lost, the retry sends the same key and the server must not create a second order. Auto-increment ids can't do this. One test covers exactly that case.

## Run it

```bash
dart pub get
dart run build_runner build --delete-conflicting-outputs   # regenerates database.g.dart (also committed)
dart test
```

Needs a system SQLite library (present on macOS and most Linux distributions).

## Conflict strategies (in `conflict.dart`)

- **Last write wins:** newer timestamp wins. Fine for low-stakes data like preferences. Clocks differ between devices, and the losing change is silently lost.
- **Server authoritative:** if only the server changed, it wins. If both changed since the last sync, the server wins **and** the user is asked.
- **CRDTs / event sourcing** (for collaborative editing) are mentioned in the carousel but **not implemented here**.

## Limits

- The server is a fake in the tests. A real API must honour the idempotency key.
- No network-change listener, background scheduling or batching. Call `syncPending()` from a connectivity listener, a timer or a background task of your choice.
- Rows are sent one at a time, and nothing here handles two devices editing the same row at the same moment beyond the strategies above.
