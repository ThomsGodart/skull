/// The rules as the player reads them in the app: our own summary, written
/// from GAME_RULES.md.
///
/// Kept apart from `strings.dart` because of its length; like it, this file
/// holds nothing but text. A line that starts with [cardsMark] is no text to
/// read: it lists, by their identifiers, the cards to draw beside the line
/// that follows.
abstract final class RulesContent {
  static const cardsMark = '[cartes] ';

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
          '[cartes] green-14 yellow-14 purple-14 black-14\n'
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
          '[cartes] escape-1\n'
          '• Fuite : perd toujours. Si tout le monde joue une fuite, la '
          'première l\'emporte.\n'
          '[cartes] pirate-1\n'
          '• Pirate : bat toutes les cartes Couleur. Entre pirates, le '
          'premier joué gagne.\n'
          '[cartes] tigress-1\n'
          '• Tigresse : tu choisis en la jouant si elle vaut un pirate ou '
          'une fuite.\n'
          '[cartes] skullKing-1\n'
          '• Skull King : bat les pirates et toutes les cartes Couleur.\n'
          '[cartes] mermaid-1\n'
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
          '[cartes] green-14\n'
          '• Un 14 vert, jaune ou violet dans un pli gagné : +10\n'
          '[cartes] black-14\n'
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
    (
      title: 'À deux joueurs',
      body:
          'Un troisième paquet est distribué au fantôme de Barbe Grise. Il '
          'ne parie pas et ne marque pas, mais il prend des plis.\n\n'
          'Les deux joueurs entament les manches à tour de rôle. Barbe Grise '
          'joue toujours en deuxième : la carte du dessus de son paquet, '
          'sans avoir à suivre la couleur. S\'il remporte un pli, il entame '
          'le suivant, et le joueur qui a commencé la manche joue après '
          'lui.\n\n'
          'Sa Tigresse vaut une fuite. Le Butin n\'est pas utilisé.',
    ),
    (
      title: 'Extension : Kraken, Baleine blanche, Butin',
      body:
          'Ces cartes s\'ajoutent au choix à la création de la partie. '
          'Comme toute carte spéciale, elles se jouent à tout moment.\n\n'
          '[cartes] kraken-1\n'
          '• Kraken : le pli est détruit, personne ne le remporte et ses '
          'bonus sont perdus. Celui qui l\'aurait gagné entame le suivant.\n'
          '[cartes] whiteWhale-1\n'
          '• Baleine blanche : toutes les cartes spéciales du pli sont '
          'détruites et les couleurs ne comptent plus ; la plus haute valeur '
          'gagne, la première jouée en cas d\'égalité. S\'il ne reste que '
          'des cartes spéciales, le pli est détruit.\n'
          '• Les deux dans le même pli : seule la dernière jouée agit.\n'
          '[cartes] loot-1\n'
          '• Butin : perd comme une fuite, mais allie son joueur au gagnant '
          'du pli. Si tous deux réussissent leur pari, chacun marque +20. '
          'Pas d\'alliance si le pli est détruit, ni si c\'est le Butin qui '
          'l\'emporte parce que tout le monde a joué une fuite. En entame, '
          'il laisse la carte suivante fixer la couleur.\n\n'
          'Dès qu\'un Kraken ou une Baleine blanche est sur la table, plus '
          'personne n\'est obligé de suivre la couleur.',
    ),
    (
      title: 'Extension : pouvoirs des pirates',
      body:
          'Si l\'option est activée, gagner un pli avec un pirate déclenche '
          'son pouvoir, tout de suite. La Tigresse n\'en a pas, et un pli '
          'détruit n\'en déclenche aucun. Tu peux toujours choisir de ne '
          'rien changer.\n\n'
          '[cartes] pirate-1\n'
          '• Rosie la Douce : choisis qui entame le prochain pli.\n'
          '[cartes] pirate-2\n'
          '• Will le Bandit : pioche 2 cartes, puis défausse-en 2 (celles '
          'que tu viens de piocher si tu veux). S\'il reste moins de 2 '
          'cartes dans la pioche, tu prends ce qu\'il y a.\n'
          '[cartes] pirate-3\n'
          '• Rascal le Flambeur : mise 0, 10 ou 20 points, gagnés si ton '
          'pari est réussi, perdus sinon.\n'
          '[cartes] pirate-4\n'
          '• Juanita Jade : regarde les cartes qui n\'ont pas été '
          'distribuées.\n'
          '[cartes] pirate-5\n'
          '• Harry le Géant : à la fin de la manche, une fois tous les plis '
          'joués, modifie ton pari de plus ou moins 1.\n\n'
          'Les autres pouvoirs s\'utilisent tout de suite. Après le dernier '
          'pli, seule la mise de Rascal sert encore.',
    ),
    (
      title: 'Deuxième extension',
      body:
          'Une option à part, à la création de la partie (à partir de 3 '
          'joueurs). Elle ajoute 19 cartes, et permet de distribuer 10 '
          'cartes même à 8 joueurs.\n\n'
          '[cartes] green-7-extra yellow-8-extra\n'
          '• 7 et 8 en double dans chaque couleur : de deux cartes égales, '
          'la première jouée l\'emporte. Remporter le 8 de l\'extension '
          'vaut +5, le 7 coûte −5, si ton pari est réussi.\n'
          '[cartes] purple-0or14\n'
          '• 0/14 dans chaque couleur : tu dis en la jouant si c\'est un 0 '
          'ou un 14. Elle ne rapporte pas de bonus.\n'
          '[cartes] joker-1\n'
          '• Joker 15 : un 15 de la couleur demandée (verte, jaune ou '
          'violette). S\'il fixe la couleur, tu la choisis. Jamais atout : '
          'il perd si le noir est demandé. Tu peux toujours le jouer.\n'
          '[cartes] pirate-6\n'
          '• Mary Thorne : un pirate de plus. Son pouvoir : tu désignes un '
          'joueur, qui devra jouer au pli suivant une carte tirée au hasard '
          'dans sa main.\n'
          '[cartes] mat-1\n'
          '• Mat le Forban : bat les pirates et les couleurs, perd contre '
          'le Skull King et les sirènes, qui gagnent alors +30. Il utilise '
          'les pouvoirs des pirates qu\'il capture.\n'
          '[cartes] plank-1\n'
          '• Marcher sur la planche : ne gagne pas de pli, mais élimine un '
          'pirate du pli (ni Mat ni la Tigresse). S\'il y en a plusieurs, '
          'son joueur choisit.\n'
          '[cartes] stingray-1\n'
          '• Raie Tachetée : comme la Baleine blanche, mais la plus basse '
          'valeur gagne. De plusieurs monstres marins, le dernier joué '
          'décide.\n'
          '[cartes] lastSalvo-1\n'
          '• Dernière Salve : ne gagne pas de pli. Son joueur rejoue une '
          'carte après tous les autres, puis saute le prochain pli qu\'il '
          'n\'entame pas.\n'
          '[cartes] davyJones-1\n'
          '• Coffre de Davy Jones : ne gagne pas de pli. Il détruit les '
          'monstres marins du pli, qui se joue alors sans eux : +20 par '
          'monstre pour son joueur, si son pari est réussi.\n\n'
          'Planche, Raie, Salve et Coffre ne sont pas des fuites. Un pli qui '
          'ne contient qu\'elles est défaussé, et celui qui l\'a entamé '
          'rejoue.',
    ),
    (
      title: 'Score Rascal',
      body:
          'Une autre façon de compter, au choix à la création de la partie. '
          'À chaque manche, tout le monde peut gagner la même chose : 10 '
          'points par carte distribuée.\n\n'
          '• Pari exact : la totalité, et tous tes bonus.\n'
          '• À un pli près : la moitié, et la moitié de tes bonus.\n'
          '• Deux plis d\'écart ou plus : rien.\n\n'
          'Un pari ne fait jamais perdre de points. L\'alliance du Butin et '
          'la mise de Rascal demandent toujours un pari exact : à un pli '
          'près, la mise est perdue, et c\'est le seul moyen de finir une '
          'manche dans le négatif.',
    ),
  ];
}
