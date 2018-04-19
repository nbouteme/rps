Instructions
===============

Avec Monodevelop:
- Importez la solution dans monodevelop et compilez.

En ligne de commande:
- `xbuild rps_nett.sln`

Du à un problème dans la nouvelle version majeure de ncurses (6.0), il
est nécessaire si vous avez cette version de changer la variable TERM,
pour a peu près tout les programmes Mono s'éxecutant dans un terminal.

(`export TERM=xterm`)

https://github.com/mono/mono/issues/6752

L'éxecutable  de  sortie  est  dans  rps_nett/bin/Debug  et  s'appelle
`rps_nett.exe`

`node index.js` pour exécuter le programme.

`mono rps_nett.exe  join` attends jusqu'à  ce qu'il trouve  une partie
sur le réseau, que les joueurs  le rejoigne, et laisse le joueur jouer
jusque à la fin.

`mono  rps_nett.exe create  [n]` crée  une partie  pour n  joueurs, et
quitte lorsque les n joueurs on pu se rejoindre.
