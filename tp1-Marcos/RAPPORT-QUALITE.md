# Rapport qualité, module inventaire

Nom : KPANOU Marcos
Date : 16 septembre 2026
Empreinte du commit de départ :

---

## 1. Tableau de bord initial

Mesures relevées avant toute modification.

### Complexité par fonction

| Fonction | Ligne | Complexité cyclomatique | Rang |
|---           |---  |--- |---|
| rapport      | 122 | 22 | D |
| par_cat      | 94  | 10 | B |
| mouv         | 37  | 9  | B |
| classer      | 74  | 5  | A |
| val          | 19  | 3  | A |
| alerte       | 29  | 3  | A |
| cout         | 62  | 3  | A |
| rot          | 87  | 2  | A |
| maj_prix     | 175 | 1  | A |
| export_json  | 185 | 1  | A |

Commande utilisée :  


```powershell
radon cc -s -a inventaire.py
```

### Synthèse du fichier

| Mesure | Valeur | Commande |
|---|---|---|
| Lignes de code réelles | 161 | radon raw inventaire.py |
| Complexité moyenne | B (5.9) |  ` | radon cc -s -a inventaire.py |
| Indice de maintenabilité | A (36.80) | radon mi -s inventaire.py |
| Score pylint | 7.76/10 | pylint inventaire.py |
| Problèmes ruff | 14 | ruff check inventaire.py |
| Entrées vulture | 14 | vulture inventaire.py |
| Couverture de branches | 0% | pytest --cov=inventaire --cov-branch --cov-report=term-missing |
| Barrière xenon | échec (bloc D, module B) | xenon --max-absolute B --max-modules A --max-average A inventaire.py |

---

## 2. Catalogue des odeurs

Douze entrées minimum. Trois au moins doivent être invisibles pour les outils.
La colonne conséquence décrit ce qui arrive à la personne qui devra modifier ce
fichier dans six mois.

| # | Ligne | Odeur ou défaut | Détecté par | Conséquence concrète |
|---|---|---|---|---|
| 1 | 122 | Fonction trop complexe (22 chemins possibles) | radon, xenon | Trop de cas à vérifier mentalement pour modifier `rapport` sans risquer de casser un cas non testé |
| 2 | 37 | Liste par défaut partagée `j=[]` | pylint, ruff | La même liste est réutilisée à chaque appel de `mouv` ; des données s'accumulent en cachette d'un appel à l'autre |
| 3 | 185 | Liste par défaut partagée `hist=[]` | pylint, ruff | Même problème que ci-dessus dans `export_json` : l'historique s'accumule sans qu'on l'ait demandé |
| 4 | 90 | `except:` qui attrape tout | pylint, ruff | N'importe quelle erreur (même une faute de frappe dans le code) est silencieusement transformée en 0, sans message |
| 5 | 122 | 7 paramètres dont plusieurs booléens | pylint | Un appel comme `rapport(a, None, None, None, True, False)` est illisible sans revenir lire la définition de la fonction |
| 6 | 94 | 13 branches dans `par_cat` | pylint | Ajouter une catégorie d'article oblige à copier-coller un bloc entier au lieu d'ajouter une simple donnée |
| 7 | 169, 187 | Fichiers ouverts sans fermeture garantie | ruff | Si une erreur survient avant `f.close()`, le fichier reste ouvert indéfiniment |
| 8 | 122-172 | 8 niveaux de `if` imbriqués | pylint | Comprendre à quelle condition un `print` s'exécute demande de dérouler 6 conditions dans sa tête |
| 9 | 15-16, 38 | Variables globales modifiées par plusieurs fonctions (`STOCK`, `DERNIER`) | aucun outil | Deux tests qui utilisent `mouv()` peuvent s'influencer l'un l'autre selon l'ordre d'exécution |
| 10 | partout | Noms de variables sans signification (`a`, `q`, `t`, `l`, `d`) | aucun outil | Il faut lire tout le corps de chaque fonction pour deviner ce que représente une variable |
| 11 | 63, 141 | La règle "stock bas" est réécrite différemment à deux endroits | aucun outil | Corriger cette règle un jour obligera à chercher toutes ses copies à la main ; un oubli crée un bug silencieux |

---

## 3. Faut-il tout réécrire

Le score pylint (7,76/10) et l'indice de maintenabilité (rang A) donnent une impression rassurante, mais ce sont des moyennes : elles diluent le seul vrai point noir du fichier. La fonction `rapport()` concentre à elle seule une complexité de 22 (rang D), et l'outil `xenon` — conçu pour bloquer plutôt que pour noter — échoue sur ce fichier.

9 des 10 fonctions du fichier sont simples (rang A ou B). Réécrire tout le module reviendrait à jeter ce qui fonctionne déjà pour, au mieux, reproduire à l'identique la seule fonction réellement problématique.

Je propose donc un refactoring ciblé, dans cet ordre :
1. `rapport()` — le point le plus complexe et le plus risqué, à traiter en premier
2. `par_cat()` — duplication facile à corriger avec un dictionnaire de correspondance
3. `mouv()` — le plus délicat, car il touche l'état global partagé (`STOCK`, `DERNIER`)

---

## 4. Écarts constatés entre le code et les règles métier

Rempli pendant la mission 3, sans rien corriger.

| Règle | Ligne | Ce que le code fait | Ce que la règle dit |
|---|---|---|---|
|  |  |  |  |

---

## 5. Tableau de bord après refactoring

Mêmes mesures, mêmes commandes qu'en partie 1.

| Mesure | Avant | Après | Écart |
|---|---|---|---|
|  |  |  |  |

Ce que ce delta prouve, en trois phrases maximum :

---

## 6. Bugs prouvés puis corrigés

| Règle violée | Ligne d'origine | Commit red | Commit fix | Conséquence métier |
|---|---|---|---|---|
|  |  |  |  |  |

Pour au moins un de ces bugs, la conséquence est chiffrée en euros ou en ruptures de stock.
