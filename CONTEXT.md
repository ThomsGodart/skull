# Vocabulaire du domaine

Le code, les identifiants et les tests sont en anglais ; tout ce que voit le joueur est en français. Ce fichier fixe la correspondance. Les règles sont dans `GAME_RULES.md`.

| Code | Interface | Sens |
|---|---|---|
| `Game` | partie | Dix manches (plus les éventuelles manches de départage). |
| `Round` | manche | Une distribution, les paris, puis autant de plis que de cartes distribuées. |
| `Trick` | pli | Une carte jouée par joueur ; une carte le remporte. |
| `Bid` | pari | Nombre de plis qu'un joueur annonce pour la manche. |
| `Seat` | joueur / siège | Position à la table, de 0 à n − 1, dans le sens horaire. À 2 joueurs il y a 3 sièges : le dernier est celui du fantôme, qui ne parie ni ne marque. |
| `Round starter` | — | Le joueur qui a entamé le premier pli de la manche. |
| `Dealer` | donneur | Distribue ; le siège à sa gauche entame. |
| `Lead` | entame | Première carte d'un pli ; `leader` = joueur qui entame. |
| `Play` | carte jouée | Une carte posée dans un pli par un siège, avec le mode choisi si c'est la Tigresse. |
| `Hand` | main | Cartes qu'un joueur détient. |
| `Suit` | couleur | `green` vert, `yellow` jaune, `purple` violet, `black` noir. |
| `Trump` | atout | La couleur noire. |
| `Lead suit` | couleur demandée | Couleur à suivre dans le pli, s'il y en a une. |
| `Number card` | carte Couleur | Carte numérotée de 1 à 14. |
| `Special card` | carte spéciale | Toute carte non numérotée. |
| `Character` | personnage | Pirate, Tigresse jouée comme pirate, Skull King, sirène. |
| `Escape` | fuite | Carte qui perd toujours. |
| `Pirate` | pirate | |
| `Tigress` | Tigresse | Jouée comme pirate ou comme fuite (`TigressMode`). |
| `Skull King` | Skull King | |
| `Mermaid` | sirène | |
| `Bonus` | bonus | Points gagnés avec un pli, comptés seulement si le pari est réussi. |
| `Capture` | capture | Un personnage en bat un autre et rapporte un bonus. |
| `Loot` | Butin | Carte d'extension. Crée une `Alliance` (alliance) entre son joueur et le gagnant du pli. |
| `Kraken` | Kraken | Carte d'extension. |
| `White Whale` | Baleine blanche | Carte d'extension. |
| `Creature` | — | Le Kraken ou la Baleine blanche (`Play.isCreature`). |
| `Destroyed` (trick) | pli détruit | Pli que personne ne remporte. Son `winner` désigne alors seulement qui entame le suivant. |
| `Pirate` (enum) | Rosie, Will, Rascal, Juanita, Harry | Les cinq pirates nommés ; `Pirate.of(card)` donne celui d'une carte Pirate. |
| `Power` | pouvoir | Ce qu'un pirate nommé permet à son joueur quand il gagne un pli (`PowerQuestion`). |
| `Stock` | pioche | Les cartes non distribuées d'une manche. |
| `Discard` | défausse | Cartes mises hors jeu par Will le Bandit. |
| `Wager` | mise | Les 0, 10 ou 20 points que Rascal le Flambeur fait miser. |
| `Ghost` | fantôme, Barbe Grise | Le troisième paquet d'une partie à 2 : ni pari ni score (`Game.ghostSeat`). |
| `Counter` | compteur de points | La feuille de score d'une partie jouée avec le vrai paquet (`CounterGame`). |
| `CounterEntry` | saisie | Ce qu'un joueur a fait dans une manche comptée : pari, plis, bonus, mise, changement de Harry. |
| `Draft bids` | — | Les paris d'une manche comptée, saisis avant que ses plis soient connus. |
| `Bot level` | niveau des adversaires | `easy`, `normal`, `hard`. |
| `Scoring` | calcul des points | `classic` (livret) ou `rascal` (score Rascal). |
| `Question` / `Answer` / `Event` | — | Contrat entre le moteur et ce qui le pilote (voir `docs/REFERENCE_RTAROT.md`). |
| `View` | — | Ce qu'un siège a le droit de voir de la partie. |

À éviter : « tour » ou « levée » pour un pli, « mise » pour un pari (la mise est celle de Rascal le Flambeur), « round » pour un pli.
