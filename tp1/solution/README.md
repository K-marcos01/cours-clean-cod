# TP1, solution de référence

Ce dossier existe pour deux raisons.

Il sert de **corrigé** au TP1.

Il sert de **point de départ au TP2** à celles et ceux qui n'ont pas terminé le TP1.
Vous partez de là, vous ne partez pas de rien.

## Ce qu'il contient

```
inventaire/
  inventaire.py         le module de stock, refactorisé, bugs corrigés
  rapport.py            le calcul et la restitution du rapport mensuel
  test_inventaire.py    43 tests, un par comportement
kata_parking/
  parking.py            les 8 exigences E1 à E8
  test_parking.py       33 tests, les valeurs limites comprises
```

## Le lancer

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
pytest
```

## Ce que valent ces fichiers

| Mesure | inventaire | kata_parking |
|---|---|---|
| Tests | 43 | 33 |
| Couverture de branches | 99 % | 100 % |
| Complexité max | A (4) | A (3) |
| Complexité moyenne | A (1.90) | A (1.83) |
| ruff | 0 problème | 0 problème |

La seule ligne non couverte de tout le projet est le corps de `exporter_rapport`,
c'est-à-dire la seule fonction qui écrit sur le disque. Ce n'est pas un hasard,
et c'est le point de départ du jour 2.

## Ce que ce code n'est pas

Il est **propre**, il n'est pas **bien conçu**. C'est volontaire.

`niveau_alerte` enchaîne des `if` sur des seuils : ajouter un niveau oblige à
rouvrir la fonction. `exporter_rapport` appelle `open` directement : impossible
de le tester sans toucher au disque. Le module mélange le calcul, la mise en
forme et l'écriture : trois raisons de changer au même endroit.

Autrement dit, tout ce que le jour 1 demandait est fait, et il reste exactement
les problèmes que SOLID traite. C'est le sujet du TP2.

## Les écarts corrigés par rapport à la version de Kevin

| Règle | Ce que faisait l'original | Ce que dit la règle |
|---|---|---|
| M2 | `quantite < seuil`, un article pile au seuil passait inaperçu | au seuil, l'article est en alerte |
| M3 | le stock était décrémenté avant la vérification, puis laissé négatif | un retrait refusé laisse le stock intact |
| M5 | remise à partir de 101 unités | remise à partir de 100 incluses |
| M7 | un `except` nu renvoyait 0 quand il n'y avait aucune vente | une erreur explicite est levée |
| Divers | argument par défaut mutable `j=[]` partagé entre tous les appels | aucun état partagé implicite |
