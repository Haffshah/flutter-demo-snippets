// Fails (exit code 1) when presentation code breaks the boundaries from AGENTS.md.
//
//   dart run tool/check_boundaries.dart [project_root]
//
// Rules checked:
//   1. Files under a `presentation` folder must not import HTTP packages or `data` code.
//   2. Files under a `domain` folder must not import Flutter, HTTP packages or `data` code.
import 'dart:io';

const _http = ['package:http/', 'package:dio/', 'dart:io'];

class Violation {
  Violation(this.file, this.line, this.rule);
  final String file;
  final int line;
  final String rule;
  @override
  String toString() => '$file:$line  $rule';
}

List<Violation> check(Directory root) {
  final violations = <Violation>[];
  final libDir = Directory('${root.path}/lib');
  if (!libDir.existsSync()) return violations;

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll('\\', '/');
    final inPresentation = path.contains('/presentation/');
    final inDomain = path.contains('/domain/');
    if (!inPresentation && !inDomain) continue;

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('import ')) continue;
      final layer = inPresentation ? 'presentation' : 'domain';

      if (_http.any(line.contains)) {
        violations.add(Violation(path, i + 1, '$layer must not import HTTP/IO: $line'));
      }
      if (RegExp(r"/data/").hasMatch(line)) {
        violations.add(Violation(path, i + 1, '$layer must not import data code: $line'));
      }
      if (inDomain && line.contains('package:flutter/')) {
        violations.add(Violation(path, i + 1, 'domain must not import Flutter: $line'));
      }
    }
  }
  return violations;
}

void main(List<String> args) {
  final root = Directory(args.isEmpty ? '.' : args.first);
  final found = check(root);
  if (found.isEmpty) {
    print('Boundaries OK');
    return;
  }
  for (final v in found) {
    stderr.writeln(v);
  }
  stderr.writeln('${found.length} boundary violation(s)');
  exit(1);
}
