import '../storage/game_store.dart';
import 'game_controller.dart';

/// Keeps game [id] up to date in [store] as it is played.
///
/// Writes are queued so that they land in the order the answers were given.
final class GameSaver {
  GameSaver(this.store, this.id);

  final GameStore store;
  final int id;
  Future<void> _lastWrite = Future.value();

  /// Completes when everything recorded so far has been written.
  Future<void> get done => _lastWrite;

  void record(GameProgress progress) {
    _lastWrite = _lastWrite
        .then(
          (_) => switch (progress.result) {
            final result? => store.finish(id, result),
            null => store.saveProgress(
              id,
              answers: progress.answers,
              round: progress.round,
              humanScore: progress.humanScore,
            ),
          },
        )
        // A failed write must not stop the later ones.
        .catchError((Object _) {});
  }
}
