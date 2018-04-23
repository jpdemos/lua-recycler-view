### English
This project creates a recycler view that optimize the scroll panel by only showing the visible panels.

Without this, the game (Garry's Mod) would only be able to have about 200 panels before starting to lag, and creating 1000 panels would crash the game.

With this, you can create as many panels as your RAM support (about 200mb for 1 000 000 simple panels) without lagging.
This is done by only showing the visible panels.

The particularity of this project is that it supports panels with different size; Meaning each panels can have their own size without affecting the recycler view.

This use the delta of the scroll to determine where we are in the list, and then show and update the list panels.
The recycler view has a dynamic count of visible panels, which is determined by the size of the window/container; not by the count of entries in the list.


### Français
Ce projet crée un "recycler view", ce qui optimise un panel scrollable en affichant seulement les panels visible.

Sans ceci, le jeu (Garry's Mod) ne pourrait afficher seulement 200 panels avant de commencer à avoir des problems de latences, et créer 1000 panels ferait planter le jeu.

Avec ceci, vous êtes limité uniquement par la taille de votre RAM. (Approx. 200MB pour 1 000 000 de simples panels)
Il n'y a aucun problème de latence car le recycler view n'affiche que les panels visibles.

La particularité de ce projet est qu'il supporte les panels qui ont des tailles différentes. Cela signifie que chaque panel peut avoir sa propre taille, sans que cela affecte les performances du recycler view.

Le delta du scroll est utilisé pour déterminer où nous nous situons dans la liste, pour pouvoir ensuite afficher les panels correspondants.
Le recycler view à un nombre de panels visible dynamic, qui est déterminé par la taille de la fenêtre/containeur et non par le nombre d'entrées dans la liste.


### Preview / Apperçu

![Preview/Appercu](https://i.imgur.com/ozCJzOc.png)

In this basic list, you can see we can reach about 10 000 entries and the game hasn't crashed (and isn't lagging).
This is because only 27 entries are actually rendered. the other entries and their data are stored in RAM.
The blue entries are simply here to prove you can have different sized entries without any problems.

Dans cet apperçu basique, vous pouvez constater que nous pouvont atteindre les 10 000 entrées sans aucun souci (aucun crash, aucune latence)
C'est possible car, dans cet exemple, seuls 27 entrées sont affichées. Les autres entrées sont stockées dans la RAM.
Les entrées en bleu sont simplement là pour prouver que l'on peut avoir des entrées à taille différente sans soucis.