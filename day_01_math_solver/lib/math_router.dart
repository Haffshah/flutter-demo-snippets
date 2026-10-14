import 'symbolic_parser.dart';

/// Layer 3: the cloud model. Implement with your own backend or SDK. Never ship a paid API key in the app.
abstract class LlmExplainer {
  Future<SolverResult> explain(String problem);
}

typedef AnalyticsLog = void Function(String event, {required int ms});

/// The routing logic from the carousel:
///   1. try the local symbolic parser (offline, no cost)
///   2. only if it can't solve the problem, ask the LLM
class MathRouter {
  MathRouter({required this.llm, AnalyticsLog? analytics, Stopwatch Function()? stopwatch})
      : _analytics = analytics ?? ((_, {required ms}) {}),
        _stopwatch = stopwatch ?? Stopwatch.new;

  final LlmExplainer llm;
  final AnalyticsLog _analytics;
  final Stopwatch Function() _stopwatch;

  Future<SolverResult> solve(String problem) async {
    final watch = _stopwatch()..start();
    final local = SymbolicParser.solve(problem);
    if (local.isSolved) {
      _analytics('local_solve', ms: watch.elapsedMilliseconds);
      return local;
    }
    final remote = await llm.explain(problem);
    _analytics('llm_escalation', ms: watch.elapsedMilliseconds);
    return remote;
  }
}
