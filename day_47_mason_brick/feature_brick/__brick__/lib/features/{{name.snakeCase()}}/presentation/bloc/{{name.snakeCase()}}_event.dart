part of '{{name.snakeCase()}}_bloc.dart';

sealed class {{name.pascalCase()}}Event {
  const {{name.pascalCase()}}Event();
}

final class {{name.pascalCase()}}Started extends {{name.pascalCase()}}Event {
  const {{name.pascalCase()}}Started();
}
