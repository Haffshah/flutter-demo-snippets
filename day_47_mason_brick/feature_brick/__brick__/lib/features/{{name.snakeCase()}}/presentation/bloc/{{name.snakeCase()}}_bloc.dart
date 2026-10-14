import 'package:bloc/bloc.dart';

import '../../domain/repositories/{{name.snakeCase()}}_repository.dart';

part '{{name.snakeCase()}}_event.dart';
part '{{name.snakeCase()}}_state.dart';

class {{name.pascalCase()}}Bloc extends Bloc<{{name.pascalCase()}}Event, {{name.pascalCase()}}State> {
  {{name.pascalCase()}}Bloc(this._repository) : super(const {{name.pascalCase()}}Initial()) {
    on<{{name.pascalCase()}}Started>(_onStarted);
  }

  final {{name.pascalCase()}}Repository _repository;

  Future<void> _onStarted({{name.pascalCase()}}Started event, Emitter<{{name.pascalCase()}}State> emit) async {
    emit(const {{name.pascalCase()}}Loading());
    try {
      emit({{name.pascalCase()}}Loaded(await _repository.load()));
    } catch (e) {
      emit({{name.pascalCase()}}Failure(e.toString()));
    }
  }
}
