import 'dart:typed_data';

import 'package:low_end_matching_demo/face_matcher.dart';
import 'package:low_end_matching_demo/frame_buffer_pool.dart';
import 'package:test/test.dart';

Float32List v(List<double> x) => Float32List.fromList(x);

void main() {
  group('FrameBufferPool', () {
    test('buffers are width * height * 4 bytes', () {
      final pool = FrameBufferPool(width: 8, height: 4);
      expect(pool.tryAcquire()!.length, 8 * 4 * 4);
    });

    test('a released buffer is handed out again (the same object, no new allocation)', () {
      final pool = FrameBufferPool(width: 8, height: 4, count: 2);
      final a = pool.tryAcquire()!;
      pool.release(a);
      final again = pool.tryAcquire()!;
      expect(identical(a, again), isTrue);
      expect(pool.allocations, 2, reason: 'only the 2 buffers created up front');
    });

    test('a thousand frames never allocate beyond the initial buffers', () {
      final pool = FrameBufferPool(width: 16, height: 16, count: 3);
      for (var i = 0; i < 1000; i++) {
        final b = pool.tryAcquire()!;
        b[0] = i % 256; // pretend to write a camera frame
        pool.release(b);
      }
      expect(pool.allocations, 3);
    });

    test('returns null when every buffer is in use, so the caller can drop the frame', () {
      final pool = FrameBufferPool(width: 4, height: 4, count: 1);
      expect(pool.tryAcquire(), isNotNull);
      expect(pool.tryAcquire(), isNull);
    });

    test('rejects a wrong-sized buffer and a double release', () {
      final pool = FrameBufferPool(width: 4, height: 4, count: 1);
      expect(() => pool.release(Uint8List(10)), throwsArgumentError);
      final b = pool.tryAcquire()!;
      pool.release(b);
      expect(() => pool.release(b), throwsStateError);
    });
  });

  group('cosineSimilarity', () {
    test('identical, orthogonal and opposite vectors', () {
      expect(cosineSimilarity(v([1, 2, 3]), v([1, 2, 3])), closeTo(1, 1e-6));
      expect(cosineSimilarity(v([1, 0]), v([0, 1])), closeTo(0, 1e-6));
      expect(cosineSimilarity(v([1, 0]), v([-1, 0])), closeTo(-1, 1e-6));
    });

    test('a zero vector gives 0, not NaN', () {
      expect(cosineSimilarity(v([0, 0]), v([1, 1])), 0);
    });

    test('different lengths are rejected', () {
      expect(() => cosineSimilarity(v([1]), v([1, 2])), throwsArgumentError);
    });
  });

  group('FaceMatcher', () {
    final templates = {'alice': v([1, 0, 0]), 'bob': v([0, 1, 0])};

    test('returns the closest enrolled template', () {
      final m = FaceMatcher(templates).match(v([0.9, 0.1, 0]));
      expect(m!.id, 'alice');
      expect(m.score, greaterThan(0.9));
    });

    test('returns null when nothing is similar enough', () {
      expect(FaceMatcher(templates).match(v([0, 0, 1])), isNull);
    });

    test('the isolate version gives the same answer as the direct call', () async {
      final matcher = FaceMatcher(templates);
      final probe = v([0.1, 0.95, 0]);
      final direct = matcher.match(probe)!;
      final viaIsolate = (await matcher.matchOffMainThread(probe))!;
      expect(viaIsolate.id, direct.id);
      expect(viaIsolate.score, closeTo(direct.score, 1e-9));
    });
  });

  group('whole pipeline with the stand-in embedding', () {
    test('frame buffer -> embedding -> match', () async {
      final pool = FrameBufferPool(width: 8, height: 8, count: 2);

      Uint8List frame(int base) {
        final b = pool.tryAcquire()!;
        for (var i = 0; i < b.length; i++) {
          b[i] = (base + i * 7) % 256;
        }
        return b;
      }

      final enrolled = frame(10);
      final templates = {'person-1': fakeEmbedding(enrolled)};
      pool.release(enrolled);

      final probe = frame(10); // same pixels again, from the reused buffer
      final result = await FaceMatcher(templates).matchOffMainThread(fakeEmbedding(probe));
      pool.release(probe);

      expect(result!.id, 'person-1');
      expect(result.score, closeTo(1, 1e-6));
      expect(pool.allocations, 2);
    });

    test('the stand-in embedding is normalized', () {
      final e = fakeEmbedding(Uint8List.fromList(List.generate(256, (i) => i)));
      final norm = e.fold<double>(0, (a, x) => a + x * x);
      expect(norm, closeTo(1, 1e-5));
    });
  });
}
