# Les démonstrations du jour 2

## Préparer la machine, une fois

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install pytest pytest-cov ruff pylint radon xenon vulture mypy pre-commit
```

## Démo 1, la demande du lundi matin

Pas de dossier dédié : elle se fait **en direct sur `tp2/depart/`**, le code que les
étudiants recevront l'après-midi.

```bash
cd tp2/depart
pytest -q                    # 25 tests verts, on part de là
```

Ouvrir `facturation/tarifs.py` et `facturation/facture.py`, et montrer au tableau, sans
coder, ce qu'il faudrait toucher pour les trois demandes de la slide : une formule de
plus, un code promo de plus, un canal d'envoi de plus.

Compter à voix haute : fichiers rouverts, fonctions modifiées, tests à rejouer.

Le moment qui porte : rappeler que ce code a **complexité maximale au rang A, zéro
problème ruff et 25 tests verts**. Tous les critères du jour 1 sont satisfaits, et le
code résiste quand même.

Le détail qui fait mouche sur la demande SMS : `ClientSMTP.envoyer_sms` existe déjà, et
lève `NotImplementedError`. L'interface promettait quelque chose que l'implémentation ne
tient pas. C'est la violation de ISP, et elle est visible avant même d'avoir parlé du
principe.

## Démo 2, l'ouverture d'un point de variation

Dossier `demo-ouverture`. Le script construit un dépôt git en trois états et lance
dessus le vrai script de correction du TP2.

```bash
cd demo-ouverture
./rejouer-demo.sh
```

Ce qu'il faut montrer à l'écran, dans cet ordre :

```bash
cd ouverture-demo
git diff --numstat depart-tp2..ouverture-terminee     # l'ouverture : ça bouge
git diff --numstat ouverture-terminee..HEAD           # l'extension : ça n'ajoute
```

La deuxième commande affiche deux fichiers neufs et **une seule ligne** ajoutée dans un
fichier existant, qui est un import. C'est le résultat attendu de la mission 3.

Le compteur de tests raconte l'histoire à lui seul : 4 tests au départ, 4 après
l'ouverture, 7 après l'extension. Rien n'a été ajouté pendant qu'on ouvrait.

## Démo 3, l'inversion des dépendances

Dossier `demo-dip`. Deux fichiers au comportement identique.

```bash
cd demo-dip
pytest -q --cov=avant --cov=apres --cov-branch --cov-report=term-missing
```

Ce que la sortie montre, et qu'il faut commenter :

`avant.py` déclenche un avertissement **module never imported**. Aucun test ne peut le
charger utilement, puisque l'exercer signifie écrire un fichier. C'est la trace, dans un
rapport de couverture, d'une violation de DIP.

`apres.py` est couvert à 81 %. Les lignes manquantes sont celles de `DisqueLocal`, c'est
à dire l'adaptateur d'infrastructure. C'est **normal et sain** : la règle métier est
couverte à 100 %, et le morceau qui touche le disque sera couvert par un test
d'intégration au jour 4.

Montrer enfin `DestinationEnMemoire` : douze lignes de double, et une règle métier
devient testable pour toujours.

## Démo 4, la TVA par pays

Pas de dossier : elle se fait à l'oral sur la slide de l'acte 3, celle qui demande s'il
faut ouvrir `taux_de_tva`.

Écrire les deux versions au tableau, compter les fichiers, compter les lignes, et
demander à la salle laquelle elle préfère maintenir. Puis annoncer que le commercial
vient de signer en Espagne, et refaire voter.

C'est le moment le plus utile de la journée pour éviter le code sur-architecturé du TP.
Le barème pénalise explicitement une abstraction sans deuxième implémentation, autant
que la salle sache pourquoi.
