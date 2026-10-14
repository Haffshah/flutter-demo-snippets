/// Tip 1 from the carousel: adjust how often you ask for location based on how fast the device moves.
class PollingPolicy {
  const PollingPolicy({required this.distanceFilterMeters, required this.pollInterval});

  /// Ask the location API to report only after the device moved at least this far.
  final double distanceFilterMeters;

  /// How often to ask at all.
  final Duration pollInterval;

  /// The tiers and numbers below are ILLUSTRATIVE. The carousel gives the idea (poll less when still
  /// or very fast), not these values. Tune them for your own app and test on real devices.
  static PollingPolicy forSpeed(double metersPerSecond) {
    if (metersPerSecond < 0.5) {
      return const PollingPolicy(distanceFilterMeters: 100, pollInterval: Duration(seconds: 60)); // still
    }
    if (metersPerSecond < 2) {
      return const PollingPolicy(distanceFilterMeters: 10, pollInterval: Duration(seconds: 5)); // walking
    }
    if (metersPerSecond < 15) {
      return const PollingPolicy(distanceFilterMeters: 25, pollInterval: Duration(seconds: 10)); // city driving
    }
    return const PollingPolicy(distanceFilterMeters: 100, pollInterval: Duration(seconds: 20)); // fast
  }
}
