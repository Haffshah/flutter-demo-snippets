import 'package:math_solver_demo/math_router.dart';
import 'package:math_solver_demo/symbolic_parser.dart';
import 'package:test/test.dart';

class _FakeLlm implements LlmExplainer {
  final List<String> asked = [];

  @override
  Future<SolverResult> explain(String problem) async {
    asked.add(problem);
    return const SolverResult(isSolved: true, answer: 'explained by the model', source: 'llm');
  }
}

void main() {
  group('SymbolicParser', () {
    test('the carousel example: 2x + 5 = 15 -> isolate, then divide', () {
      final r = SymbolicParser.solve('2x + 5 = 15');
      expect(r.isSolved, isTrue);
      expect(r.answer, 'x = 5');
      expect(r.steps, ['Isolate: 2x = 10', 'Divide by 2: x = 5']);
    });

    test('arithmetic with precedence and parentheses', () {
      expect(SymbolicParser.solve('3 + 4 * 2').answer, '11');
      expect(SymbolicParser.solve('(3 + 4) * 2').answer, '14');
      expect(SymbolicParser.solve('2^3 - 1').answer, '7');
      expect(SymbolicParser.solve('10 / 4').answer, '2.5');
    });

    test('linear equations with x on both sides', () {
      expect(SymbolicParser.solve('3x - 4 = x + 10').answer, 'x = 7');
      expect(SymbolicParser.solve('x = 9').answer, 'x = 9');
    });

    test('quadratics with two real roots', () {
      final r = SymbolicParser.solve('x^2 - 5x + 6 = 0');
      expect(r.answer, 'x = 2 or x = 3');
    });

    test('quadratic with one root and with none', () {
      expect(SymbolicParser.solve('x^2 + 2x + 1 = 0').answer, 'x = -1');
      final none = SymbolicParser.solve('x^2 + 1 = 0');
      expect(none.isSolved, isTrue);
      expect(none.answer, 'no real solution');
    });

    test('implicit multiplication and unary minus', () {
      expect(SymbolicParser.solve('2(x + 1) = 10').answer, 'x = 4');
      expect(SymbolicParser.solve('-x = 3').answer, 'x = -3');
    });

    test('things it cannot solve are reported as unsolved, not guessed', () {
      expect(SymbolicParser.solve('prove that sqrt(2) is irrational').isSolved, isFalse);
      expect(SymbolicParser.solve('x^3 = 8').isSolved, isFalse);
      expect(SymbolicParser.solve('2x + 1 = 3y').isSolved, isFalse);
      expect(SymbolicParser.solve('').isSolved, isFalse);
      expect(SymbolicParser.solve('1 / 0 = x').isSolved, isFalse);
    });
  });

  group('MathRouter', () {
    test('solvable problems never reach the LLM', () async {
      final llm = _FakeLlm();
      final events = <String>[];
      final router = MathRouter(llm: llm, analytics: (e, {required ms}) => events.add(e));
      final r = await router.solve('2x + 5 = 15');
      expect(r.answer, 'x = 5');
      expect(r.source, 'local');
      expect(llm.asked, isEmpty);
      expect(events, ['local_solve']);
    });

    test('unsolved problems escalate to the LLM', () async {
      final llm = _FakeLlm();
      final events = <String>[];
      final router = MathRouter(llm: llm, analytics: (e, {required ms}) => events.add(e));
      final r = await router.solve('prove the sum of two even numbers is even');
      expect(r.source, 'llm');
      expect(llm.asked, ['prove the sum of two even numbers is even']);
      expect(events, ['llm_escalation']);
    });
  });
}
