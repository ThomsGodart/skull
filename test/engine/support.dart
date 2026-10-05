import 'package:skull_kings/engine/engine.dart';

Card g(int value) => Card.number(Suit.green, value);
Card y(int value) => Card.number(Suit.yellow, value);
Card p(int value) => Card.number(Suit.purple, value);
Card b(int value) => Card.number(Suit.black, value);
Card pirate([int copy = 1]) => Card.special(CardKind.pirate, copy);
Card esc([int copy = 1]) => Card.special(CardKind.escape, copy);
Card mermaid([int copy = 1]) => Card.special(CardKind.mermaid, copy);
final Card skullKing = Card.special(CardKind.skullKing);
final Card tigress = Card.special(CardKind.tigress);

/// A trick where seat i played `cards[i]`. A tigress is played as [tigressAs].
List<Play> trick(List<Card> cards, {TigressMode? tigressAs}) => [
  for (final (seat, card) in cards.indexed)
    Play(
      seat: seat,
      card: card,
      tigressAs: card.kind == CardKind.tigress ? tigressAs : null,
    ),
];
