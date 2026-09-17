# Crafting Code, 4 jours

Support de cours et travaux pratiques.

```
jour1/                  clean code, indicateurs qualité, TDD unitaire
  cours-jour1.md        support Marp, 118 slides, environ 3 h
  cours-jour1.pdf       le même, exporté
  img/                  les 6 schémas SVG
  demos/                les 4 démonstrations faites en direct
tp1/                    5 h, audit, TDD strict, refactoring sous tests
  README.md             l'énoncé des 5 missions et le barème
  legacy/               le module à auditer
  correction/           le script qui produit la branche tp1-corrige
  solution/             l'état final, 76 tests verts, point de départ du TP2
  modeles/              le squelette du rapport qualité
  outils/               vérification de l'historique TDD

jour2/                  les cinq principes SOLID
  cours-jour2.md        support Marp, 94 slides, environ 3 h
  cours-jour2.pdf       le même, exporté
  img/                  les 8 schémas SVG
  demos/                les 4 démonstrations
tp2/                    5 h, cinq violations dans un code en service
  README.md             l'énoncé des 6 missions et le barème
  depart/               l'application de facturation, 25 tests verts
  modeles/              le squelette du rapport de conception
  outils/               vérification de l'extension additive
```

## Projeter les slides

Dans VS Code avec l'extension **Marp for VS Code**, ouvrir le `.md` et lancer l'aperçu.

En ligne de commande :

```bash
cd jour1   # ou jour2
npx @marp-team/marp-cli cours-jour1.md --pdf --allow-local-files
```

`--allow-local-files` est obligatoire, les schémas sont des fichiers SVG locaux.

## Préparer les démonstrations

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install pytest pytest-cov ruff pylint radon xenon vulture mypy pre-commit
```

Le détail de chaque démo est dans `jourN/demos/README.md`.

Répéter avant le cours :

```bash
jour1/demos/demo-tdd/rejouer-demo.sh          # 13 commits rouge, vert, refactor
jour2/demos/demo-ouverture/rejouer-demo.sh    # ferme, ouvert, étendu
```

Le second se termine en lançant le vrai script de correction du TP2.

## Le corrigé du TP1

Il vit sur une branche, `tp1-corrige`, qui contient **90 commits réels** rejouant les
cinq missions comme un étudiant les aurait faites.

```bash
git log --oneline origin/tp1-corrige
git worktree add ../tp1-corrige tp1-corrige   # l'ouvrir a cote, sans quitter main
```

Chaque commit a été vérifié au moment où il a été créé : un `red:` qui passerait au
vert arrête la génération. Les commits sont horodatés de 9h05 à 14h35, écart médian
de trois minutes, sur 395 minutes. Le corrigé passe le script de correction sans
aucun signalement.

Les scripts qui produisent cette branche sont dans `tp1/correction/`, et
`tp1/correction/README.md` liste les trois moments à montrer au tableau pendant le
débrief.

## Corriger les TP

```bash
tp1/outils/verifier-historique.sh /chemin/vers/le/depot 3
tp2/outils/verifier-ocp.sh        /chemin/vers/le/depot
```

Le premier rejoue des commits `red:` tirés au hasard et vérifie qu'ils sont réellement
rouges. Le second compare les étiquettes `ouverture-terminee` et `HEAD` et refuse toute
ligne supprimée dans un fichier métier existant.

## Le fil des quatre jours

| Jour | Sujet | État |
|---|---|---|
| 1 | Craftsmanship, clean code, indicateurs, outils, TDD unitaire | fait |
| 2 | Les cinq principes SOLID, un par un, sur une application en service | fait |
| 3 | Code legacy, tests de caractérisation, coutures, odeurs, débogage | à produire |
| ? | **Patrons de conception du GoF**, objectif du module encore sans créneau | à placer |
| 4 | Stratégie de tests, intégration et bout en bout, CI/CD, éco-conception | à produire |
