# TP1, corrigé complet, missions 0 à 5

Le corrigé existe sous deux formes.

**La branche `tp1-corrige`** contient les 90 commits réels, avec les vraies
modifications et les vrais tests. C'est l'artefact à consulter.

**Le script de ce dossier** est ce qui a produit cette branche. Il sert à la
régénérer, à la modifier, ou à en faire une variante.

---

## Consulter la branche

Sans quitter `main` :

```bash
git fetch origin
git log --oneline origin/tp1-corrige
git show origin/tp1-corrige~6
git diff origin/tp1-corrige~7 origin/tp1-corrige~6
```

Pour l'ouvrir à côté, dans un dossier séparé, sans changer de branche :

```bash
git worktree add ../tp1-corrige tp1-corrige
cd ../tp1-corrige
pytest -q
```

Pour la supprimer ensuite :

```bash
git worktree remove ../tp1-corrige
```

Les commits sont horodatés de **9h05 à 11h40**, avec un écart médian de trois
minutes entre deux commits. Le corrigé passe donc le contrôle de rythme du script
de correction, ce qui n'était pas le cas quand tous les commits tombaient dans la
même seconde.

---

## Régénérer la branche

Il ne donne pas seulement le résultat, il donne le chemin. C'est le chemin qui est noté.

### Le lancer

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install pytest pytest-cov ruff pylint radon xenon vulture

./rejouer-missions-0-1-2.sh
cd tp1-corrige
git log --oneline
```

### Ce qu'il produit

Un dépôt git de **41 commits** pour les missions 0 à 2, **72** avec la mission 3, **90** au complet.

| Préfixe | Nombre |
|---|---|
| `chore:` | 5 |
| `red:` | 11 |
| `green:` | 11 |
| `test:` | 8 |
| `refactor:` | 6 |

Chaque commit se vérifie au moment où il est créé. Un commit `red:` dont la suite
passerait au vert arrête le script. Un commit `green:` ou `refactor:` qui casserait
la suite l'arrête aussi. Le corrigé ne peut donc pas mentir sur son propre historique.

### Ce que valent les livrables

| Mesure | Valeur |
|---|---|
| Tests du kata | 27 |
| Couverture de branches de `parking.py` | 100 % |
| Complexité maximale | A (4) |
| Complexité moyenne | A (1.83) |
| ruff | 0 problème |
| Barrière xenon | franchie |

---

## Mission 0, ce qui est attendu

Trois commits `chore:`, pas un seul gros.

Le `.gitignore` arrive **en premier**, avant tout le reste, sinon le premier commit
embarque des `__pycache__`.

Le `pyproject.toml` configure `pythonpath` pour que les tests trouvent les modules sans
qu'on ait besoin de bricoler `sys.path` dans les fichiers de test.

Il configure aussi ruff dès la mission 0. L'option `ignore = ["N818"]` mérite d'être
commentée en salle : cette règle impose un suffixe `Error` aux exceptions, ce qui est
une convention anglaise. On la désactive **explicitement**, avec un commentaire, plutôt
que de renoncer à toute la famille de règles. C'est la bonne façon de traiter une règle
qui ne s'applique pas à votre contexte.

## Mission 1, ce qui est attendu

Deux commits `chore:`, et **zéro modification du code**. Le script le vérifie lui-même :

```bash
git diff --quiet HEAD~2 HEAD -- inventaire/
```

Le rapport contient, pour chaque chiffre, la commande qui l'a produit **et** la sortie
brute de cette commande. Un chiffre sans sa commande n'est pas vérifiable.

Le point à faire passer en correction : le score pylint de 7.76 sur 10 et l'indice de
maintenabilité de rang A donnent l'impression d'un fichier correct. Ce sont les deux
chiffres qui mentent. Ceux qui disent la vérité sont la complexité de `rapport`, qui
vaut 22, et la couverture, qui vaut zéro.

Le catalogue compte quatorze odeurs, dont **sept qu'aucun outil ne détecte**. Le sujet
en demande trois. C'est là que se fait la différence entre un étudiant qui a lancé des
outils et un étudiant qui a lu le code.

## Mission 2, ce qui est attendu

Onze paires `red:` puis `green:`, huit commits `test:` et six `refactor:`.

Les huit `test:` sont importants à commenter. Ce sont les cas où le test passe du
premier coup parce que le code écrit au tour précédent couvrait déjà la situation.
Un étudiant qui n'a que des `red:` et des `green:` a probablement forcé des rouges
artificiels.

Trois moments méritent d'être montrés au tableau.

**Le passage du code en dur à la généralisation.** Le commit `green: la trente et
unieme minute coute un euro cinquante` écrit `if duree > 30: return 1.50`. C'est
volontairement faux dans le cas général. C'est le test suivant, sur 61 minutes, qui
force l'apparition de `math.ceil`.

**L'arrivée de l'arrondi.** Le commit `green: un abonne paie soixante pour cent du
montant` introduit `round(montant, 2)`. Il ne l'introduit pas par précaution : sans
lui, `1.5 * 0.6` vaut `0.8999999999999999` et le test échoue. Le test a exigé
l'arrondi, le développeur ne l'a pas anticipé.

**Le rouge de E8.** Le commit `red: une sortie anterieure a l'entree est refusee`
échoue alors qu'une exception est bien levée, parce que c'est la **mauvaise**
exception : le code passe par le contrôle de durée négative. Le `match="anterieure"`
de `pytest.raises` est ce qui rend le test exigeant. Sans lui, le test serait passé
au vert et n'aurait rien prouvé.

---

## Mission 3, ce qui est attendu

31 commits : 9 `test:` pour le filet, 20 `refactor:` pour la chirurgie, 2 `chore:`
pour le rapport. Régénérables avec `./rejouer-mission-3.sh <depot>`, qui continue un
dépôt déjà arrivé au bout de la mission 2.

### Le résultat chiffré

| Mesure | Avant | Après |
|---|---|---|
| Complexité de `rapport` | 22, rang D | 5, rang A |
| Complexité moyenne | 5.9, rang B | 2.65, rang A |
| Fonctions au-dessus du rang A | 3 | 0 |
| Tests sur le module | 0 | 44 |
| Fonctions de plus de 4 paramètres | 2 | 0 |
| Arguments par défaut mutables | 2 | 0 |
| Attrape-tout d'exception | 1 | 0 |
| `print` dans le code de calcul | 7 | 0 |
| Problèmes ruff | 14 | 0 |

### Les cinq points à faire passer en salle

**Le filet fige des comportements faux, exprès.** Quatre tests portent le nom de la
règle qu'ils violent : `test_alerte_ignore_un_article_pile_au_seuil_alors_que_la_regle_m2_l_exige`.
C'est contre-intuitif et c'est tout l'exercice. Un test de caractérisation ne juge pas,
il enregistre. Le jour où quelqu'un corrige le bug, ce test devient rouge et c'est
exactement ce qu'on veut : la correction sera vue.

**Un écart n'est pas un défaut technique.** Le corrigé distingue les deux. Le seuil
inclusif, la remise à 100 unités, le stock laissé négatif, l'erreur non levée : ce sont
des écarts par rapport à une règle métier écrite, ils sont figés et attendent la
mission 5. L'argument par défaut mutable et les `print` : aucune règle de M1 à M8 ne les
décrit, donc ce sont des défauts techniques, et la mission 3 les supprime directement.
Cette distinction évite le débat sans fin sur ce qu'on a le droit de changer.

**Le filet ne protège que ce qu'il couvre.** Le rapport le dit noir sur blanc pour trois
comportements : les `print`, que la mission impose de sortir du calcul et qu'aucun test
ne fige, et l'attrape-tout de `rot`, qui absorbait aussi des erreurs que personne n'a
jamais rencontrées. Le refactoring ne conserve que le cas documenté. C'est la limite
honnête d'un filet de caractérisation, et il vaut mieux l'énoncer que la découvrir.

**Le commit de renommage touche aussi les tests.** C'est le seul de la mission 3 dans ce
cas, et la question tombe toujours. Renommer une fonction publique oblige à mettre à jour
ses appelants, tests compris. Ce n'est pas modifier un test pour le faire passer : aucune
assertion ne change, seuls les noms appelés changent. Montrer le diff est la meilleure
réponse.

**Un test disparaît, et c'est justifié.** `test_mouv_refuse_un_type_de_mouvement_inconnu`
documentait le rejet d'une valeur invalide du drapeau `t`. Quand `mouv` est scindée en
`retirer_du_stock` et `ajouter_au_stock`, le drapeau n'existe plus, donc la branche
défensive non plus. Supprimer un test de caractérisation demande toujours une
justification écrite ; en voici une bonne.

### La séquence des 20 refactorings

Aucun ne dépasse quelques lignes. Dans l'ordre : code mort, constantes nommées,
`valeur_brute` extraite, compréhensions de liste, `sorted` à la place du tri à bulles,
duplication de `par_cat`, attrape-tout de `rot`, clause de garde de `cout`, arguments
mutables, puis cinq passes sur `rapport` pour en sortir les messages, la sélection,
l'écriture de fichier et l'affichage, et enfin les renommages et la scission de `mouv`.

C'est le rythme à montrer : `rapport` n'est pas tombée de D à A d'un coup, elle est
tombée en cinq commits dont aucun ne fait plus de dix lignes de diff.

---

## Missions 4 et 5, ce qui est attendu

18 commits, régénérables avec `./rejouer-missions-4-et-5.sh <depot>`. Leurs messages
portent une étiquette `[Mission 4]` ou `[Mission 5]` en fin de ligne, pour retrouver
chaque mission d'un coup d'oeil pendant le débrief. Les 72 premiers commits n'en ont
pas, ils sont antérieurs à cette convention.

### Mission 4, quatre commits `chore:`

Les seuils dans `pyproject.toml`, `verifier.sh`, le garde-fou `pre-commit`, et la preuve.

Les quatre crochets sont **locaux**, `language: system`. Ils utilisent les outils déjà
installés dans l'environnement virtuel, donc aucun téléchargement, donc rien ne casse en
salle quand le réseau est capricieux. Ça vaut la peine de le dire : la configuration
d'exemple du cours pointe vers des dépôts distants, celle-ci non.

`preuve-garde-fou.txt` contient une vraie sortie de terminal, capturée pendant la
génération. On y remplace `TAUX_TVA = 0.2` par `0.7`, on tente de commiter, le crochet
`tests unitaires` échoue, et `git log --oneline -1` montre que le dernier commit n'a pas
bougé. Le commit fautif n'existe pas.

### Mission 5, quatorze commits

Le sujet demande deux écarts au minimum, le corrigé en traite **quatre** : M2, M5, M3 et
M7. Chacun suit le même triptyque.

| Écart | `red:` | `fix:` | `test:` |
|---|---|---|---|
| M2, seuil inclusif | le test de règle échoue | un caractère change | le filet est mis à jour |
| M5, remise à 100 | idem | un caractère change | idem |
| M3, retrait refusé | idem | deux lignes permutées | idem |
| M7, période sans vente | idem | une exception remplace `return 0` | idem |

### Les quatre points à faire passer en salle

**On prépare avant de corriger.** Pour M2, la comparaison était écrite à quatre endroits.
Un `refactor:` la réunit d'abord dans `est_en_alerte`, ce qui réduit la correction à un
seul caractère. Ce commit de préparation arrive **avant** le test rouge, quand la suite
est encore verte. Corriger quatre fois la même chose est un signal, pas une fatalité.

**Un commit `fix:` laisse la suite rouge.** C'est contre-intuitif et c'est logique : la
correction fait passer le test de règle, et casse du même coup le test du filet qui
figeait l'ancien comportement. C'est le `test:` suivant qui remet tout au vert. Le
corrigé le vérifie explicitement : après un `fix:`, il exige que le test de règle passe,
pas que la suite entière soit verte.

**`--no-verify` est utilisé, et seulement deux fois par cycle.** Un crochet qui exige une
suite verte interdit mécaniquement le TDD. Les commits `red:` et `fix:` le contournent
donc explicitement. C'est le seul usage légitime de `--no-verify` dans ce TP, et il est
commenté dans le script. L'alternative en équipe est de déplacer les tests au stade
`pre-push` et de ne garder que le formatage et le lint au moment du commit. La question
tombera, autant avoir la réponse.

**Le garde-fou a réellement attrapé une erreur pendant la génération.** Le commit `test:`
de M7 a été refusé parce que les imports n'étaient pas triés. Ce n'est pas une anecdote :
c'est la démonstration que le crochet sert à quelque chose, sur un dépôt qu'on croyait
propre.

### Le résultat final

```
./verifier.sh
Required test coverage of 85.0% reached. Total coverage: 88.56%
75 passed
Tout est vert.
```

Et le contrôle de correction ne signale plus rien :

```
./outils/verifier-historique.sh <depot> 3
Aucun probleme bloquant detecte.
```

90 commits, 15 `red:`, 11 `green:`, 4 `fix:`, 27 `refactor:`, 21 `test:`, 12 `chore:`,
étalés sur 395 minutes avec un écart médian de trois minutes.

---

## Ce que le corrigé ne contient pas

Rien. Le TP1 est couvert de bout en bout.

Un seul point d'attention si vous régénérez : `pre-commit install` écrit dans
`.git/hooks/`, qui est **partagé entre le dépôt principal et ses worktrees**. Régénérez
donc les missions 4 et 5 dans un clone autonome, pas dans un `git worktree`, sinon vous
installez le crochet dans votre dépôt de cours.

```bash
git clone --branch tp1-corrige --single-branch <votre-depot> /tmp/corrige
cd /tmp/corrige && /chemin/vers/tp1/correction/rejouer-missions-4-et-5.sh .
```

### La différence avec `tp1/solution/`

`tp1/solution/` est un **état final idéalisé**, pas le résultat de cette branche.

Il va plus loin que ce que la mission 3 demande : il applique la piste bonus du sujet en
remplaçant les dictionnaires d'articles par un type dédié, il sépare le calcul du rapport
dans un module à part, et il corrige les écarts, ce qui est le travail de la mission 5.

C'est aussi le point de départ du TP2, ce qui explique pourquoi il est écrit ainsi.
La branche, elle, montre le chemin qu'un étudiant parcourt réellement en cinq heures.
