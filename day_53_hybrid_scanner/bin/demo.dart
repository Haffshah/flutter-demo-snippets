import 'package:hybrid_scanner_demo/scanner.dart';

class _FakeOcr implements Ocr {
  @override
  Future<String> read(String imagePath) async =>
      'at Swiggy\n₹250 cashback\ncode: SWIGGY250\nvalid till 31/12/2026';
}

class _FakeAi implements AiExtractor {
  @override
  Future<Coupon?> extract(String imagePath, String ocrText, {bool highRes = false}) async =>
      Coupon(merchant: 'Swiggy', amount: 250, code: null, confidence: highRes ? 0.95 : 0.5);
}

class _Online implements Connectivity {
  @override
  Future<bool> isOffline() async => false;
}

Future<void> main() async {
  final scanner = HybridScanner(ocr: _FakeOcr(), ai: _FakeAi(), connectivity: _Online());
  final result = await scanner.scan('screenshot_1.png');
  print(result);
  print('AI calls: ${scanner.aiCalls} (weak first pass, then one high-res retry)');
  final again = await scanner.scan('screenshot_1.png');
  print('Second scan served from cache, AI calls still ${scanner.aiCalls}: ${identical(result, again)}');
}
