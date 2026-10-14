import 'package:flutter_test/flutter_test.dart';
import 'package:pigeon_demo/battery_api.g.dart';
import 'package:pigeon_demo/battery_service.dart';

import 'test_api.g.dart';

/// Stands in for the native side. The generated TestBatteryApi routes calls here,
/// so the Dart code is exercised with real types and no string channel names.
class _FakeHost implements TestBatteryApi {
  _FakeHost(this.level, this.charging);
  final int level;
  final bool charging;

  @override
  int getBatteryLevel() => level;

  @override
  BatteryInfo getBatteryInfo() => BatteryInfo(level: level, isCharging: charging);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('describe() formats level and charging state', () async {
    TestBatteryApi.setUp(_FakeHost(80, true));
    expect(await BatteryService().describe(), '80% (charging)');
    TestBatteryApi.setUp(_FakeHost(15, false));
    expect(await BatteryService().describe(), '15%');
  });

  test('getBatteryLevel returns an int from the host', () async {
    TestBatteryApi.setUp(_FakeHost(42, false));
    expect(await BatteryApi().getBatteryLevel(), 42);
  });
}
