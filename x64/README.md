Fonctionnement
==============

Le projet dépend sur NASM.
Pour assembler, `make` suffit, l'éxecutable de sortie est `rpsm`
`rpsm` prend soit 2 ou 3 arguments.

`./rpsm join` attends  jusqu'à  ce  qu'il trouve  une  partie  sur  le
réseau, que les joueurs le rejoigne,  et laisse le joueur jouer jusque
à la fin.

`./rpsm create [n]` crée une partie  pour n joueurs, et quitte lorsque
les n joueurs on pu se rejoindre.

Si le code est trop verbeux, voici une explication de l'architecture.

Tout  le  fonctionnement  client/serveur  est assuré  par  une  boucle
d'évènements (implémentée  dans `event_loop.s`).  CAD que  chaque file
descriptor est  associé à  un objet qui  possède une  fonction receive
appelée lorsqu'un evenement est disponible  sur le fd.  Ensuite chaque
objet nécéssaire "s'abonne" à la  boucle d'évènement pour être pris en
compte.  (`add_source`).  Et  lorsqu'il  finit son  traitement, il  se
désabonne avec  `remove_source`. Le  programme quitte lorsqu'il  n'y a
plus de sources pour émettre d'évènements.  Il  y a des cas où on veut
pouvoir représenter  un évènement qui  se produit, mais qui  n'est pas
associé  à  un  file  descriptor.  Pour  représenter  ceci,  j'utilise
signalfd pour crée  un filedescriptor qui représente  l'état du signal
SIGALRM.

Typiquement coté client, le programme commence avec 3 sources, une qui
attends la disponibilité de paquets udp broadcast, dans `client_udp.s`
Une autre source  qui attend des connections tcp sur  un port d'écoute
attribué par  le système  `client_udp.s`.  La  dernière source  est la
logique  de  jeu  elle  même,  qui attends  qu'une  des  deux  sources
précédentes émettent le  signal SIGALRM sur le  processus courant pour
commencer à s'éxecuter, implémenté dans `rps.s`.

Quand l'écouteur UDP trouve un serveur, il crée une nouvelle source
basée sur le fd de la socket de connection client/serveur (son code
est aussi dans `client_udp.s`) et se supprime lui même de la boucle
d'évènement.

Coté serveur,  on commence avec  deux sources, et aucune  source n'est
nécessaire par la suite.  Il y  a l'émetteur de paquets UDP broadcast,
qui est basé  sur l'émission d'un signal SIGALRM  toutes les secondes.
Et il y a l'écouteur TCP,  qui attend évidemment une connection sur sa
socket. les deux sont implémentés dans `host.s`


Au niveau des autres fichiers non mentionnés jusqu'ici:
- `hash_data.s`, la fonction de hashage définie dans le protocole.
- `input.s`,  fonctions  qui  permette de  demander  à  l'utilisateur
   d'entrer un choix pour pierre papier ciseaux
- `main.s`, le point d'entrée...
- `sig.s`, définition d'un sigset_t représentant le signal SIGALRM
- `utils.s`, des fonctions utilitaires standard en C, (memcpy, memcmp,
   strcmp, utoa, puts, atoi...)