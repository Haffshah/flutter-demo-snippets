import 'package:hybrid_scanner_demo/scanner.dart';
import 'package:test/test.dart';

class FakeOcr implements Ocr {
  int reads = 0;
  @override
  Future<String> read(String imagePath) async {
    reads++;
    return 'at Swiggy\n₹250 cashback\ncode: SWIGGY250\nvalid till 31/12/2026';
  }
}

class FakeAi implements AiExtractor {
  FakeAi(this.responder);
  final Future<Coupon?> Function(bool highRes) responder;
  @override
  Future<Coupon?> extract(String imagePath, String ocrText, {bool highRes = false}) =>
      responder(highRes);
}

class FakeNet implements Connectivity {
  FakeNet({this.offline = false});
  final bool offline;
  @override
  Future<bool> isOffline() async => offline;
}

HybridScanner build({required FakeAi ai, bool offline = false, FakeOcr? ocr}) =>
    HybridScanner(ocr: ocr ?? FakeOcr(), ai: ai, connectivity: FakeNet(offline: offline));

void main() {
  test('local parser reads amount, code, expiry and merchant', () {
    final c = LocalParser().parse('at Swiggy\n₹250 cashback\ncode: SWIGGY250\nvalid till 31/12/2026');
    expect(c.merchant, 'Swiggy');
    expect(c.amount, 250);
    expect(c.code, 'SWIGGY250');
    expect(c.expiry, DateTime(2026, 12, 31));
    expect(c.isLocal, isTrue);
  });

  test('offline: returns the local parse and never calls the AI', () async {
    final s = build(ai: FakeAi((_) async => fail('AI must not be called')), offline: true);
    final r = await s.scan('a.png');
    expect(r.isLocal, isTrue);
    expect(r.code, 'SWIGGY250');
    expect(s.aiCalls, 0);
  });

  test('fusion: AI wins per field, local fills the gaps', () async {
    final s = build(
      ai: FakeAi((_) async => const Coupon(merchant: 'Swiggy Instamart', amount: 300, confidence: 0.95)),
    );
    final r = await s.scan('a.png');
    expect(r.merchant, 'Swiggy Instamart'); // AI wins
    expect(r.amount, 300); // AI wins
    expect(r.code, 'SWIGGY250'); // filled by local
    expect(r.expiry, DateTime(2026, 12, 31)); // filled by local
    expect(r.isLocal, isFalse);
  });

  test('confident result: no escalation', () async {
    final s = build(
      ai: FakeAi((_) async => const Coupon(merchant: 'Swiggy', amount: 250, confidence: 0.95)),
    );
    await s.scan('a.png');
    expect(s.aiCalls, 1);
  });

  test('low confidence: one high-res retry, better result kept', () async {
    final s = build(
      ai: FakeAi((hi) async => Coupon(merchant: 'Swiggy', amount: 250, confidence: hi ? 0.95 : 0.5)),
    );
    final r = await s.scan('a.png');
    expect(s.aiCalls, 2);
    expect(r.confidence, greaterThanOrEqualTo(0.85));
  });

  test('low confidence: worse retry is ignored', () async {
    final s = build(
      ai: FakeAi((hi) async => Coupon(merchant: 'Swiggy', amount: 250, confidence: hi ? 0.2 : 0.5)),
    );
    final r = await s.scan('a.png');
    expect(s.aiCalls, 2);
    expect(r.confidence, closeTo((0.5 + 1.0) / 2, 1e-9));
  });

  test('AI failure: falls back to the local parse', () async {
    final s = build(ai: FakeAi((_) async => throw Exception('network')));
    final r = await s.scan('a.png');
    expect(r.isLocal, isTrue);
    expect(r.amount, 250);
  });

  test('AI returns nothing usable: falls back to the local parse', () async {
    final s = build(ai: FakeAi((_) async => null));
    final r = await s.scan('a.png');
    expect(r.isLocal, isTrue);
  });

  test('same image twice: OCR and AI run once', () async {
    final ocr = FakeOcr();
    final s = build(
      ai: FakeAi((_) async => const Coupon(merchant: 'Swiggy', amount: 250, confidence: 0.95)),
      ocr: ocr,
    );
    await s.scan('a.png');
    await s.scan('a.png');
    expect(ocr.reads, 1);
    expect(s.aiCalls, 1);
  });
}
