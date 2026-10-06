import 'dart:math';

import '../engine/engine.dart';

/// Decides for a seat nobody is playing. It only gets what that seat may see.
typedef Bot = Answer Function(Question question, GameView view);

/// The weakest bot: any legal answer.
Bot randomBot(Random random) =>
    (question, view) => randomAnswer(question, random);
