/// Splits [bytes] into pieces of at most [size] bytes.
Iterable<List<int>> chunk(List<int> bytes, {int size = 20}) sync* {
  for (var i = 0; i < bytes.length; i += size) {
    yield bytes.sublist(i, i + size > bytes.length ? bytes.length : i + size);
  }
}

/// Sends bytes in small chunks with a short pause between them, so a Bluetooth
/// printer's buffer isn't overrun.
///
/// [write] is whatever sends bytes to your printer (a Bluetooth plugin call).
/// [delay] defaults to a real delay and can be replaced in tests.
class ChunkedWriter {
  ChunkedWriter(
    this.write, {
    this.size = 20,
    this.interval = const Duration(milliseconds: 10),
    Future<void> Function(Duration)? delay,
  }) : _delay = delay ?? Future<void>.delayed;

  final Future<void> Function(List<int> chunk) write;
  final int size;
  final Duration interval;
  final Future<void> Function(Duration) _delay;

  Future<void> send(List<int> bytes) async {
    final chunks = chunk(bytes, size: size).toList();
    for (var i = 0; i < chunks.length; i++) {
      await write(chunks[i]);
      if (i < chunks.length - 1) await _delay(interval); // no pause after the last chunk
    }
  }
}
