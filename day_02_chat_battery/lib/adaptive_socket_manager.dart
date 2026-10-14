import 'dart:async';
import 'dart:math';

/// Foreground or background. In Flutter, map `AppLifecycleState.paused` to [background] and the rest to [foreground].
enum AppState { foreground, background }

/// The class from slide 5: stretch the heartbeat interval when the app is in the background,
/// so the radio and CPU wake up less often.
///
/// The carousel's code uses 30 s in the foreground and 120 s in the background. (Slide 4's text says 20 s,
/// so both are configurable.) [send] is whatever sends a ping on your socket.
class AdaptiveSocketManager {
  AdaptiveSocketManager({
    required this.send,
    this.foregroundInterval = const Duration(seconds: 30),
    this.backgroundInterval = const Duration(seconds: 120),
  }) : _interval = foregroundInterval;

  final void Function() send;
  final Duration foregroundInterval;
  final Duration backgroundInterval;

  Timer? _pingTimer;
  Duration _interval;

  Duration get currentInterval => _interval;
  bool get isRunning => _pingTimer?.isActive ?? false;

  void start() => restartPingTimer();

  void stop() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void onAppStateChange(AppState state) {
    _interval = state == AppState.background ? backgroundInterval : foregroundInterval;
    if (isRunning) restartPingTimer(); // only re-arm a timer that was running
  }

  void restartPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_interval, (_) => send());
  }
}

/// Exponential backoff with jitter for reconnecting, instead of retrying immediately in a loop.
///
/// Delays double from [base] up to [max]. Jitter spreads retries so many clients don't reconnect at once.
/// The carousel's example sequence is roughly 1.5 s, 3 s, 7 s, 15 s. The numbers here are illustrative.
class ReconnectBackoff {
  ReconnectBackoff({
    this.base = const Duration(milliseconds: 1500),
    this.max = const Duration(seconds: 15),
    this.jitter = 0.2,
    Random? random,
  }) : _random = random ?? Random();

  final Duration base;
  final Duration max;

  /// 0.2 means each delay varies by up to plus or minus 20%.
  final double jitter;
  final Random _random;

  /// Delay before reconnect attempt number [attempt] (0 is the first retry).
  Duration delayFor(int attempt) {
    final factor = pow(2, attempt.clamp(0, 30)).toDouble();
    final raw = min(base.inMilliseconds * factor, max.inMilliseconds.toDouble());
    final spread = (_random.nextDouble() * 2 - 1) * jitter; // -jitter .. +jitter
    return Duration(milliseconds: (raw * (1 + spread)).round());
  }
}
