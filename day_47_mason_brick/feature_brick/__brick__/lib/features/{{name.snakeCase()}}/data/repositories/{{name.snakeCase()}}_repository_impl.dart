import '../../domain/repositories/{{name.snakeCase()}}_repository.dart';

/// Replace the body with your real data source (API client, local database, ...).
class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  @override
  Future<String> load() async => '{{name.titleCase()}} data';
}
