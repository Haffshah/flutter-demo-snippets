import 'package:local_router_demo/local_first_ai.dart';
import 'package:test/test.dart';

class FakeLocal implements LocalModel {
  FakeLocal({this.answers = const {}, this.throws = false});
  final Map<AiTask, String> answers;
  final bool throws;
  final List<AiTask> calls = [];

  @override
  Future<String?> run(AiTask task, String input) async {
    calls.add(task);
    if (throws) throw Exception('model crashed');
    return answers[task] == null ? null : '${answers[task]}:$input';
  }
}

class FakeCloud implements CloudModel {
  final List<String> inputs = [];

  @override
  Future<String> run(AiTask task, String input) async {
    inputs.add(input);
    return 'cloud:$input';
  }
}

class FakeNet implements Connectivity {
  FakeNet(this.online);
  final bool online;

  @override
  Future<bool> isOnline() async => online;
}

void main() {
  test('simple tasks are answered on the device and never reach the cloud', () async {
    final cloud = FakeCloud();
    final ai = LocalFirstAi(local: FakeLocal(answers: {AiTask.categorize: 'food'}), cloud: cloud, connectivity: FakeNet(true));
    final r = await ai.run(AiTask.categorize, 'pizza');
    expect(r.source, AiSource.local);
    expect(r.text, 'food:pizza');
    expect(cloud.inputs, isEmpty);
    expect(ai.localAnswers, 1);
  });

  test('a simple task the local model cannot answer falls back to the cloud', () async {
    final cloud = FakeCloud();
    final ai = LocalFirstAi(local: FakeLocal(), cloud: cloud, connectivity: FakeNet(true));
    final r = await ai.run(AiTask.translate, 'hola');
    expect(r.source, AiSource.cloud);
    expect(cloud.inputs, ['hola']);
  });

  test('a crashing local model is treated as "cannot answer", not as an error', () async {
    final ai = LocalFirstAi(local: FakeLocal(throws: true), cloud: FakeCloud(), connectivity: FakeNet(true));
    final r = await ai.run(AiTask.spellCheck, 'helo');
    expect(r.source, AiSource.cloud);
  });

  test('complex tasks go to the cloud, with the input tidied by the local model first', () async {
    final cloud = FakeCloud();
    final local = FakeLocal(answers: {AiTask.spellCheck: 'fixed'});
    final ai = LocalFirstAi(local: local, cloud: cloud, connectivity: FakeNet(true));
    final r = await ai.run(AiTask.reason, 'whay is 2+2');
    expect(r.source, AiSource.cloud);
    expect(cloud.inputs, ['fixed:whay is 2+2']);
    expect(local.calls, [AiTask.spellCheck]);
  });

  test('complex tasks still work when there is no local tidy-up available', () async {
    final cloud = FakeCloud();
    final ai = LocalFirstAi(local: FakeLocal(), cloud: cloud, connectivity: FakeNet(true));
    await ai.run(AiTask.reason, 'explain this');
    expect(cloud.inputs, ['explain this']);
  });

  test('offline: simple tasks keep working', () async {
    final ai = LocalFirstAi(local: FakeLocal(answers: {AiTask.validateInput: 'ok'}), cloud: FakeCloud(), connectivity: FakeNet(false));
    final r = await ai.run(AiTask.validateInput, 'abc');
    expect(r.source, AiSource.local);
  });

  test('offline: complex tasks fail clearly instead of hanging', () async {
    final ai = LocalFirstAi(local: FakeLocal(), cloud: FakeCloud(), connectivity: FakeNet(false));
    expect(() => ai.run(AiTask.reason, 'prove it'), throwsA(isA<NeedsNetworkException>()));
  });

  test('counters show how the work was split', () async {
    final ai = LocalFirstAi(local: FakeLocal(answers: {AiTask.categorize: 'x'}), cloud: FakeCloud(), connectivity: FakeNet(true));
    for (var i = 0; i < 4; i++) {
      await ai.run(AiTask.categorize, 'a');
    }
    await ai.run(AiTask.reason, 'b');
    expect(ai.localAnswers, 4);
    expect(ai.cloudAnswers, 1);
  });
}
