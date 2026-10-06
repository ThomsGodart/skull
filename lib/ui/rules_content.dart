/// The rules as the player reads them in the app: our own summary of the
/// base game, written from GAME_RULES.md.
///
/// Kept apart from `strings.dart` because of its length; like it, this file
/// holds nothing but text.
abstract final class RulesContent {
  static const sections = [
    (
      title: 'Le but',
      body:
          'À chaque manche, parie le nombre exact de plis que tu vas '
          'remporter. Tu marques des points si tu tiens ton pari, tu en perds '
          'sinon. Le meilleur score après 10 manches gagne.',
    ),
    (
      title: 'Une manche',
      body:
          'La manche 1 se joue avec 1 carte chacun, la manche 2 avec 2, et '
          'ainsi de suite jusqu\'à 10. À 8 joueurs, on ne dépasse jamais 8 '
          'cartes.\n\n'
          'Tout le monde parie en secret, puis les paris sont révélés '
          'ensemble. Le joueur à gauche du donneur entame le premier pli ; '
          'ensuite, celui qui remporte un pli entame le suivant.',
    ),
    (
      title: 'Les cartes Couleur',
      body:
          'Quatre couleurs, numérotées de 1 à 14 : vert, jaune, violet, et '
          'noir. Le noir est l\'atout : il bat les trois autres couleurs, '
          'quelle que soit sa valeur.\n\n'
          'La première carte Couleur d\'un pli fixe la couleur à suivre '
          '(sauf si un personnage a été joué avant elle, voir plus bas). Si '
          'tu as cette couleur, tu dois la jouer — ou jouer une carte '
          'spéciale. Si tu ne l\'as pas, joue ce que tu veux.\n\n'
          'Une carte d\'une autre couleur que celle demandée perd toujours, '
          'sauf si c\'est un atout.',
    ),
    (
      title: 'Les cartes spéciales',
      body:
          'Elles se jouent à tout moment, même si tu as la couleur '
          'demandée.\n\n'
          '• Fuite : perd toujours. Si tout le monde joue une fuite, la '
          'première l\'emporte.\n'
          '• Pirate : bat toutes les cartes Couleur. Entre pirates, le '
          'premier joué gagne.\n'
          '• Tigresse : tu choisis en la jouant si elle vaut un pirate ou '
          'une fuite.\n'
          '• Skull King : bat les pirates et toutes les cartes Couleur.\n'
          '• Sirène : bat toutes les cartes Couleur et le Skull King, mais '
          'perd contre les pirates. Entre sirènes, la première jouée '
          'gagne.\n\n'
          'Pirate, Skull King et sirène dans le même pli : la sirène gagne.',
    ),
    (
      title: 'Entamer avec une carte spéciale',
      body:
          'Une fuite (ou la Tigresse jouée comme fuite) ne fixe rien : c\'est '
          'la première carte Couleur jouée ensuite qui fixe la couleur, '
          'même après plusieurs fuites.\n\n'
          'Dès qu\'un pirate, la Tigresse en pirate, le Skull King ou une '
          'sirène est joué avant toute carte Couleur, il n\'y a plus de '
          'couleur à suivre pour ce pli : chacun joue ce qu\'il veut.',
    ),
    (
      title: 'Les points',
      body:
          'Pari de 1 ou plus, réussi : 20 points par pli.\n'
          'Pari de 1 ou plus, raté : −10 points par pli d\'écart.\n\n'
          'Pari de 0, réussi : 10 points par carte distribuée.\n'
          'Pari de 0, raté : −10 points par carte distribuée, quel que soit '
          'le nombre de plis pris.',
    ),
    (
      title: 'Les bonus',
      body:
          'Ils ne comptent que si ton pari est réussi.\n\n'
          '• Un 14 vert, jaune ou violet dans un pli gagné : +10\n'
          '• Le 14 noir dans un pli gagné : +20\n'
          '• Une sirène capturée par ton pirate : +20\n'
          '• Un pirate capturé par ton Skull King : +30\n'
          '• Le Skull King capturé par ta sirène : +40\n\n'
          'Les bonus s\'additionnent : deux pirates capturés d\'un coup '
          'valent +60.',
    ),
    (
      title: 'Égalité',
      body:
          'Si plusieurs joueurs sont premiers à égalité après la manche 10, '
          'on joue une manche de départage, et on recommence jusqu\'à avoir '
          'un seul premier.',
    ),
  ];
}
