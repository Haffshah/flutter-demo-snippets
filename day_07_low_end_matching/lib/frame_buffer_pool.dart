import 'dart:typed_data';

/// Slide 3: `final pixelBuffer = Uint8List(width * height * 4);` allocated once and reused.
///
/// Allocating a new buffer for every camera frame creates garbage the collector has to clean up.
/// On a weak device that shows up as stutter or out-of-memory crashes. This pool allocates its buffers
/// once, up front, and hands the same ones out again and again.
class FrameBufferPool {
  FrameBufferPool({required this.width, required this.height, int count = 3}) {
    for (var i = 0; i < count; i++) {
      _free.add(Uint8List(width * height * 4)); // RGBA
      allocations++;
    }
  }

  final int width;
  final int height;
  final List<Uint8List> _free = [];

  /// How many buffers were ever created. It stays at [count] for the life of the pool.
  int allocations = 0;

  int get available => _free.length;

  /// Takes a buffer, or returns null when all are in use. In a camera loop, null means "drop this frame",
  /// which is better than allocating more memory.
  Uint8List? tryAcquire() => _free.isEmpty ? null : _free.removeLast();

  void release(Uint8List buffer) {
    if (buffer.length != width * height * 4) throw ArgumentError('buffer has the wrong size for this pool');
    if (_free.any((b) => identical(b, buffer))) throw StateError('buffer was already released');
    _free.add(buffer);
  }
}
