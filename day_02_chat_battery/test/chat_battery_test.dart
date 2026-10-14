import 'dart:math';

import 'package:chat_battery_demo/adaptive_socket_manager.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  group('AdaptiveSocketManager', () {
    test('pings every 30 s in the foreground', () {
      fakeAsync((async) {
        var pings = 0;
        final m = AdaptiveSocketManager(send: () => pings++)..start();
        async.elapse(const Duration(seconds: 95));
        expect(pings, 3); // at 30, 60, 90
        m.stop();
      });
    });

    test('going to the background stretches the interval to 120 s', () {
      fakeAsync((async) {
        var pings = 0;
        final m = AdaptiveSocketManager(send: () => pings++)..start();
        m.onAppStateChange(AppState.background);
        expect(m.currentInterval, const Duration(seconds: 120));
        async.elapse(const Duration(seconds: 119));
        expect(pings, 0);
        async.elapse(const Duration(seconds: 2));
        expect(pings, 1);
        m.stop();
      });
    });

    test('coming back to the foreground returns to 30 s', () {
      fakeAsync((async) {
        var pings = 0;
        final m = AdaptiveSocketManager(send: () => pings++)..start();
        m.onAppStateChange(AppState.background);
        m.onAppStateChange(AppState.foreground);
        expect(m.currentInterval, const Duration(seconds: 30));
        async.elapse(const Duration(seconds: 61));
        expect(pings, 2);
        m.stop();
      });
    });

    test('a state change does not start pings if the manager was never started', () {
      fakeAsync((async) {
        var pings = 0;
        final m = AdaptiveSocketManager(send: () => pings++);
        m.onAppStateChange(AppState.background);
        async.elapse(const Duration(minutes: 10));
        expect(pings, 0);
        expect(m.isRunning, isFalse);
      });
    });

    test('stop cancels the timer', () {
      fakeAsync((async) {
        var pings = 0;
        final m = AdaptiveSocketManager(send: () => pings++)..start();
        m.stop();
        async.elapse(const Duration(minutes: 10));
        expect(pings, 0);
      });
    });

    test('intervals are configurable', () {
      fakeAsync((async) {
        var pings = 0;
        final m = AdaptiveSocketManager(send: () => pings++, foregroundInterval: const Duration(seconds: 20))..start();
        async.elapse(const Duration(seconds: 41));
        expect(pings, 2);
        m.stop();
      });
    });
  });

  group('ReconnectBackoff', () {
    test('without jitter the delays double and then stop at the cap', () {
      final b = ReconnectBackoff(jitter: 0);
      final seconds = [for (var i = 0; i < 6; i++) b.delayFor(i).inMilliseconds / 1000];
      expect(seconds, [1.5, 3.0, 6.0, 12.0, 15.0, 15.0]);
    });

    test('jitter keeps every delay within the configured range', () {
      final b = ReconnectBackoff(jitter: 0.2, random: Random(42));
      for (var i = 0; i < 200; i++) {
        final attempt = i % 6;
        final raw = [1500, 3000, 6000, 12000, 15000, 15000][attempt];
        final d = b.delayFor(attempt).inMilliseconds;
        expect(d, inInclusiveRange(raw * 0.8 - 1, raw * 1.2 + 1));
      }
    });

    test('jitter actually varies the delay', () {
      final b = ReconnectBackoff(jitter: 0.2, random: Random(1));
      final delays = {for (var i = 0; i < 20; i++) b.delayFor(2).inMilliseconds};
      expect(delays.length, greaterThan(5));
    });

    test('a huge attempt number does not overflow', () {
      final b = ReconnectBackoff(jitter: 0);
      expect(b.delayFor(10000), const Duration(seconds: 15));
    });
  });
}
