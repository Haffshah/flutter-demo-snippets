/// A small, generic version of a layered "scan a screenshot" pipeline.
///
/// Layers (top to bottom):
///   0. cache      - same image twice costs nothing the second time
///   1. OCR        - on-device text recognition
///   2. local parse- free, deterministic baseline that ALWAYS runs
///   2b. offline   - no connection: return the local parse, skip the AI
///   3. AI + fusion- online: AI result wins per field, local fills the gaps
///   4. escalation - weak fused result: retry once at high resolution, keep the better one
///   5. fallback   - AI failed: return the local parse
///
/// OCR, AI and connectivity are interfaces, so the demo runs with fakes.
library;

class Coupon {
  const Coupon({
    this.merchant,
    this.amount,
    this.code,
    this.expiry,
    this.confidence = 0,
    this.isLocal = false,
  });

  final String? merchant;
  final double? amount;
  final String? code;
  final DateTime? expiry;

  /// 0..1. For AI results this is what the extractor reports.
  final double confidence;

  /// True when the result came from the local parse only.
  final bool isLocal;

  int get filledFields =>
      [merchant, amount, code, expiry].where((v) => v != null).length;

  Coupon copyWith({double? confidence, bool? isLocal}) => Coupon(
        merchant: merchant,
        amount: amount,
        code: code,
        expiry: expiry,
        confidence: confidence ?? this.confidence,
        isLocal: isLocal ?? this.isLocal,
      );

  @override
  String toString() =>
      'Coupon(merchant: $merchant, amount: $amount, code: $code, expiry: $expiry, '
      'confidence: ${confidence.toStringAsFixed(2)}, isLocal: $isLocal)';
}

abstract class Ocr {
  Future<String> read(String imagePath);
}

abstract class AiExtractor {
  /// Returns null when the model produced nothing usable. May throw.
  Future<Coupon?> extract(String imagePath, String ocrText, {bool highRes = false});
}

abstract class Connectivity {
  Future<bool> isOffline();
}

/// Layer 2: cheap regex baseline. Illustrative patterns, not production-grade.
class LocalParser {
  static final _amount = RegExp(r'(?:₹|Rs\.?\s?)\s?(\d+(?:\.\d+)?)');
  static final _code = RegExp(r'(?:code|coupon)[:\s]+([A-Z0-9]{4,})', caseSensitive: false);
  static final _expiry = RegExp(r'(?:valid till|expires?)[:\s]+(\d{2})/(\d{2})/(\d{4})', caseSensitive: false);
  static final _merchant = RegExp(r'^(?:at|from)\s+([A-Za-z][A-Za-z ]{2,})$', caseSensitive: false, multiLine: true);

  Coupon parse(String text) {
    final amount = _amount.firstMatch(text);
    final code = _code.firstMatch(text);
    final expiry = _expiry.firstMatch(text);
    final merchant = _merchant.firstMatch(text);

    final coupon = Coupon(
      merchant: merchant?.group(1)?.trim(),
      amount: amount == null ? null : double.parse(amount.group(1)!),
      code: code?.group(1)?.toUpperCase(),
      expiry: expiry == null
          ? null
          : DateTime(int.parse(expiry.group(3)!), int.parse(expiry.group(2)!), int.parse(expiry.group(1)!)),
      isLocal: true,
    );
    // Local confidence is capped: regex alone should never look as sure as a good AI pass.
    return coupon.copyWith(confidence: coupon.filledFields / 4 * 0.6);
  }
}

class HybridScanner {
  HybridScanner({
    required this.ocr,
    required this.ai,
    required this.connectivity,
    LocalParser? parser,
    this.escalationThreshold = 0.85,
  }) : _parser = parser ?? LocalParser();

  final Ocr ocr;
  final AiExtractor ai;
  final Connectivity connectivity;
  final double escalationThreshold;
  final LocalParser _parser;

  final Map<String, Coupon> _cache = {};

  /// How many AI calls were made. Handy for tests and for printing in the demo.
  int aiCalls = 0;

  Future<Coupon> scan(String imagePath) async {
    // Layer 0: cache (the path stands in for an image hash here).
    final cached = _cache[imagePath];
    if (cached != null) return cached;

    // Layer 1 + 2: OCR, then the local baseline that always runs.
    final text = await ocr.read(imagePath);
    final local = _parser.parse(text);

    // Layer 2b: offline short-circuit.
    if (await connectivity.isOffline()) {
      return _remember(imagePath, local);
    }

    try {
      // Layer 3: AI + fusion.
      aiCalls++;
      final first = await ai.extract(imagePath, text);
      if (first == null || first.merchant == null) {
        return _remember(imagePath, local); // nothing usable: local fallback
      }
      var fused = fuse(first, local);

      // Layer 4: confidence-gated escalation. One retry, keep the stronger result.
      if (fused.confidence < escalationThreshold) {
        try {
          aiCalls++;
          final retry = await ai.extract(imagePath, text, highRes: true);
          if (retry != null) {
            final fusedRetry = fuse(retry, local);
            if (fusedRetry.confidence >= fused.confidence) fused = fusedRetry;
          }
        } catch (_) {
          // Keep the first-pass result.
        }
      }
      return _remember(imagePath, fused);
    } catch (_) {
      // Layer 5: AI failed. The local parse is the safety net.
      return _remember(imagePath, local);
    }
  }

  /// AI wins per field; local fills what the AI left empty.
  /// Confidence here is illustrative: the average of the AI's own confidence
  /// and how many of the 4 fields ended up filled.
  Coupon fuse(Coupon ai, Coupon local) {
    final merged = Coupon(
      merchant: ai.merchant ?? local.merchant,
      amount: ai.amount ?? local.amount,
      code: ai.code ?? local.code,
      expiry: ai.expiry ?? local.expiry,
    );
    final completeness = merged.filledFields / 4;
    return Coupon(
      merchant: merged.merchant,
      amount: merged.amount,
      code: merged.code,
      expiry: merged.expiry,
      confidence: (ai.confidence + completeness) / 2,
    );
  }

  Coupon _remember(String key, Coupon value) {
    _cache[key] = value;
    return value;
  }
}
