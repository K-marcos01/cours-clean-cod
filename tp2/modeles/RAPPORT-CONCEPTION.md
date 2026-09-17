# Rapport de conception

Nom :
Date :
Empreinte du commit `depart-tp2` :
Empreinte du commit `ouverture-terminee` :

---

## 1. Les cinq violations

Une ligne par principe. Le symptôme doit être un fait vérifiable, la conséquence doit
décrire ce qui arrive à quelqu'un.

| Principe | Fichier et ligne | Le symptôme observable | La conséquence concrète |
|---|---|---|---|
| S | | | |
| O | | | |
| L | | | |
| I | | | |
| D | | | |

---

## 2. Le coût des trois demandes, avant

Rempli en mission 1, sans écrire une ligne de code.

| Demande | Fichiers à rouvrir | Fonctions à modifier | Tests existants à rejouer |
|---|---|---|---|
| D1 formule decouverte | | | |
| D2 code promo RENTREE | | | |
| D3 palier a 200 postes | | | |

---

## 3. Le graphe des dépendances

Commande utilisée :

```bash

```

| Module | Ce qu'il importe | Dépendance à inverser ? |
|---|---|---|
| | | |

Les dépendances qui vont du métier vers un détail technique :

---

## 4. Les points de variation ouverts

Rempli en mission 4, premier temps.

| Point de variation | Technique choisie | Pourquoi celle-là et pas une plus lourde |
|---|---|---|
| | | |

Preuve que le comportement n'a pas changé pendant l'ouverture :

```bash

```

---

## 5. Le coût des trois demandes, après

Mêmes demandes, mêmes colonnes. C'est le delta qui est noté.

| Demande | Fichiers rouverts | Fichiers créés | Lignes supprimées dans l'existant | Tests neufs |
|---|---|---|---|---|
| D1 formule decouverte | | | | |
| D2 code promo RENTREE | | | | |
| D3 palier a 200 postes | | | | |

Sortie de `./outils/verifier-ocp.sh` :

```

```

---

## 6. La hiérarchie qui ment

| Sous-type | Contrat respecté ? | Clause brisée | Correction appliquée |
|---|---|---|---|
| | | | |

La clause brisée est l'une des trois : précondition renforcée, postcondition affaiblie,
exception nouvelle.

Comment la règle métier a survécu à la correction :

---

## 7. Principe par principe, ce que ça m'a coûté

Trois phrases maximum par principe, dont une sur le coût de lecture.

**S.**

**O.**

**L.**

**I.**

**D.**

---

## 8. Le procès

Une abstraction que j'ai introduite et dont je ne suis pas sûr.

**Ce que j'ai fait.**

**Pourquoi j'aurais pu ne pas le faire.**

**Ce que ça coûte à quelqu'un qui lit le code pour la première fois.**

Ce paragraphe vaut autant de points que la section 7 entière. S'il ne s'écrit pas
honnêtement, c'est un résultat : retirez l'abstraction.
