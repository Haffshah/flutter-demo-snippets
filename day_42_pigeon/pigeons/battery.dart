// The single source of truth. Edit this file, then re-run:
//   dart run pigeon --input pigeons/battery.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/battery_api.g.dart',
  dartTestOut: 'test/test_api.g.dart',
  dartPackageName: 'pigeon_demo',
  swiftOut: 'ios/Classes/BatteryApi.g.swift',
  kotlinOut: 'android/src/main/kotlin/dev/demo/BatteryApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'dev.demo'),
))
class BatteryInfo {
  BatteryInfo({required this.level, required this.isCharging});
  int level; // 0..100
  bool isCharging;
}

@HostApi(dartHostTestHandler: 'TestBatteryApi')
abstract class BatteryApi {
  /// Returns the current battery level, 0..100.
  int getBatteryLevel();

  BatteryInfo getBatteryInfo();
}
