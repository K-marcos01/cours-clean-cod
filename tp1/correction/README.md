# TP1, corrigé des missions 0, 1 et 2

Le corrigé existe sous deux formes.

**La branche `tp1-corrige`** contient les 41 commits réels, avec les vraies
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

Un dépôt git de **41 commits**.

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

## Ce que le corrigé ne contient pas

Les missions 3, 4 et 5. Le script de vérification signalera donc l'absence de
`verifier.sh` et de `preuve-garde-fou.txt`, ce qui est normal à ce stade.

```bash
git worktree add ../tp1-corrige tp1-corrige
./outils/verifier-historique.sh ../tp1-corrige 3
```

L'état final complet du TP1, missions 3 à 5 comprises, est dans `tp1/solution/`.
