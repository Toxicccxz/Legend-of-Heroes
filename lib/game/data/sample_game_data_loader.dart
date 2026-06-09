import '../repositories/game_definition_repository.dart';

class SampleGameDataLoader {
  const SampleGameDataLoader(this._repository);

  final GameDefinitionRepository _repository;

  Future<GameDefinitions> load() {
    return _repository.load();
  }
}
