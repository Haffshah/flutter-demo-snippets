import 'battery_api.g.dart';

/// Thin wrapper so the rest of the app never touches the generated API directly.
class BatteryService {
  BatteryService({BatteryApi? api}) : _api = api ?? BatteryApi();

  final BatteryApi _api;

  Future<String> describe() async {
    final info = await _api.getBatteryInfo();
    return '${info.level}%${info.isCharging ? ' (charging)' : ''}';
  }
}
