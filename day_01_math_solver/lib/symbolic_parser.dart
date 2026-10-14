import 'dart:math' as math;

/// Result of trying to solve a problem on the device.
class SolverResult {
  const SolverResult({required this.isSolved, this.answer, this.steps = const [], this.source = 'local'});

  final bool isSolved;
  final String? answer;
  final List<String> steps;

  /// 'local' or 'llm'.
  final String source;

  static const unsolved = SolverResult(isSolved: false);
}

/// Layer 2 of the carousel: a Dart-native parser that solves arithmetic, linear equations and
/// quadratics without any network. Input is plain text such as `2x + 5 = 15`, not LaTeX.
class SymbolicParser {
  static SolverResult solve(String input) {
    try {
      final text = input.replaceAll(' ', '');
      if (text.isEmpty) return SolverResult.unsolved;
      final parts = text.split('=');
      if (parts.length == 1) return _arithmetic(text);
      if (parts.length == 2) return _equation(parts[0], parts[1]);
      return SolverResult.unsolved;
    } on FormatException {
      return SolverResult.unsolved; // not something the local parser understands
    }
  }

  static SolverResult _arithmetic(String text) {
    final p = _Poly.parse(text);
    if (p.degree != 0) return SolverResult.unsolved; // it has an x in it: not plain arithmetic
    return SolverResult(isSolved: true, answer: _fmt(p.c[0]), steps: ['$text = ${_fmt(p.c[0])}']);
  }

  static SolverResult _equation(String left, String right) {
    final l = _Poly.parse(left);
    final r = _Poly.parse(right);
    final p = l.minus(r); // everything on the left: p(x) = 0
    switch (p.degree) {
      case 1:
        return _linear(l, r, p);
      case 2:
        return _quadratic(p);
      default:
        return SolverResult.unsolved;
    }
  }

  /// a*x + b = c  ->  isolate, then divide.
  static SolverResult _linear(_Poly l, _Poly r, _Poly p) {
    final a = p.c[1];
    final b = p.c[0];
    final steps = <String>[];
    if (l.degree == 1 && r.degree == 0 && l.c[0] != 0) {
      steps.add('Isolate: ${_term(l.c[1])} = ${_fmt(r.c[0] - l.c[0])}');
    }
    final x = -b / a;
    if (a != 1) steps.add('Divide by ${_fmt(a)}: x = ${_fmt(x)}');
    if (steps.isEmpty) steps.add('x = ${_fmt(x)}');
    return SolverResult(isSolved: true, answer: 'x = ${_fmt(x)}', steps: steps);
  }

  /// a*x^2 + b*x + c = 0 using the quadratic formula. Real roots only.
  static SolverResult _quadratic(_Poly p) {
    final a = p.c[2], b = p.c[1], c = p.c[0];
    final disc = b * b - 4 * a * c;
    final steps = ['Discriminant: b^2 - 4ac = ${_fmt(disc)}'];
    if (disc < 0) {
      steps.add('Negative discriminant: no real roots');
      return SolverResult(isSolved: true, answer: 'no real solution', steps: steps);
    }
    final root = math.sqrt(disc);
    final x1 = (-b + root) / (2 * a);
    final x2 = (-b - root) / (2 * a);
    if (disc == 0) {
      steps.add('One root: x = ${_fmt(x1)}');
      return SolverResult(isSolved: true, answer: 'x = ${_fmt(x1)}', steps: steps);
    }
    final lo = math.min(x1, x2), hi = math.max(x1, x2);
    steps.add('Two roots: x = ${_fmt(lo)} or x = ${_fmt(hi)}');
    return SolverResult(isSolved: true, answer: 'x = ${_fmt(lo)} or x = ${_fmt(hi)}', steps: steps);
  }

  static String _term(double a) => a == 1 ? 'x' : '${_fmt(a)}x';

  static String _fmt(double v) {
    final rounded = double.parse(v.toStringAsFixed(6));
    return rounded == rounded.roundToDouble() ? rounded.toInt().toString() : rounded.toString();
  }
}

/// A polynomial in x with up to degree 2: c[0] + c[1] x + c[2] x^2.
class _Poly {
  _Poly(this.c);

  final List<double> c; // length 3

  static _Poly constant(double v) => _Poly([v, 0, 0]);
  static _Poly get x => _Poly([0, 1, 0]);

  int get degree {
    for (var i = 2; i >= 0; i--) {
      if (c[i].abs() > 1e-12) return i;
    }
    return 0;
  }

  _Poly plus(_Poly o) => _Poly([for (var i = 0; i < 3; i++) c[i] + o.c[i]]);
  _Poly minus(_Poly o) => _Poly([for (var i = 0; i < 3; i++) c[i] - o.c[i]]);
  _Poly negate() => _Poly([for (final v in c) -v]);

  _Poly times(_Poly o) {
    final out = [0.0, 0.0, 0.0];
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        if (c[i] == 0 || o.c[j] == 0) continue;
        if (i + j > 2) throw const FormatException('degree above 2');
        out[i + j] += c[i] * o.c[j];
      }
    }
    return _Poly(out);
  }

  _Poly dividedBy(_Poly o) {
    if (o.degree != 0 || o.c[0] == 0) throw const FormatException('can only divide by a non-zero number');
    return _Poly([for (final v in c) v / o.c[0]]);
  }

  _Poly pow(int n) {
    var out = _Poly.constant(1);
    for (var i = 0; i < n; i++) {
      out = out.times(this);
    }
    return out;
  }

  static _Poly parse(String s) {
    final parser = _Parser(s);
    final p = parser.expression();
    if (!parser.atEnd) throw FormatException('unexpected "${parser.rest}"');
    return p;
  }
}

/// Recursive-descent parser: + - * / ^, parentheses, unary minus, and implicit multiplication (2x, 3(x+1)).
class _Parser {
  _Parser(this._s);

  final String _s;
  int _i = 0;

  bool get atEnd => _i >= _s.length;
  String get rest => _s.substring(_i);
  String? get _peek => atEnd ? null : _s[_i];

  _Poly expression() {
    var left = term();
    while (_peek == '+' || _peek == '-') {
      final op = _s[_i++];
      final right = term();
      left = op == '+' ? left.plus(right) : left.minus(right);
    }
    return left;
  }

  _Poly term() {
    var left = power();
    while (true) {
      final ch = _peek;
      if (ch == '*' || ch == '/') {
        _i++;
        final right = power();
        left = ch == '*' ? left.times(right) : left.dividedBy(right);
      } else if (ch != null && (ch == 'x' || ch == '(' || _isDigit(ch) || ch == '.')) {
        left = left.times(power()); // implicit multiplication
      } else {
        return left;
      }
    }
  }

  _Poly power() {
    final base = unary();
    if (_peek == '^') {
      _i++;
      final start = _i;
      while (!atEnd && _isDigit(_s[_i])) {
        _i++;
      }
      if (start == _i) throw const FormatException('exponent must be a whole number');
      return base.pow(int.parse(_s.substring(start, _i)));
    }
    return base;
  }

  _Poly unary() {
    if (_peek == '-') {
      _i++;
      return unary().negate();
    }
    if (_peek == '+') {
      _i++;
      return unary();
    }
    return atom();
  }

  _Poly atom() {
    final ch = _peek;
    if (ch == null) throw const FormatException('unexpected end');
    if (ch == '(') {
      _i++;
      final inner = expression();
      if (_peek != ')') throw const FormatException('missing )');
      _i++;
      return inner;
    }
    if (ch == 'x') {
      _i++;
      return _Poly.x;
    }
    if (_isDigit(ch) || ch == '.') {
      final start = _i;
      while (!atEnd && (_isDigit(_s[_i]) || _s[_i] == '.')) {
        _i++;
      }
      return _Poly.constant(double.parse(_s.substring(start, _i)));
    }
    throw FormatException('unexpected "$ch"');
  }

  bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
}
