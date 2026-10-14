# Offline POS: append-only ledger, replayed on reconnect

**The trap:** two registers are offline and each sells the last-but-few of an item. Each one only knows "stock is now 4". When the network returns and both push "stock = 4", one sale is lost.

**The fix shown in the Reel:** don't store the stock number. Append what happened (a sale is `-1`) to a local SQLite ledger, and replay those entries to the server in order when the connection returns. Changes add up instead of overwriting each other.

| File | What it does |
|---|---|
| [`lib/ledger.dart`](lib/ledger.dart) | SQLite ledger: append entries, derive stock, list pending entries |
| [`lib/sync.dart`](lib/sync.dart) | `replay` (sequential, stops on failure) plus a fake server with both styles: add a change vs overwrite a number |
| [`test/pos_sync_test.dart`](test/pos_sync_test.dart) | 6 tests, including the two-register case both ways |

```bash
dart pub get
dart test
```

Needs a system SQLite library (present on macOS and most Linux distributions).

## What the tests show

- Two offline registers each sell one item with starting stock 5. Replaying ledger entries gives **3**. Pushing each register's "stock = 4" gives **4**: a sale vanished.
- Replay is sequential. If one entry fails, it stops, the failed entry and the ones after it stay pending, and the next replay resumes from there.

## Limits

- **No duplicate protection.** If the server applies an entry but the response is lost, a retry would apply it twice. Fix that with idempotency keys (see [`day_40_offline_sync`](../day_40_offline_sync)).
- **No negative-stock rules.** Two registers can still oversell while offline. The ledger makes the totals correct afterwards. It doesn't prevent the oversell. The Reel's "auto backorders" are not implemented.
- The server is a fake map in memory. A real one would store the same entries, ideally in a transaction.
- No real network, no UI, and nothing here was run on a real POS.
