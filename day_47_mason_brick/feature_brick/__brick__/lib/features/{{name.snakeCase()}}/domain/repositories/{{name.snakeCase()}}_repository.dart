/// Contract for the {{name.titleCase()}} feature. The domain layer depends on this, never on HTTP or a database.
abstract class {{name.pascalCase()}}Repository {
  Future<String> load();
}
