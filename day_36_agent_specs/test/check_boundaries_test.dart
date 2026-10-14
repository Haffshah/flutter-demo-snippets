import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_boundaries.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('boundaries_'));
  tearDown(() => root.deleteSync(recursive: true));

  void write(String path, String content) {
    final f = File('${root.path}/$path')..createSync(recursive: true);
    f.writeAsStringSync(content);
  }

  test('clean project passes', () {
    write('lib/features/a/presentation/page.dart', "import 'package:flutter/material.dart';\n");
    write('lib/features/a/domain/repo.dart', 'abstract class Repo {}\n');
    expect(check(root), isEmpty);
  });

  test('widget importing http is flagged', () {
    write('lib/features/a/presentation/page.dart', "import 'package:http/http.dart' as http;\n");
    final v = check(root);
    expect(v, hasLength(1));
    expect(v.single.rule, contains('presentation must not import HTTP'));
  });

  test('presentation importing data code is flagged', () {
    write('lib/features/a/presentation/page.dart', "import '../data/api.dart';\n");
    expect(check(root), hasLength(1));
  });

  test('domain importing flutter is flagged', () {
    write('lib/features/a/domain/entity.dart', "import 'package:flutter/foundation.dart';\n");
    expect(check(root).single.rule, contains('domain must not import Flutter'));
  });

  test('data layer is allowed to use http', () {
    write('lib/features/a/data/api.dart', "import 'package:http/http.dart' as http;\n");
    expect(check(root), isEmpty);
  });
}
