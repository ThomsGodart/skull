import 'dart:math';

import '../engine/engine.dart';

/// Every text the player reads. Kept in one place so it can be translated.
abstract final class Strings {
  static const appTitle = 'Skull Kings';

  /// Pictograms, as characters of the bundled font.
  static const homeEmblem = '\u{2620}';
  static const tagline = 'Parie tes plis, tiens ta parole.';
  static const newGame = 'Nouvelle partie';
  static const opponents = 'Adversaires';
  static const you = 'Toi';
  static const ghostName = 'Barbe Grise';
  static const twoPlayersNote =
      'À 2 joueurs, le fantôme de Barbe Grise joue un troisième paquet : il '
      'ne parie pas, ne marque pas, mais prend des plis. Le Butin et la '
      'deuxième extension ne sont pas utilisés.';

  /// Pool of pirate-style names: bots (and a random player name) are drawn
  /// from here without repeating at the same table.
  static const botNames = [
    'Mako',
    'Corail',
    'Bosco',
    'Sloop',
    'Récif',
    'Ancre',
    'Rafale',
    'Brume',
    'Écubier',
    'Caravelle',
    'Corsaire',
    'Crabe',
    'Dauphin',
    'Écume',
    'Fregate',
    'Galion',
    'Goéland',
    'Harpon',
    'Houle',
    'Jolly',
    'Kraken',
    'Lagon',
    'Lame',
    'Marée',
    'Mouette',
    'Nautilus',
    'Nerée',
    'Ouragan',
    'Perle',
    'Pirate',
    'Plume',
    'Poseidon',
    'Requins',
    'Rhum',
    'Sabre',
    'Salée',
    'Sirène',
    'Tempête',
    'Timon',
    'Tortue',
    'Trident',
    'Vague',
    'Vigie',
    'Vortex',
    'Alizé',
    'Baleine',
    'Boucan',
    'Cabestan',
    'Flibuste',
    'Naufrage',
  ];

  /// [count] distinct names drawn from [botNames].
  static List<String> shuffledBotNames(int count, [Random? random]) {
    if (count < 0 || count > botNames.length) {
      throw ArgumentError.value(count, 'count', 'must be 0..${botNames.length}');
    }
    final names = List<String>.of(botNames)..shuffle(random ?? Random());
    return names.take(count).toList();
  }

  static String roundTitle(int round, int cards) =>
      'Manche $round · $cards carte${cards > 1 ? 's' : ''}';
  static String tieBreakTitle(int cards) =>
      'Départage · $cards carte${cards > 1 ? 's' : ''}';

  static const chooseBid = 'Combien de plis vas-tu prendre ?';
  static String placeBid(int bid) => 'Parier $bid';
  static const pickBidFirst = 'Choisis un nombre';
  static const yourLead = 'À toi — joue la carte de ton choix';
  static const playAnything =
      'À toi — pas de couleur à suivre : joue ce que tu veux';
  static String followSuit(Suit suit) => 'À toi — fournis du ${suitName(suit)}';
  static String noSuitHeld(Suit suit) =>
      'À toi — pas de ${suitName(suit)} : joue ce que tu veux';
  static const playCard = 'Jouer';
  static String bidPlaced(int bid) => 'Pari validé : $bid';
  static const waitingForBids = 'En attente des autres joueurs…';
  static const changeBid = 'Modifier mon pari';
  static String destroyedTricks(int count) =>
      '$count pli${count > 1 ? 's' : ''} détruit${count > 1 ? 's' : ''} : '
      'personne ne l${count > 1 ? 'es' : '\''} a remporté${count > 1 ? 's' : ''}';
  static String wagerBadge(int amount) => 'Mise $amount';
  static const harryBadge = 'Harry ±1';
  static const harryBadgeHelp =
      'A gagné un pli avec Harry : pourra modifier son pari de 1 à la fin '
      'de la manche';
  static String wagerBadgeHelp(int amount) =>
      'A misé $amount avec Rascal le Flambeur';
  static const cardEffectsLabel = 'Afficher l\'effet des cartes';
  static const cardEffectsHelp =
      'Quand tu touches une carte, son rôle s\'affiche au-dessus de ta main.';
  static const trickTokensLabel = 'Jetons de plis';
  static const trickTokensHelp =
      'Un jeton par pli parié, plein une fois le pli remporté.';
  static const autoHarryLabel = 'Harry le Géant automatique';
  static const autoHarryHelp =
      'À la fin de la manche, ton pari est ajusté tout seul vers le nombre '
      'de plis remportés.';
  static String thinking(String name) => '$name réfléchit…';
  static String trickFor(String name) => 'Pli pour $name';
  static const trickForYou = 'Pli pour toi';
  static String trickBonus(List<Bonus> bonuses) {
    final points = bonuses.fold(0, (sum, bonus) => sum + bonus.points);
    return '+$points (${bonuses.map(bonusName).join(', ')}) '
        'si le pari est réussi';
  }

  static const zeroFourteen = '0/14';
  static const zeroFourteenTitle = 'Jouer cette carte comme…';
  static String asValue(int value) => 'Un $value';
  static const jokerTitle = 'Le Joker fixe la couleur…';
  static String jokerAs(Suit suit) => 'en ${suitName(suit)}';
  static const plankTitle = 'Marcher sur la planche';
  static const plankBody = 'Quel pirate quitte le pli ?';
  static const victimBody =
      'Qui devra jouer, au prochain pli, une carte tirée au hasard dans sa '
      'main ?';
  static String victimChosen(String victim) =>
      'Mary Thorne : $victim jouera une carte tirée au hasard';
  static const victimChosenYou =
      'Mary Thorne : tu dois jouer la carte tirée au hasard dans ta main';
  static const overboard = 'à l\'eau';
  static String forcedCard(String card) =>
      'À toi — Mary Thorne t\'impose de jouer : $card';
  static String sideBonus(String name, Bonus bonus) =>
      '${signed(bonus.points)} pour $name (${bonusName(bonus)}) si son pari '
      'est réussi';
  static String optionalCard(CardKind kind) => switch (kind) {
    CardKind.mat => 'Mat le Forban',
    CardKind.plank => 'Marcher sur la planche',
    CardKind.stingray => 'Raie Tachetée',
    CardKind.lastSalvo => 'La Dernière Salve',
    CardKind.davyJones => 'Le Coffre de Davy Jones',
    _ => throw ArgumentError.value(kind, 'kind', 'is not an optional card'),
  };
  static const optionSecondExpansion = 'Deuxième extension (19 cartes)';
  static const optionSecondExpansionHelp =
      '7, 8 et 0/14 en plus, Joker 15, Mary Thorne, Mat le Forban, Raie '
      'Tachetée, Dernière Salve, Coffre de Davy Jones, Marcher sur la '
      'planche.';
  static const secondExpansionShort = '2ᵉ extension';
  static const tigressTitle = 'Jouer la Tigresse comme…';
  static const asPirate = 'Pirate';
  static const asEscape = 'Fuite';
  static String playedAs(TigressMode mode) => switch (mode) {
    TigressMode.pirate => 'pirate',
    TigressMode.escape => 'fuite',
  };

  static const dealer = 'Donneur';
  static const dealerMark = 'D';
  static const leadMark = '1er';
  static const leadsNext = 'Entame le prochain pli';
  static String bidsTotal(int bids, int cards) =>
      'Paris : $bids pour $cards pli${cards > 1 ? 's' : ''}';

  /// What a card does, in a sentence, for the player who looks at it closely.
  /// Null for a plain number card. With [powers], a pirate tells its power.
  static String? cardHint(Card card, {required bool powers}) =>
      switch (card.kind) {
        CardKind.number when card.isExtraNumber =>
          card.value == 8
              ? '8 de l\'extension : +5 pour qui remporte le pli, si son '
                    'pari est réussi.'
              : '7 de l\'extension : −5 pour qui remporte le pli, si son '
                    'pari est réussi.',
        CardKind.number =>
          card.suit == Suit.black
              ? 'Atout : bat les trois autres couleurs.'
              : null,
        CardKind.zeroFourteen =>
          '0 ou 14 : tu choisis en la jouant. Jouée comme 14, elle ne '
              'rapporte pas de bonus.',
        CardKind.joker =>
          'Un 15 de la couleur demandée, ou de celle que tu choisis si tu '
              'fixes la couleur. Jamais atout : perd si le noir est demandé.',
        CardKind.mat =>
          'Bat les pirates et les couleurs. Perd contre le Skull King et '
              'les sirènes, qui gagnent alors +30.'
              '${powers ? ' Utilise les pouvoirs des pirates capturés.' : ''}',
        CardKind.plank =>
          'Ne gagne pas de pli. Élimine un pirate du pli : tu choisis '
              'lequel s\'il y en a plusieurs.',
        CardKind.stingray =>
          'Détruit les cartes spéciales : la plus basse valeur gagne, '
              'quelle que soit sa couleur.',
        CardKind.lastSalvo =>
          'Ne gagne pas de pli. Tu rejoues une carte après tous les '
              'autres, puis tu sautes le pli suivant.',
        CardKind.davyJones =>
          'Ne gagne pas de pli. Détruit les monstres marins du pli : +20 '
              'chacun si ton pari est réussi.',
        CardKind.escape => 'Perd toujours.',
        CardKind.pirate => switch (Pirate.of(card)) {
          final pirate? when powers =>
            '${pirateName(pirate)}. ${piratePower(pirate)}',
          _ =>
            'Bat toutes les cartes Couleur et les sirènes. Perd contre le '
                'Skull King.',
        },
        CardKind.tigress =>
          'Pirate ou fuite : tu choisis en la jouant. Elle n\'a pas de '
              'pouvoir.',
        CardKind.skullKing =>
          'Bat les pirates et toutes les couleurs. Perd contre une sirène.',
        CardKind.mermaid =>
          'Bat toutes les couleurs et le Skull King. Perd contre les pirates.',
        CardKind.loot =>
          'Perd comme une fuite. T\'allie au gagnant du pli : +20 chacun si '
              'vos deux paris sont réussis.',
        CardKind.kraken =>
          'Détruit le pli : personne ne le remporte, celui qui l\'aurait '
              'gagné entame.',
        CardKind.whiteWhale =>
          'Détruit les cartes spéciales : la plus haute valeur gagne, '
              'quelle que soit sa couleur.',
      };

  /// What winning a trick with [pirate] lets its player do.
  static String piratePower(Pirate pirate) => switch (pirate) {
    Pirate.rosie => 'Si elle gagne le pli : tu choisis qui entame le suivant.',
    Pirate.will =>
      'S\'il gagne le pli : tu pioches 2 cartes, puis tu en défausses 2.',
    Pirate.rascal =>
      'S\'il gagne le pli : tu mises 0, 10 ou 20 points sur ton pari.',
    Pirate.juanita =>
      'Si elle gagne le pli : tu regardes les cartes non distribuées.',
    Pirate.harry =>
      'S\'il gagne le pli : à la fin de la manche, tu peux modifier ton '
          'pari de 1.',
    Pirate.mary =>
      'Si elle gagne le pli : tu désignes un joueur, qui devra jouer au '
          'pli suivant une carte tirée au hasard dans sa main.',
  };
  static const ghostLabel = 'fantôme';
  static String leadsRound(String name) => '$name entame la manche';
  static const youLeadRound = 'Tu entames la manche';
  static String points(int score) => '$score pts';
  static String cardsLeft(int cards) => '$cards c.';

  static const lastTrick = 'Dernier pli';
  static const noLastTrick = 'Aucun pli joué dans cette manche.';
  static const scoreSheet = 'Feuille de score';
  static const close = 'Fermer';
  static const quit = 'Quitter';
  static const pause = 'Pause';
  static const finishEarly = 'Terminer la partie';
  static const finishEarlyConfirm =
      'La manche en cours ne sera pas comptée. Les scores restent '
      'tels quels.';
  static const gameIsSaved =
      'La partie est sauvegardée. Tu pourras la reprendre depuis l\'accueil.';
  static const resume = 'Reprendre';
  static const bidAcceptedHelp = 'Pari validé';
  static const startingRoundLabel = 'Commencer à la manche';
  static String startingRoundOption(int round, int cards) =>
      'Manche $round · $cards carte${cards > 1 ? 's' : ''}';
  static const chatTitle = 'Discussion';
  static const chatHint = 'Écrire un message…';
  static const chatSend = 'Envoyer';
  static const chatEmpty = 'Aucun message pour l\'instant.';
  static const lastTrickLabel = 'Dernier pli';
  static const yourHandLabel = 'Ta main';
  static const stockLabel = 'Cartes non distribuées';
  static String wagerBodyWithBid(int bid) =>
      'Ton pari est $bid. Mise dessus : gagnée s\'il est réussi, '
      'perdue sinon.';
  static const nameForbidden =
      'Choisis un vrai nom : « Toi » n\'est pas autorisé.';
  static const optionFirstExpansion = 'Première extension';
  static const optionFirstExpansionHelp =
      'Choisis les cartes à ajouter au jeu de base.';

  static String savedGameSummary(int round, int score) =>
      'Manche $round · ${points(score)}';
  static const replaceGameTitle = 'Remplacer la partie en cours ?';
  static const replaceGameBody =
      'Une partie est déjà commencée. En lancer une nouvelle l\'efface.';
  static const replaceGame = 'Remplacer';
  static const keepGame = 'Garder';

  static const setupTitle = 'Nouvelle partie';
  static const launch = 'Lancer la partie';
  static String setupSummary(GameConfig config) =>
      '${config.players} joueurs · ${modeName(config)} · '
      '$standardRounds manches';
  static String fewerCardsNote(int players, int cards) =>
      'À $players joueurs, les dernières manches se jouent avec $cards cartes.';
  static const saveFailed = 'La sauvegarde a échoué.';
  static const cannotStart = 'Impossible de lancer la partie.';

  static const history = 'Historique';
  static const historyEmpty = 'Aucune partie terminée pour l\'instant.';
  static String historyResult(int rank, int score) =>
      '${ordinal(rank)} · ${points(score)}';
  static String playersCount(int players) => '$players joueurs';
  static String wonBy(String name) => 'Gagnée par $name';
  static const wonByYou = 'Gagnée par toi';

  /// The first line under a game in the history. A null [winner] is the human.
  static String historyDetails({required DateTime date, String? winner}) =>
      '${dateTime(date)} · ${winner == null ? wonByYou : wonBy(winner)}';
  static String gameSetup(int players, GameConfig? config) =>
      [playersCount(players), if (config != null) modeName(config)].join(' · ');
  static const delete = 'Supprimer';
  static const deleteGameTitle = 'Supprimer cette partie ?';
  static const deleteGameBody =
      'Elle disparaîtra de l\'historique et des statistiques.';
  static const gameDetailTitle = 'Détail de la partie';
  static const detailUnavailable =
      'Le détail de cette partie n\'est plus disponible.';

  static String ordinal(int rank) => rank == 1 ? '1er' : '${rank}e';

  /// A day and a time, as in « 06/10/2026 à 21:30 ».
  static String dateTime(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        'à ${two(date.hour)}:${two(date.minute)}';
  }

  static const loadFailed = 'Impossible de lire les parties enregistrées.';

  static const statistics = 'Statistiques';
  static const statGamesPlayed = 'Parties jouées';
  static const statWins = 'Victoires';
  static const statWinRate = 'Taux de victoire';
  static const statAverageRank = 'Classement moyen';
  static const statAverageScore = 'Score moyen';
  static const statBestScore = 'Meilleur score';
  static const statBidSuccess = 'Paris réussis';
  static const statZeroBidSuccess = 'Paris à 0 réussis';
  static String statMeasuredOn(int games) =>
      'Paris mesurés sur $games partie${games > 1 ? 's' : ''}.';

  /// Shown instead of a figure that has nothing to measure.
  static const unavailable = '—';
  static String percent(double ratio) => '${(ratio * 100).round()} %';
  static String decimal(double value) =>
      value.toStringAsFixed(1).replaceFirst('.', ',');

  static const settings = 'Réglages';
  static const botSpeedLabel = 'Vitesse des adversaires';
  static const speedNormal = 'Normale';
  static const speedFast = 'Rapide';
  static const speedInstant = 'Instantanée';
  static const singleTapPlay = 'Jouer en un seul appui';
  static const singleTapPlayHelp =
      'Sinon, un premier appui soulève la carte et un second la joue.';
  static const hapticsLabel = 'Vibrations';
  static const reduceMotionLabel = 'Réduire les animations';
  static const fullscreenLabel = 'Plein écran';
  static const fullscreenHelp =
      'Masque les barres du téléphone, ou agrandit la page depuis l\'appli.';
  static const fullscreenEnter = 'Plein écran';
  static const fullscreenExit = 'Quitter le plein écran';
  static const licenses = 'Licences';
  static const licensesHelp =
      'Les mentions légales des composants libres que l\'appli embarque : '
      'Flutter, la base de données, la police des pictogrammes…';

  static const rules = 'Règles';
  static const rulesTitle = 'Règles du jeu';

  static const botLevelLabel = 'Niveau des adversaires';
  static const levelEasy = 'Facile';
  static const levelNormal = 'Normal';
  static const levelHard = 'Difficile';
  static const levelHardHelp =
      'Avant chaque pari et chaque carte, les adversaires imaginent les '
      'mains des autres et jouent la manche dans leur tête. Ils se '
      'souviennent des cartes tombées.';
  static const levelEasyHelp =
      'Les adversaires se trompent souvent dans leurs paris et leurs cartes.';
  static const presetLabel = 'Mode de jeu';
  static const presetClassic = 'Classique';
  static const presetFull = 'Extension';
  static const presetCustom = 'Personnalisé';
  static const scoringLabel = 'Calcul des points';
  static const scoringClassic = 'Classique';
  static const scoringRascal = 'Rascal';
  static const scoringRascalHelp =
      'Même potentiel pour tous : tout si le pari est exact, la moitié à un '
      'pli près, rien au-delà. Pas de points négatifs, sauf une mise de '
      'Rascal le Flambeur perdue.';
  static const optionKraken = 'Kraken';
  static const optionKrakenHelp = 'Détruit le pli : personne ne le remporte.';
  static const optionWhale = 'Baleine blanche';
  static const optionWhaleHelp =
      'Détruit les cartes spéciales : la plus haute valeur gagne.';
  static const optionLoot = 'Butin (2 cartes)';
  static const optionLootHelp =
      'Alliance avec le gagnant du pli : +$allianceBonus chacun si les deux '
      'paris sont réussis.';
  static const optionPowers = 'Pouvoirs des pirates';
  static const optionPowersHelp =
      'Gagner un pli avec un pirate déclenche son pouvoir.';

  /// What a game is played with, as one line.
  static String modeName(GameConfig config) => [
    config.usesFullExpansion
        ? 'Extension complète'
        : config.usesExpansion
        ? 'Extension partielle'
        : 'Jeu de base',
    if (config.playsSecondExpansion) secondExpansionShort,
    config.scoring == Scoring.rascal ? 'score Rascal' : 'score classique',
  ].join(' · ');

  static String pirateName(Pirate pirate) => switch (pirate) {
    Pirate.rosie => 'Rosie la Douce',
    Pirate.will => 'Will le Bandit',
    Pirate.rascal => 'Rascal le Flambeur',
    Pirate.juanita => 'Juanita Jade',
    Pirate.harry => 'Harry le Géant',
    Pirate.mary => 'Mary Thorne',
  };

  /// The short name written on a pirate card.
  static String pirateShortName(Pirate pirate) => switch (pirate) {
    Pirate.rosie => 'Rosie',
    Pirate.will => 'Will',
    Pirate.rascal => 'Rascal',
    Pirate.juanita => 'Juanita',
    Pirate.harry => 'Harry',
    Pirate.mary => 'Mary',
  };

  static String usesPower(String name, Pirate pirate) =>
      '$name utilise ${pirateName(pirate)}';
  static String harryLater(String name) =>
      '${pirateName(Pirate.harry)} : $name pourra modifier son pari à la '
      'fin de la manche';
  static const harryLaterYou =
      'Harry le Géant : tu pourras modifier ton pari à la fin de la manche';
  static String leaderChosen(String leader) =>
      '${pirateName(Pirate.rosie)} : $leader entame le prochain pli';
  static String cardsDiscarded(String name, int count) =>
      '${pirateName(Pirate.will)} : $name pioche et défausse '
      '$count carte${count > 1 ? 's' : ''}';
  static String wagerPlaced(String name, int amount) =>
      '${pirateName(Pirate.rascal)} : $name mise $amount';
  static String bidChanged(String name, int bid) =>
      '${pirateName(Pirate.harry)} : $name parie maintenant $bid';

  static const chooseLeaderBody = 'Qui entame le prochain pli ?';
  static String discardBody(int count) =>
      'Tu as pioché. Choisis $count carte${count > 1 ? 's' : ''} à défausser.';
  static const discardConfirm = 'Défausser';
  static const wagerBody =
      'Mise sur ton pari : gagnée s\'il est réussi, perdue sinon.';
  // Prefer [wagerBodyWithBid] when the current bid is known.
  static String wagerOption(int amount) =>
      amount == 0 ? 'Ne rien miser' : 'Miser $amount';
  static String adjustBidBody(int tricks) =>
      'La manche est finie : tu as pris $tricks pli${tricks > 1 ? 's' : ''}. '
      'Tu peux modifier ton pari d\'un pli.';
  static String adjustBidOption(int change, int bid) => switch (change) {
    0 => 'Garder $bid',
    > 0 => 'Monter à $bid',
    _ => 'Descendre à $bid',
  };
  static const stockBody = 'Ces cartes ne sont pas en jeu dans cette manche.';

  static String trickDestroyed(String leader) => 'Pli détruit — $leader entame';
  static const trickDestroyedYouLead = 'Pli détruit — tu entames';
  static String alliance(String first, String second) =>
      'Alliance : $first et $second, +$allianceBonus chacun si les deux '
      'paris sont réussis';
  static String allianceLine(int points) => 'alliance ${signed(points)}';
  static String wagerLine(int points) => 'mise ${signed(points)}';

  static const counter = 'Compteur de points';
  static const counterIntro =
      'Vous jouez avec le vrai paquet : l\'appli tient la feuille de score.';
  static const counterNew = 'Nouvelle partie à compter';
  static const counterResume = 'Reprendre';
  static String counterResumeSummary(int round, int players) =>
      'Manche $round · ${playersCount(players)}';
  static const counterFinished = 'Parties comptées';
  static const counterPlayers = 'Joueurs';
  static String counterPlayerHint(int number) => 'Joueur $number';
  static const counterAddPlayer = 'Ajouter un joueur';
  static const counterRemovePlayer = 'Retirer';
  static const counterFirstLeader = 'Premier à entamer';
  static const counterStart = 'Commencer';
  static const counterNeedNames = 'Donne un nom à chaque joueur.';
  static const counterDistinctNames =
      'Deux joueurs portent le même nom : change-en un.';
  static String counterRoundTitle(int round, int cards) =>
      roundTitle(round, cards);
  static String counterLeads(String name) => '$name entame';
  static String counterEnterRound(int round) => 'Saisir la manche $round';
  static String counterEnterResults(int round) =>
      'Saisir les résultats de la manche $round';
  static const counterBidsPhase = 'Les paris';
  static const counterResultsPhase = 'Les résultats';
  static const counterBidsDone = 'Valider les paris';
  static const counterRoundDone = 'Valider la manche';
  static const counterCards = 'Cartes par joueur';
  static const counterBid = 'Pari';
  static const counterTricks = 'Plis';
  static const counterBonus = 'Bonus';
  static const counterSecondExpansion = 'Deuxième extension';
  static const counterSecondExpansionHelp =
      '$optionSecondExpansionHelp Ajoute leurs bonus à la saisie.';
  static const counterManualBonuses = 'Bonus comptés à la main';
  static const counterManualBonusesHelp =
      'Tu additionnes toi-même les bonus de chaque joueur et tu saisis le '
      'total, sans détailler les cartes.';
  static String counterBonusFor(String name) => 'Bonus de $name';
  static String counterTricksMismatch(int claimed, int cards) =>
      '$claimed pli${claimed > 1 ? 's' : ''} saisi${claimed > 1 ? 's' : ''} '
      'pour $cards carte${cards > 1 ? 's' : ''} : '
      '${claimed > cards ? 'c\'est trop, corrige les plis.' : 'vérifie, sauf si un pli a été détruit.'}';
  static const counterAlliances = 'Alliances (Butin)';
  static const counterAddAlliance = 'Ajouter une alliance';
  static String counterAlliance(String first, String second) =>
      '$first et $second';
  static const counterAllianceTitle = 'Qui s\'allie ?';
  static const counterWager = 'Mise de Rascal';
  static const counterCorrectHint =
      'Touche le numéro d\'une manche pour la corriger.';
  static const counterFinish = 'Terminer la partie';
  static const counterTieBreak =
      'Égalité en tête : jouez une manche de départage.';
  static const ok = 'OK';

  static String bonusLabel(Bonus bonus) =>
      '${switch (bonus) {
        Bonus.standardFourteen => '14 vert, jaune ou violet',
        Bonus.blackFourteen => '14 noir',
        Bonus.mermaidCaptured => 'Sirène capturée par un pirate',
        Bonus.pirateCaptured => 'Pirate capturé par le Skull King',
        Bonus.skullKingCaptured => 'Skull King capturé par une sirène',
        Bonus.extraEight => '8 de l\'extension',
        Bonus.extraSeven => '7 de l\'extension',
        Bonus.matCaptured => 'Mat le Forban capturé par le Skull King ou une sirène',
        Bonus.seaMonsterCaptured => 'Monstre marin détruit par le Coffre de Davy Jones',
      }} (${signed(bonus.points)})';

  static const online = 'Jouer en ligne';
  static const onlineIntro =
      'Chacun sur son téléphone. Celui qui crée la partie donne le code '
      'aux autres ; son téléphone fait tourner la partie.';
  static const onlineCreate = 'Créer une partie';
  static const onlineJoin = 'Rejoindre';
  static const onlineCodeLabel = 'Code de la partie';
  static const onlineCodeHint = 'ABCD';
  static const onlineRoomTitle = 'Salon';
  static String onlineCode(String code) => 'Code : $code';
  static const onlineShareCode = 'Donne ce code aux autres joueurs.';
  static const onlineWaitingHost = 'En attente que l\'hôte lance la partie…';
  static const onlineConnecting = 'Connexion…';
  static String onlineSeats(int people, int seats) =>
      '$people joueur${people > 1 ? 's' : ''} · $seats au maximum';
  static const onlineBotsTitle = 'Ajouter des bots ?';
  static String onlineBotsBody(int people, int room) =>
      'Vous êtes $people. Jusqu\'à $room bot${room > 1 ? 's' : ''} '
      'peu${room > 1 ? 'vent' : 't'} compléter la table.';
  static const onlineSetupNote =
      'Le nombre de joueurs se décide dans le salon : tous ceux qui '
      'rejoignent jouent, et tu pourras ajouter des bots au lancement.';
  static const onlineStart = 'Lancer la partie';
  static const onlineNeedGuest = 'Attends qu\'un autre joueur te rejoigne.';
  static String onlineAwayCounting(String name, int seconds) =>
      '$name est déconnecté · un bot joue à sa place dans $seconds s';
  static String onlineAwayHeld(String name) =>
      '$name est déconnecté · on l\'attend';
  static String onlineAwayReplaced(String name) =>
      '$name est déconnecté · un bot joue à sa place jusqu\'à son retour';
  static const onlineKeepWaiting = 'L\'attendre';
  static const onlineReplaceNow = 'Mettre un bot';
  static const onlineNamePrompt =
      'Les autres joueurs te verront sous ce nom. Choisis le tien avant de '
      'jouer en ligne.';
  static const onlineHostTag = 'hôte';
  static const onlineAwayTag = 'déconnecté';
  static const onlineYouTag = 'toi';
  static const onlineCannotConnect =
      'Connexion impossible. Vérifie ta connexion Internet et réessaie.';
  static String onlineRefused(String reason) => switch (reason) {
    'full' => 'Cette partie est complète.',
    'started' => 'Cette partie a déjà commencé.',
    'version' => 'Vos applis n\'ont pas la même version : mettez-les à jour.',
    _ => 'Impossible de rejoindre cette partie.',
  };
  static const onlineHostAway =
      'L\'hôte est déconnecté : la partie est en pause.';
  static const onlineClosed = 'L\'hôte a mis fin à la partie.';
  static const onlineLeaveHost =
      'Si tu quittes, la partie s\'arrête pour tout le monde.';
  static const onlineLeaveGuest = 'Si tu quittes, un bot jouera à ta place.';
  static const leave = 'Quitter';
  static const backToHome = 'Retour à l\'accueil';

  static const profileTitle = 'Ton profil';
  static const playerNameLabel = 'Nom';
  static const playerColorLabel = 'Couleur';
  static const save = 'Enregistrer';
  static const cancel = 'Annuler';

  static String roundOver(int round) => 'Fin de la manche $round';
  static const continueGame = 'Continuer';
  static const colPlayer = 'Joueur';
  static const colBid = 'Pari';
  static const colTricks = 'Plis';
  static const colTricksBid = 'Plis/Pari';
  static String tricksOverBid(int tricks, int bid) => '$tricks/$bid';
  static const bonusHeading = 'Bonus';
  static const colBidPoints = 'Points';
  static const colBonus = 'Bonus';
  static const colRound = 'Manche';
  static const colTotal = 'Total';
  static const bonusLost = 'perdu';
  static const noBonus = '—';
  static String detailsOf(String name, List<String> details) =>
      '$name : ${details.join(', ')}';

  static const gameOver = 'Partie terminée';
  static const winnerMark = '\u{1F3C6}';
  static const youWin = 'Tu gagnes !';
  static String wins(String name) => '$name gagne';
  static String youWinWith(int score) => 'Tu gagnes avec ${points(score)} !';
  static String winsWith(String name, int score) =>
      '$name gagne avec ${points(score)}';
  static const playAgain = 'Rejouer';
  static const home = 'Accueil';

  static String suitName(Suit suit) => switch (suit) {
    Suit.green => 'vert',
    Suit.yellow => 'jaune',
    Suit.purple => 'violet',
    Suit.black => 'noir',
  };

  static const trump = 'ATOUT';

  /// The name of [card]. With [namedPirates], a pirate goes by its own name.
  static String cardName(Card card, {bool namedPirates = false}) =>
      switch (Pirate.of(card)) {
        final pirate? when namedPirates => pirateShortName(pirate),
        _ => _kindName(card),
      };

  static String _kindName(Card card) => switch (card.kind) {
    CardKind.number => '${card.value} ${suitName(card.suit!)}',
    CardKind.zeroFourteen => '$zeroFourteen ${suitName(card.suit!)}',
    CardKind.joker => 'Joker 15',
    CardKind.mat => 'Mat',
    CardKind.plank => 'Planche',
    CardKind.stingray => 'Raie',
    CardKind.lastSalvo => 'Salve',
    CardKind.davyJones => 'Coffre',
    CardKind.escape => 'Fuite',
    CardKind.pirate => 'Pirate',
    CardKind.tigress => 'Tigresse',
    CardKind.skullKing => 'Skull King',
    CardKind.mermaid => 'Sirène',
    CardKind.loot => 'Butin',
    CardKind.kraken => 'Kraken',
    CardKind.whiteWhale => 'Baleine blanche',
  };

  static String bonusName(Bonus bonus) => switch (bonus) {
    Bonus.standardFourteen => '14',
    Bonus.blackFourteen => '14 noir',
    Bonus.mermaidCaptured => 'sirène capturée',
    Bonus.pirateCaptured => 'pirate capturé',
    Bonus.skullKingCaptured => 'Skull King capturé',
    Bonus.extraEight => '8 de l\'extension',
    Bonus.extraSeven => '7 de l\'extension',
    Bonus.matCaptured => 'Mat le Forban capturé',
    Bonus.seaMonsterCaptured => 'monstre marin détruit',
  };

  static String signed(int points) => points > 0 ? '+$points' : '$points';

  /// Like [signed], for a figure that may well be zero.
  static String signedOrZero(int points) => points == 0 ? '0' : signed(points);
}
