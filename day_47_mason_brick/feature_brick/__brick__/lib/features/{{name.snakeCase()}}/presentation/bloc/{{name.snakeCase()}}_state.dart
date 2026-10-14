part of '{{name.snakeCase()}}_bloc.dart';

sealed class {{name.pascalCase()}}State {
  const {{name.pascalCase()}}State();
}

final class {{name.pascalCase()}}Initial extends {{name.pascalCase()}}State {
  const {{name.pascalCase()}}Initial();
}

final class {{name.pascalCase()}}Loading extends {{name.pascalCase()}}State {
  const {{name.pascalCase()}}Loading();
}

final class {{name.pascalCase()}}Loaded extends {{name.pascalCase()}}State {
  const {{name.pascalCase()}}Loaded(this.data);
  final String data;
}

final class {{name.pascalCase()}}Failure extends {{name.pascalCase()}}State {
  const {{name.pascalCase()}}Failure(this.message);
  final String message;
}
