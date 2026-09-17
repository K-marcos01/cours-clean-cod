# Rapport de conception

Nom :
Date :
Empreinte du commit `depart-tp2` :
Empreinte du commit `ouverture-terminee` :

---

## 1. Le coût des trois demandes, avant ouverture

Rempli en mission 1, sans écrire une ligne de code.

| Demande | Fichiers à rouvrir | Fonctions à modifier | Tests existants à rejouer | Principe en cause |
|---|---|---|---|---|
| D1 niveau prealerte | | | | |
| D2 palier à 500 | | | | |
| D3 export CSV | | | | |

---

## 2. La carte des acteurs

Un acteur est une personne ou un service qui peut demander un changement.
Un fichier qui apparaît en face de deux acteurs viole SRP. Marque-le.

| Acteur | Ce qu'il peut demander | Fichiers concernés | Conflit ? |
|---|---|---|---|
| | | | |

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

Rempli en mission 3, premier temps.

| Point de variation | Technique choisie | Pourquoi celle-là et pas une plus lourde |
|---|---|---|
| | | |

Preuve que le comportement n'a pas changé pendant l'ouverture :

```bash

```

---

## 5. Le coût des trois demandes, après ouverture

Mêmes colonnes qu'en partie 1. C'est le delta qui est noté.

| Demande | Fichiers rouverts | Fichiers créés | Lignes supprimées dans l'existant | Tests neufs |
|---|---|---|---|---|
| D1 niveau prealerte | | | | |
| D2 palier à 500 | | | | |
| D3 export CSV | | | | |

Sortie de `./outils/verifier-ocp.sh` :

```

```

---

## 6. Les deux patrons, et leur procès

### Patron 1 :

**Le problème.** Trois phrases maximum. Un symptôme concret, avec un numéro de ligne.

**Le choix.** Pourquoi celui-là. Nomme le patron écarté et dis pourquoi.

**Le coût.** Combien de fichiers un lecteur doit ouvrir en plus pour suivre un appel.

**Le procès.** Pourquoi tu aurais pu ne pas le faire. Ce paragraphe vaut autant que
les trois autres réunis.

### Patron 2 :

**Le problème.**

**Le choix.**

**Le coût.**

**Le procès.**

### Le code supprimé

Lequel des deux patrons a permis de supprimer du code, et combien de lignes :

---

## 7. La hiérarchie qui ment

| Sous-type | Contrat respecté ? | Clause brisée | Correction appliquée |
|---|---|---|---|
| | | | |

La clause brisée est l'une des trois : précondition renforcée, postcondition
affaiblie, exception nouvelle.

Empreinte du commit `test:` qui prouve la violation :

Empreinte du commit qui la corrige :
