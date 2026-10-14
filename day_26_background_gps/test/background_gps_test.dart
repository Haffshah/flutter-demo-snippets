import 'package:background_gps_demo/location_batcher.dart';
import 'package:background_gps_demo/polling_policy.dart';
import 'package:test/test.dart';

void main() {
  group('PollingPolicy', () {
    test('still: asks rarely', () {
      final p = PollingPolicy.forSpeed(0);
      expect(p.pollInterval, greaterThanOrEqualTo(const Duration(seconds: 30)));
    });

    test('moving slowly polls more often than standing still', () {
      expect(PollingPolicy.forSpeed(1).pollInterval, lessThan(PollingPolicy.forSpeed(0).pollInterval));
    });

    test('very fast: backs off again', () {
      expect(PollingPolicy.forSpeed(30).pollInterval, greaterThan(PollingPolicy.forSpeed(5).pollInterval));
    });
  });

  group('LocationBatcher', () {
    late DateTime clock;
    late List<List<int>> uploads;
    late InMemoryPointStore<int> store;
    late bool failUpload;
    late LocationBatcher<int> batcher;

    setUp(() {
      clock = DateTime(2026, 1, 1, 12);
      uploads = [];
      failUpload = false;
      store = InMemoryPointStore<int>();
      batcher = LocationBatcher<int>(
        store: store,
        now: () => clock,
        upload: (batch) async {
          if (failUpload) throw Exception('offline');
          uploads.add(batch);
        },
      );
    });

    test('points are held, not sent one by one', () async {
      for (var i = 0; i < 5; i++) {
        clock = clock.add(const Duration(seconds: 10));
        await batcher.record(i);
      }
      expect(uploads, isEmpty);
      expect((await store.all()).length, 5);
    });

    test('one batch is sent once the interval has passed', () async {
      await batcher.record(1);
      await batcher.record(2);
      clock = clock.add(const Duration(minutes: 2));
      await batcher.record(3);
      expect(uploads, [
        [1, 2, 3]
      ]);
      expect(await store.all(), isEmpty);
    });

    test('failed upload keeps the points and retries later', () async {
      await batcher.record(1);
      failUpload = true;
      clock = clock.add(const Duration(minutes: 3));
      await batcher.record(2);
      expect(uploads, isEmpty);
      expect((await store.all()).length, 2);

      failUpload = false;
      expect(await batcher.flush(), isTrue);
      expect(uploads.single, [1, 2]);
    });

    test('flush with nothing stored sends nothing', () async {
      expect(await batcher.flush(), isFalse);
      expect(uploads, isEmpty);
    });
  });
}
