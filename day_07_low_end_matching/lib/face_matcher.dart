import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

/// Cosine similarity of two embeddings: 1 means same direction, 0 unrelated, -1 opposite.
/// A zero vector gives 0 instead of NaN.
double cosineSimilarity(Float32List a, Float32List b) {
  if (a.length != b.length) throw ArgumentError('embeddings must have the same length');
  double dot = 0, na = 0, nb = 0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  if (na == 0 || nb == 0) return 0;
  return dot / (math.sqrt(na) * math.sqrt(nb));
}

class MatchResult {
  const MatchResult(this.id, this.score);
  final String id;
  final double score;
}

/// Compares an embedding with enrolled templates and returns the best one, if it is similar enough.
class FaceMatcher {
  FaceMatcher(this.templates, {this.threshold = 0.8});

  final Map<String, Float32List> templates;

  /// Minimum cosine similarity to count as a match. Pick it by testing on your own data.
  final double threshold;

  MatchResult? match(Float32List embedding) {
    MatchResult? best;
    templates.forEach((id, t) {
      final s = cosineSimilarity(embedding, t);
      if (best == null || s > best!.score) best = MatchResult(id, s);
    });
    return best != null && best!.score >= threshold ? best : null;
  }

  /// Slide 3: `Isolate.run(() => ...)` keeps the heavy part off the UI thread.
  ///
  /// Note: Dart copies the data it sends to an isolate. A small gallery is fine. For a large one, keep a
  /// long-lived worker isolate that holds the templates so they are not copied on every call.
  Future<MatchResult?> matchOffMainThread(Float32List embedding) {
    final templates = this.templates;
    final threshold = this.threshold;
    return Isolate.run(() => FaceMatcher(templates, threshold: threshold).match(embedding));
  }
}

/// A STAND-IN for the TFLite model: average-pools the frame into [size] values and normalizes them.
/// Real embeddings come from a neural network. This only lets the rest of the pipeline run and be tested.
Float32List fakeEmbedding(Uint8List rgba, {int size = 16}) {
  final out = Float32List(size);
  final chunk = math.max(1, rgba.length ~/ size);
  for (var i = 0; i < size; i++) {
    var sum = 0;
    final start = i * chunk;
    final end = math.min(rgba.length, start + chunk);
    for (var j = start; j < end; j++) {
      sum += rgba[j];
    }
    out[i] = end > start ? sum / (end - start) : 0;
  }
  final norm = math.sqrt(out.fold<double>(0, (a, v) => a + v * v));
  if (norm > 0) {
    for (var i = 0; i < size; i++) {
      out[i] /= norm;
    }
  }
  return out;
}
