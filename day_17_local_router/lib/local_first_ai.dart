/// The kinds of work the carousel splits into "small, do it on the device" and "needs a big model".
enum AiTask {
  // Simple: the carousel lists input validation, spelling correction, categorization and raw translation.
  validateInput,
  spellCheck,
  categorize,
  translate,

  // Complex: reasoning that a small on-device model can't be trusted with.
  reason;

  bool get isSimple => this != AiTask.reason;
}

enum AiSource { local, cloud }

class AiResult {
  const AiResult(this.text, this.source);
  final String text;
  final AiSource source;
}

/// An on-device model (for example a small quantized language model). Return null when it cannot
/// produce a usable answer, so the router may fall back to the cloud.
abstract class LocalModel {
  Future<String?> run(AiTask task, String input);
}

/// A cloud model behind your own backend. Keep API keys on the server, never in the app.
abstract class CloudModel {
  Future<String> run(AiTask task, String input);
}

abstract class Connectivity {
  Future<bool> isOnline();
}

/// Thrown when the task needs the cloud and there is no connection.
class NeedsNetworkException implements Exception {
  const NeedsNetworkException(this.task);
  final AiTask task;
  @override
  String toString() => 'Task "${task.name}" needs the network, and the device is offline.';
}

/// Local first:
///   * simple tasks run on the device. Only if the local model can't answer do they go to the cloud.
///   * complex tasks go to the cloud, after the input is tidied by the local model when one is available
///     (the carousel's "intelligent prompt filtering").
///   * offline: simple tasks still work, complex ones fail clearly instead of hanging.
class LocalFirstAi {
  LocalFirstAi({required this.local, required this.cloud, required this.connectivity});

  final LocalModel local;
  final CloudModel cloud;
  final Connectivity connectivity;

  int localAnswers = 0;
  int cloudAnswers = 0;

  Future<AiResult> run(AiTask task, String input) async {
    if (task.isSimple) {
      final answer = await _tryLocal(task, input);
      if (answer != null) {
        localAnswers++;
        return AiResult(answer, AiSource.local);
      }
      return _cloud(task, input); // the local model couldn't do it
    }

    final tidied = await _tryLocal(AiTask.spellCheck, input) ?? input;
    return _cloud(task, tidied);
  }

  Future<String?> _tryLocal(AiTask task, String input) async {
    try {
      return await local.run(task, input);
    } catch (_) {
      return null; // a broken local model must not break the feature
    }
  }

  Future<AiResult> _cloud(AiTask task, String input) async {
    if (!await connectivity.isOnline()) throw NeedsNetworkException(task);
    final text = await cloud.run(task, input);
    cloudAnswers++;
    return AiResult(text, AiSource.cloud);
  }
}
