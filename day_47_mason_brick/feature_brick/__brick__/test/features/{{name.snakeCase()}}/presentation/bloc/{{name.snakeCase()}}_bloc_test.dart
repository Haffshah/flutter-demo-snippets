import 'package:flutter_test/flutter_test.dart';

// Update 'your_app' to your package name.
import 'package:your_app/features/{{name.snakeCase()}}/domain/repositories/{{name.snakeCase()}}_repository.dart';
import 'package:your_app/features/{{name.snakeCase()}}/presentation/bloc/{{name.snakeCase()}}_bloc.dart';

class _FakeRepository implements {{name.pascalCase()}}Repository {
  _FakeRepository({this.fail = false});
  final bool fail;

  @override
  Future<String> load() async {
    if (fail) throw Exception('boom');
    return 'data';
  }
}

void main() {
  test('emits loading then loaded', () async {
    final bloc = {{name.pascalCase()}}Bloc(_FakeRepository());
    final future = expectLater(
      bloc.stream,
      emitsInOrder([isA<{{name.pascalCase()}}Loading>(), isA<{{name.pascalCase()}}Loaded>()]),
    );
    bloc.add(const {{name.pascalCase()}}Started());
    await future;
    await bloc.close();
  });

  test('emits failure when the repository throws', () async {
    final bloc = {{name.pascalCase()}}Bloc(_FakeRepository(fail: true));
    final future = expectLater(
      bloc.stream,
      emitsInOrder([isA<{{name.pascalCase()}}Loading>(), isA<{{name.pascalCase()}}Failure>()]),
    );
    bloc.add(const {{name.pascalCase()}}Started());
    await future;
    await bloc.close();
  });
}
