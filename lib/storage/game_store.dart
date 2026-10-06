import '../engine/engine.dart';
import 'finished_game.dart';

/// A game as it is kept between two launches of the app: with its config, its
/// answers are all it takes to replay it to where it was left.
final class SavedGame {
  const SavedGame({
    required this.id,
    required this.config,
    required this.answers,
    required this.round,
    required this.humanScore,
  });

  final int id;
  final GameConfig config;
  final List<Answer> answers;

  /// Where the game stands, to describe it without replaying it.
  final int round;
  final int humanScore;
}

/// Where games are kept. At most one game is in progress at a time.
abstract interface class GameStore {
  /// The game in progress, if there is one that can still be read.
  Future<SavedGame?> loadActive();

  /// Starts keeping a new game, dropping any other game in progress.
  /// Returns its identifier.
  Future<int> create(GameConfig config);

  /// Records where game [id] stands.
  Future<void> saveProgress(
    int id, {
    required List<Answer> answers,
    required int round,
    required int humanScore,
  });

  /// Marks game [id] as over: it is no longer the game in progress, and
  /// joins the finished games.
  Future<void> finish(
    int id,
    GameFinished result, {
    required GameSummary summary,
    required String playerName,
  });

  /// Every finished game, the latest first.
  Future<List<FinishedGame>> loadFinished();

  /// The config and answers of game [id], to replay it. Null when the game
  /// is gone or can no longer be read.
  Future<SavedGame?> loadGame(int id);

  /// Forgets finished game [id].
  Future<void> deleteFinished(int id);

  /// Drops the game in progress, if any.
  Future<void> discardActive();
}
