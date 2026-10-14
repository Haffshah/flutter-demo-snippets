/// Where points wait before upload. Back it with Hive, SQLite or anything else.
/// The demo uses [InMemoryPointStore].
abstract class PointStore<T> {
  Future<void> add(T point);
  Future<List<T>> all();
  Future<void> clear();
}

class InMemoryPointStore<T> implements PointStore<T> {
  final List<T> _items = [];

  @override
  Future<void> add(T point) async => _items.add(point);

  @override
  Future<List<T>> all() async => List.unmodifiable(_items);

  @override
  Future<void> clear() async => _items.clear();
}

/// Tip 2 from the carousel: write positions locally, then upload them in one batch every
/// [flushInterval] (2 minutes in the carousel) instead of one request per location tick.
class LocationBatcher<T> {
  LocationBatcher({
    required this.store,
    required this.upload,
    required DateTime Function() now,
    this.flushInterval = const Duration(minutes: 2),
  })  : _now = now,
        _lastFlush = now();

  final PointStore<T> store;

  /// Sends one batch. Throw to signal failure. The points are kept and retried next time.
  final Future<void> Function(List<T> batch) upload;
  final Duration flushInterval;
  final DateTime Function() _now;
  DateTime _lastFlush;

  Future<void> record(T point) async {
    await store.add(point);
    if (_now().difference(_lastFlush) >= flushInterval) await flush();
  }

  /// Uploads everything stored. Returns true if a batch was sent.
  Future<bool> flush() async {
    final batch = await store.all();
    if (batch.isEmpty) {
      _lastFlush = _now();
      return false;
    }
    try {
      await upload(batch);
    } catch (_) {
      return false; // keep the points; try again on the next call
    }
    await store.clear();
    _lastFlush = _now();
    return true;
  }
}
