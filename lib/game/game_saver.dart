import '../history/game_summary.dart';
import '../storage/game_store.dart';
import 'game_controller.dart';

/// Keeps game [id] up to date in [store] as it is played.
///
/// Writes are queued so that they land in the order the answers were given.
final class GameSaver {
  GameSaver(
    this.store,
    this.id, {
    required this.playerName,
    this.humanSeat = 0,
    this.onError,
  });

  final GameStore store;
  final int id;

  /// Kept with the game when it ends, as the name the human bore then.
  final String playerName;
  final int humanSeat;

  /// Told about each write that failed. Later writes still go through, and
  /// each one carries the whole game, so a failed one is made up for.
  final void Function(Object error)? onError;

  Future<void> _lastWrite = Future.value();

  /// Completes when everything recorded so far has been written.
  Future<void> get done => _lastWrite;

  void record(GameProgress progress) {
    _lastWrite = _lastWrite.then((_) async {
      try {
        await store.saveProgress(
          id,
          answers: progress.answers,
          round: progress.round,
          humanScore: progress.humanScore,
        );
        if (progress.result case final result?) {
          await store.finish(
            id,
            result,
            summary: GameSummary.of(progress.rounds, humanSeat: humanSeat),
            playerName: playerName,
          );
        }
      } on Object catch (error) {
        onError?.call(error);
      }
    });
  }
}
