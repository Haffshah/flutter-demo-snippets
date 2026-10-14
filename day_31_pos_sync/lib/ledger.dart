import 'package:sqlite3/sqlite3.dart';

class LedgerEntry {
  const LedgerEntry({required this.id, required this.registerId, required this.sku, required this.delta});

  final String id;
  final String registerId;
  final String sku;

  /// Change in stock: -1 for one sale, +10 for a delivery.
  final int delta;
}

/// A register's local database. It never stores "current stock". It only appends what happened,
/// and current stock is always the starting stock plus the sum of the entries.
class Ledger {
  Ledger(this._db) {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS ledger (
        seq INTEGER PRIMARY KEY AUTOINCREMENT,   -- order the register recorded things in
        id TEXT NOT NULL UNIQUE,
        register_id TEXT NOT NULL,
        sku TEXT NOT NULL,
        delta INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )''');
  }

  factory Ledger.inMemory() => Ledger(sqlite3.openInMemory());

  final Database _db;

  /// Appends one transaction. Entries are never edited or deleted.
  void record(LedgerEntry e) => _db.execute(
        'INSERT INTO ledger (id, register_id, sku, delta) VALUES (?, ?, ?, ?)',
        [e.id, e.registerId, e.sku, e.delta],
      );

  /// What this register believes the stock is: [base] plus everything recorded for [sku].
  int stock(String sku, {required int base}) {
    final row = _db.select('SELECT COALESCE(SUM(delta), 0) AS d FROM ledger WHERE sku = ?', [sku]).first;
    return base + (row['d'] as int);
  }

  /// Entries not yet confirmed by the server, oldest first.
  List<LedgerEntry> pending() => _db
      .select('SELECT id, register_id, sku, delta FROM ledger WHERE synced = 0 ORDER BY seq')
      .map((r) => LedgerEntry(
            id: r['id'] as String,
            registerId: r['register_id'] as String,
            sku: r['sku'] as String,
            delta: r['delta'] as int,
          ))
      .toList();

  void markSynced(String id) => _db.execute('UPDATE ledger SET synced = 1 WHERE id = ?', [id]);

  void close() => _db.dispose();
}
