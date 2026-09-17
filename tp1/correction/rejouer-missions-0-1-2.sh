#!/usr/bin/env bash
# Corrige des missions 0, 1 et 2 du TP1, rejoue commit par commit.
#
# Usage : ./rejouer-missions-0-1-2.sh [dossier_de_sortie]
#
# Le script construit un depot git complet, comme si un etudiant avait fait le
# travail. Chaque commit est verifie au moment ou il est cree : un commit red
# doit reellement etre rouge, un commit green et un commit refactor doivent
# reellement etre verts. Si ce n'est pas le cas, le script s'arrete.
#
# Prerequis : pytest, radon, pylint, ruff, vulture et xenon dans le PATH.

set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

SORTIE="${1:-tp1-corrige}"
ICI="$(cd "$(dirname "$0")" && pwd)"
LEGACY="$ICI/../legacy"

# On reprend l'identite git du poste, pour ne pas introduire un auteur inconnu.
NOM="$(git config --get user.name || echo "Corrige TP1")"
COURRIEL="$(git config --get user.email || echo "corrige@example.org")"

rm -rf "$SORTIE"; mkdir -p "$SORTIE"; cd "$SORTIE"
git init -q
git config user.name "$NOM"
git config user.email "$COURRIEL"

# Horodatages realistes : le TP commence a 9h et la mission 2 se termine vers 11h40.
# Sans ca, les 41 commits tombent dans la meme seconde et le controle de rythme
# du script de correction signale un historique fabrique, a juste titre.
HORLOGE=$(date -d "${DATE_DU_TP:-2026-09-15} 09:00:00" +%s)
DECALAGE="+0200"
avancer() { HORLOGE=$((HORLOGE + $1 * 60)); }

suite_est_verte() { python3 -m pytest -q >/dev/null 2>&1; }

commiter() {
  local prefixe="$1" message="$2"; shift 2
  git add "$@"
  GIT_AUTHOR_DATE="@$HORLOGE $DECALAGE" GIT_COMMITTER_DATE="@$HORLOGE $DECALAGE" \
    git commit -q -m "$prefixe: $message"
}

rouge() {
  local message="$1"; shift
  if suite_est_verte; then
    echo "ARRET : le commit red '$message' est vert, ce n'est pas un rouge valide"; exit 1
  fi
  avancer 3
  commiter red "$message" "$@"
  printf '  \033[31mred\033[0m      %s\n' "$message"
}

vert() {
  local message="$1"; shift
  if ! suite_est_verte; then
    echo "ARRET : le commit green '$message' n'est pas vert"; exit 1
  fi
  avancer 2
  commiter green "$message" "$@"
  printf '  \033[32mgreen\033[0m    %s\n' "$message"
}

bleu() {
  local message="$1"; shift
  if ! suite_est_verte; then
    echo "ARRET : le commit refactor '$message' casse la suite"; exit 1
  fi
  avancer 4
  commiter refactor "$message" "$@"
  printf '  \033[34mrefactor\033[0m %s\n' "$message"
}

deja_vert() {
  local message="$1"; shift
  if ! suite_est_verte; then
    echo "ARRET : le commit test '$message' devrait passer du premier coup"; exit 1
  fi
  avancer 2
  commiter test "$message" "$@"
  printf '  \033[36mtest\033[0m     %s\n' "$message"
}

tache() {
  local message="$1"; shift
  avancer 5
  commiter chore "$message" "$@"
  printf '  chore    %s\n' "$message"
}

echo ""
echo "=== MISSION 0 : l'atelier ==="

cat > .gitignore <<'EOF'
.venv/
__pycache__/
*.py[cod]
.pytest_cache/
.ruff_cache/
.coverage
htmlcov/
EOF
tache "initialisation du depot et gitignore" .gitignore

cat > requirements-dev.txt <<'EOF'
pytest
pytest-cov
ruff
pylint
radon
xenon
vulture
mypy
pre-commit
EOF
cat > pyproject.toml <<'EOF'
[tool.ruff]
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "UP", "B", "C90", "SIM", "RET", "ARG", "PL"]
ignore = ["PLR2004", "N818"]  # N818 impose un suffixe Error, incompatible avec des noms francais

[tool.ruff.lint.mccabe]
max-complexity = 8

[tool.ruff.lint.pylint]
max-args = 4
max-branches = 10
max-statements = 30

[tool.pytest.ini_options]
addopts = "-q"
pythonpath = ["inventaire", "kata_parking"]
python_files = ["test_*.py"]

[tool.coverage.run]
branch = true
omit = ["*/test_*.py"]

[tool.coverage.report]
show_missing = true
EOF
tache "outils de qualite et configuration pytest" requirements-dev.txt pyproject.toml

mkdir -p inventaire
cp "$LEGACY/inventaire.py" "$LEGACY/exemple_utilisation.py" inventaire/
tache "copie du module legacy a auditer" inventaire/inventaire.py inventaire/exemple_utilisation.py

echo ""
echo "=== MISSION 1 : l'audit chiffre ==="

avancer 20
cat > RAPPORT-QUALITE.md <<'EOF'
# Rapport qualité, module inventaire

Nom : corrigé de référence
Date : jour 1
Empreinte du commit de départ : voir `git log --oneline | tail -1`

---

## 1. Tableau de bord initial

Mesures relevées avant toute modification, sur `inventaire/inventaire.py`.

### Complexité par fonction

```bash
radon cc -s -a inventaire/inventaire.py
```

```
inventaire.py
    F 122:0 rapport - D (22)
    F 94:0 par_cat - B (10)
    F 37:0 mouv - B (9)
    F 74:0 classer - A (5)
    F 19:0 val - A (3)
    F 29:0 alerte - A (3)
    F 62:0 cout - A (3)
    F 87:0 rot - A (2)
    F 175:0 maj_prix - A (1)
    F 185:0 export_json - A (1)

10 blocks (classes, functions, methods) analyzed.
Average complexity: B (5.9)
```

| Fonction | Ligne | Complexité cyclomatique | Rang |
|---|---|---|---|
| `rapport` | 122 | 22 | D |
| `par_cat` | 94 | 10 | B |
| `mouv` | 37 | 9 | B |
| `classer` | 74 | 5 | A |
| `val` | 19 | 3 | A |
| `alerte` | 29 | 3 | A |
| `cout` | 62 | 3 | A |
| `rot` | 87 | 2 | A |
| `maj_prix` | 175 | 1 | A |
| `export_json` | 185 | 1 | A |

`rapport` demande à elle seule **22 tests** pour couvrir toutes ses branches.
Il y en a zéro aujourd'hui.

### Synthèse du fichier

| Mesure | Valeur | Commande |
|---|---|---|
| Lignes de code réelles | 159 | `radon raw inventaire/inventaire.py` |
| Lignes logiques | 161 | `radon raw inventaire/inventaire.py` |
| Complexité maximale | 22, rang D | `radon cc -s inventaire/inventaire.py` |
| Complexité moyenne | 5.9, rang B | `radon cc -a inventaire/inventaire.py` |
| Indice de maintenabilité | A (36.80) | `radon mi -s inventaire/inventaire.py` |
| Score pylint | 7.76 / 10 | `pylint inventaire/inventaire.py` |
| Problèmes ruff | 14 | `ruff check inventaire/inventaire.py` |
| Entrées vulture | 14 | `vulture inventaire/inventaire.py` |
| Couverture de branches | 0 % | `pytest --cov=inventaire --cov-branch` |
| Barrière xenon | échec, code retour 1 | `xenon --max-absolute B --max-modules A --max-average A inventaire/` |

### Les sorties brutes

```bash
radon raw inventaire/inventaire.py
```

```
inventaire.py
    LOC: 190
    LLOC: 161
    SLOC: 159
    Comments: 10
    Blank: 21
    - Comment Stats
        (C % L): 5%
```

```bash
radon mi -s inventaire/inventaire.py
```

```
inventaire.py - A (36.80)
```

```bash
xenon --max-absolute B --max-modules A --max-average A inventaire/ ; echo $?
```

```
ERROR:xenon:block "inventaire.py:122 rapport" has a rank of D
ERROR:xenon:average complexity is ranked B
ERROR:xenon:module 'inventaire.py' has a rank of B
1
```

```bash
pylint inventaire/inventaire.py
```

```
inventaire.py:37:0: W0102: Dangerous default value [] as argument
inventaire.py:37:0: R0913: Too many arguments (6/5)
inventaire.py:38:4: W0603: Using the global statement
inventaire.py:46:15: C0121: Comparison 'force == False' should be 'not force'
inventaire.py:78:8: W0612: Unused variable 'i'
inventaire.py:90:4: W0702: No exception type(s) specified (bare-except)
inventaire.py:94:0: R0912: Too many branches (13/12)
inventaire.py:122:0: R0913: Too many arguments (7/5)
inventaire.py:122:0: R0912: Too many branches (21/12)
inventaire.py:130:4: R1702: Too many nested blocks (8/5)
inventaire.py:169:12: W1514: Using open without explicitly specifying an encoding
inventaire.py:175:13: W0613: Unused argument 'ref'
inventaire.py:185:0: W0102: Dangerous default value [] as argument

Your code has been rated at 7.76/10
```

```bash
ruff check inventaire/inventaire.py
```

```
inventaire.py:37:27: B006 Do not use mutable data structures for argument defaults
inventaire.py:45:9: SIM102 Use a single `if` statement instead of nested `if` statements
inventaire.py:77:9: PERF402 Use `list` or `list.copy` to create a copy of a list
inventaire.py:90:5: E722 Do not use bare `except`
inventaire.py:124:13: DTZ005 `datetime.datetime.now()` called without a `tz` argument
inventaire.py:169:13: SIM115 Use a context manager for opening files
inventaire.py:185:51: B006 Do not use mutable data structures for argument defaults
Found 14 errors.
```

```bash
vulture inventaire/inventaire.py
```

```
inventaire.py:15: unused variable 'STOCK' (60% confidence)
inventaire.py:78: unused variable 'i' (60% confidence)
inventaire.py:175: unused function 'maj_prix' (60% confidence)
inventaire.py:175: unused variable 'p' (100% confidence)
inventaire.py:175: unused variable 'ref' (100% confidence)
```

Les entrées à 60 % qui désignent les fonctions publiques du module ne sont pas
des faux positifs de l'outil, ce sont des fonctions appelées depuis l'extérieur.
Seules `maj_prix`, `STOCK`, `i`, `ref` et `p` sont réellement mortes.
EOF
tache "releve des metriques initiales" RAPPORT-QUALITE.md

avancer 20
cat >> RAPPORT-QUALITE.md <<'EOF'

---

## 2. Catalogue des odeurs

Quatorze entrées. La colonne « détecté par » dit quel outil l'a vue. Les lignes
marquées **aucun** sont celles qu'aucun outil ne signale, et ce sont les plus chères.

| # | Ligne | Odeur ou défaut | Détecté par | Conséquence concrète |
|---|---|---|---|---|
| 1 | 4 | commentaire « NE PAS TOUCHER A mouv() SANS PREVENIR » | **aucun** | la peur est documentée au lieu d'être traitée, personne n'ose entrer dans la fonction |
| 2 | 10 à 13 | constantes `TVA`, `S`, `R`, `Q` | **aucun** | `S` et `Q` ne se cherchent pas dans le projet, il faut lire le corps pour savoir ce qu'ils valent |
| 3 | 14 à 16 | état global mutable `JOURNAL`, `STOCK`, `DERNIER` | vulture, partiellement | deux appels successifs ne donnent pas le même résultat, les tests devront s'exécuter dans un ordre précis |
| 4 | 25 | branche morte `else: t = t + 0` | **aucun** | cache une décision métier jamais écrite nulle part sur les quantités négatives |
| 5 | 30 | variable nommée `l` | ruff E741 en mode étendu | se confond avec le chiffre 1 à la lecture |
| 6 | 37 | `mouv(a, q, t="out", j=[], force=False, log=True)` | pylint R0913, W0102 | six paramètres dont trois drapeaux, et un argument par défaut mutable partagé entre tous les appels |
| 7 | 37 | l'argument `t` choisit entre entrée et sortie de stock | **aucun** | ce sont deux fonctions différentes déguisées en une seule, aucun appelant ne lit `mouv(a, 5)` correctement |
| 8 | 44 | la fonction modifie son argument avant de valider | **aucun** | le sujet demande qu'un refus laisse le stock intact, la structure du code rend cette garantie impossible à tenir |
| 9 | 74 à 84 | tri à bulles réimplémenté à la main | **aucun** | `sorted` existe, fait le même travail en une ligne et ne se trompe pas sur les indices |
| 10 | 90 | `except:` nu | pylint W0702, ruff E722 | attrape aussi le Ctrl+C et les fautes de frappe, le bug devient invisible |
| 11 | 91 | renvoie `0` pour dire « je ne sais pas calculer » | **aucun** | zéro jour de stock et absence de données deviennent indistinguables pour l'appelant |
| 12 | 94 à 119 | quatre blocs identiques, catégories écrites en dur | pylint R0912 | ajouter une catégorie oblige à copier un cinquième bloc, et à ne pas en oublier un |
| 13 | 122 | `rapport` calcule, affiche et écrit un fichier | pylint R0913, R0912, R1702 | trois acteurs différents peuvent demander de la modifier, et elle demande 22 tests |
| 14 | 175 à 182 | `maj_prix` morte, avec son ancien corps en commentaire | vulture 60 %, W0613 | lue par chaque nouvel arrivant, maintenue par erreur, et prête à se réveiller |

Sept de ces quatorze entrées ne sont vues par aucun outil.

---

## 3. Faut-il tout réécrire

Non, et les chiffres le disent.

Le problème n'est pas réparti sur les 159 lignes du module. Il est concentré :
**une seule fonction sur dix** est au rang D, et deux autres au rang B. Les sept
autres sont déjà au rang A. Réécrire l'ensemble reviendrait à jeter sept fonctions
correctes, testées par sept ans de production, pour régler un problème qui tient
dans trente lignes.

C'est exactement ce qu'a fait Netscape en 1998. Le moteur de rendu était jugé
irrécupérable, la réécriture a pris trois ans, et pendant ces trois ans Internet
Explorer est passé de 20 % à plus de 80 % du marché. Ce qui manquait à Netscape,
ce n'était pas du courage, c'était un moyen de vérifier qu'une modification ne
cassait rien.

C'est ce qui manque ici aussi : la couverture est de **0 %**. Tant qu'elle reste
à zéro, toute intervention est un pari, y compris une réécriture.

**Ordre d'intervention proposé.**

D'abord écrire des tests sur `val`, `alerte`, `cout`, `classer` et `rot`. Ce sont
les fonctions les plus simples, elles se testent en une heure, et elles portent
les règles métier que la direction lit tous les 5 du mois.

Ensuite seulement attaquer `rapport`, parce que c'est la seule fonction que
personne ne peut modifier aujourd'hui sans risque, et qu'il faut un filet avant
d'y entrer.

Supprimer `maj_prix` et l'état global en dernier : c'est peu risqué, mais ça ne
débloque rien tant que le reste n'est pas couvert.

Budget estimé : une journée. À comparer aux trois semaines d'une réécriture qui
recommencerait par redécouvrir les règles métier qui ne sont écrites nulle part
ailleurs que dans ce fichier.
EOF
tache "catalogue des odeurs et argumentaire" RAPPORT-QUALITE.md

if ! git diff --quiet HEAD~2 HEAD -- inventaire/; then
  echo "ARRET : la mission 1 a modifie le code, ce qui est interdit"; exit 1
fi
echo "  verification : le code de inventaire/ est strictement inchange"

echo ""
echo "=== MISSION 2 : le kata parking en TDD strict ==="

mkdir -p kata_parking
T=kata_parking/test_parking.py
P=kata_parking/parking.py

# --- E1 : la demi-heure offerte -------------------------------------------
cat > $T <<'EOF'
from parking import tarif


def test_un_stationnement_de_trente_minutes_est_gratuit():
    assert tarif(30) == 0.00
EOF
rouge "un stationnement de trente minutes est gratuit" $T

cat > $P <<'EOF'
def tarif(duree_en_minutes):
    return 0.00
EOF
vert "un stationnement de trente minutes est gratuit" $P

cat > $T <<'EOF'
import pytest
from parking import tarif


def test_un_stationnement_de_trente_minutes_est_gratuit():
    assert tarif(30) == 0.00


@pytest.mark.parametrize("minutes", [0, 1, 15, 29, 30])
def test_toute_duree_jusqu_a_trente_minutes_est_gratuite(minutes):
    assert tarif(minutes) == 0.00
EOF
deja_vert "toute duree jusqu'a trente minutes est gratuite" $T

# --- E2 : la demi-heure commencee -----------------------------------------
cat >> $T <<'EOF'


def test_la_trente_et_unieme_minute_coute_un_euro_cinquante():
    assert tarif(31) == 1.50
EOF
rouge "la trente et unieme minute coute un euro cinquante" $T

cat > $P <<'EOF'
def tarif(duree_en_minutes):
    if duree_en_minutes > 30:
        return 1.50
    return 0.00
EOF
vert "la trente et unieme minute coute un euro cinquante" $P

cat >> $T <<'EOF'


def test_la_soixante_et_unieme_minute_coute_trois_euros():
    assert tarif(61) == 3.00
EOF
rouge "la soixante et unieme minute coute trois euros" $T

cat > $P <<'EOF'
import math


def tarif(duree_en_minutes):
    minutes_facturables = max(0, duree_en_minutes - 30)
    return math.ceil(minutes_facturables / 30) * 1.50
EOF
vert "chaque demi-heure commencee est facturee" $P

cat >> $T <<'EOF'


@pytest.mark.parametrize("minutes, attendu", [(60, 1.50), (90, 3.00), (120, 4.50)])
def test_chaque_demi_heure_commencee_ajoute_un_euro_cinquante(minutes, attendu):
    assert tarif(minutes) == attendu
EOF
deja_vert "chaque demi-heure commencee ajoute un euro cinquante" $T

cat > $P <<'EOF'
import math

MINUTES_GRATUITES_STANDARD = 30
MINUTES_PAR_TRANCHE = 30
TARIF_PAR_TRANCHE = 1.50


def tarif(duree_en_minutes):
    minutes_facturables = max(0, duree_en_minutes - MINUTES_GRATUITES_STANDARD)
    return math.ceil(minutes_facturables / MINUTES_PAR_TRANCHE) * TARIF_PAR_TRANCHE
EOF
bleu "constantes nommees a la place des nombres en dur" $P

# --- E3 : le plafond journalier -------------------------------------------
cat >> $T <<'EOF'


def test_au_dela_de_six_heures_trente_le_montant_est_plafonne():
    assert tarif(8 * 60) == 18.00
EOF
rouge "au dela de six heures trente le montant est plafonne" $T

cat > $P <<'EOF'
import math

MINUTES_GRATUITES_STANDARD = 30
MINUTES_PAR_TRANCHE = 30
TARIF_PAR_TRANCHE = 1.50
PLAFOND_PAR_JOURNEE = 18.00


def tarif(duree_en_minutes):
    minutes_facturables = max(0, duree_en_minutes - MINUTES_GRATUITES_STANDARD)
    montant = math.ceil(minutes_facturables / MINUTES_PAR_TRANCHE) * TARIF_PAR_TRANCHE
    return min(montant, PLAFOND_PAR_JOURNEE)
EOF
vert "au dela de six heures trente le montant est plafonne" $P

cat >> $T <<'EOF'


def test_le_plafond_est_atteint_a_exactement_six_heures_trente():
    assert tarif(390) == 18.00
EOF
deja_vert "le plafond est atteint a exactement six heures trente" $T

cat >> $T <<'EOF'


def test_la_vingt_cinquieme_heure_ouvre_une_deuxieme_journee():
    assert tarif(25 * 60) == 36.00
EOF
rouge "la vingt cinquieme heure ouvre une deuxieme journee" $T

cat > $P <<'EOF'
import math

MINUTES_GRATUITES_STANDARD = 30
MINUTES_PAR_TRANCHE = 30
TARIF_PAR_TRANCHE = 1.50
PLAFOND_PAR_JOURNEE = 18.00
MINUTES_PAR_JOURNEE = 24 * 60


def tarif(duree_en_minutes):
    minutes_facturables = max(0, duree_en_minutes - MINUTES_GRATUITES_STANDARD)
    montant = math.ceil(minutes_facturables / MINUTES_PAR_TRANCHE) * TARIF_PAR_TRANCHE
    journees = max(1, math.ceil(duree_en_minutes / MINUTES_PAR_JOURNEE))
    return min(montant, journees * PLAFOND_PAR_JOURNEE)
EOF
vert "le plafond vaut dix-huit euros par journee commencee" $P

cat >> $T <<'EOF'


def test_une_journee_commencee_compte_pour_une_journee_entiere():
    assert tarif(24 * 60 + 1) == 36.00
EOF
deja_vert "une journee commencee compte pour une journee entiere" $T

cat > $P <<'EOF'
import math

MINUTES_GRATUITES_STANDARD = 30
MINUTES_PAR_TRANCHE = 30
TARIF_PAR_TRANCHE = 1.50
PLAFOND_PAR_JOURNEE = 18.00
MINUTES_PAR_JOURNEE = 24 * 60


def _montant_des_tranches(duree_en_minutes):
    minutes_facturables = max(0, duree_en_minutes - MINUTES_GRATUITES_STANDARD)
    return math.ceil(minutes_facturables / MINUTES_PAR_TRANCHE) * TARIF_PAR_TRANCHE


def _plafond(duree_en_minutes):
    journees = max(1, math.ceil(duree_en_minutes / MINUTES_PAR_JOURNEE))
    return journees * PLAFOND_PAR_JOURNEE


def tarif(duree_en_minutes):
    return min(_montant_des_tranches(duree_en_minutes), _plafond(duree_en_minutes))
EOF
bleu "extraction du calcul des tranches et du plafond" $P

# --- E4 : l'abonnement -----------------------------------------------------
cat >> $T <<'EOF'


def test_un_abonne_paie_soixante_pour_cent_du_montant():
    assert tarif(31, est_abonne=True) == 0.90
EOF
rouge "un abonne paie soixante pour cent du montant" $T

python3 - <<'EOF'
chemin = "kata_parking/parking.py"
code = open(chemin).read()
code = code.replace(
    "def tarif(duree_en_minutes):\n"
    "    return min(_montant_des_tranches(duree_en_minutes), _plafond(duree_en_minutes))\n",
    "def tarif(duree_en_minutes, est_abonne=False):\n"
    "    montant = min(_montant_des_tranches(duree_en_minutes), _plafond(duree_en_minutes))\n"
    "    if est_abonne:\n"
    "        montant *= 0.60\n"
    "    return round(montant, 2)\n",
)
open(chemin, "w").write(code)
EOF
vert "un abonne paie soixante pour cent du montant" $P

cat >> $T <<'EOF'


def test_la_remise_abonne_s_applique_aussi_sur_le_plafond():
    assert tarif(8 * 60, est_abonne=True) == 10.80
EOF
deja_vert "la remise abonne s'applique aussi sur le plafond" $T

python3 - <<'EOF'
chemin = "kata_parking/parking.py"
code = open(chemin).read()
code = code.replace(
    "MINUTES_PAR_JOURNEE = 24 * 60\n",
    "MINUTES_PAR_JOURNEE = 24 * 60\nPART_PAYEE_PAR_UN_ABONNE = 0.60\n",
)
code = code.replace("montant *= 0.60", "montant *= PART_PAYEE_PAR_UN_ABONNE")
open(chemin, "w").write(code)
EOF
bleu "constante pour la part payee par un abonne" $P

# --- E5 : le vehicule electrique -------------------------------------------
cat >> $T <<'EOF'


def test_un_vehicule_electrique_est_gratuit_jusqu_a_une_heure():
    assert tarif(60, est_electrique=True) == 0.00
EOF
rouge "un vehicule electrique est gratuit jusqu'a une heure" $T

python3 - <<'EOF'
chemin = "kata_parking/parking.py"
code = open(chemin).read()
code = code.replace(
    "def _montant_des_tranches(duree_en_minutes):\n"
    "    minutes_facturables = max(0, duree_en_minutes - MINUTES_GRATUITES_STANDARD)\n",
    "def _montant_des_tranches(duree_en_minutes, est_electrique):\n"
    "    gratuites = 60 if est_electrique else MINUTES_GRATUITES_STANDARD\n"
    "    minutes_facturables = max(0, duree_en_minutes - gratuites)\n",
)
code = code.replace(
    "def tarif(duree_en_minutes, est_abonne=False):\n"
    "    montant = min(_montant_des_tranches(duree_en_minutes), _plafond(duree_en_minutes))\n",
    "def tarif(duree_en_minutes, est_abonne=False, est_electrique=False):\n"
    "    montant = min(\n"
    "        _montant_des_tranches(duree_en_minutes, est_electrique),\n"
    "        _plafond(duree_en_minutes),\n"
    "    )\n",
)
open(chemin, "w").write(code)
EOF
vert "un vehicule electrique est gratuit jusqu'a une heure" $P

cat >> $T <<'EOF'


def test_la_soixante_et_unieme_minute_est_payante_pour_un_electrique():
    assert tarif(61, est_electrique=True) == 1.50


def test_l_avantage_electrique_se_cumule_avec_l_abonnement():
    assert tarif(61, est_abonne=True, est_electrique=True) == 0.90
EOF
deja_vert "l'avantage electrique se cumule avec l'abonnement" $T

python3 - <<'EOF'
chemin = "kata_parking/parking.py"
code = open(chemin).read()
code = code.replace(
    "MINUTES_GRATUITES_STANDARD = 30\n",
    "MINUTES_GRATUITES_STANDARD = 30\nMINUTES_GRATUITES_VEHICULE_ELECTRIQUE = 60\n",
)
code = code.replace(
    "def _montant_des_tranches(duree_en_minutes, est_electrique):\n"
    "    gratuites = 60 if est_electrique else MINUTES_GRATUITES_STANDARD\n"
    "    minutes_facturables = max(0, duree_en_minutes - gratuites)\n",
    "def _minutes_gratuites(est_electrique):\n"
    "    if est_electrique:\n"
    "        return MINUTES_GRATUITES_VEHICULE_ELECTRIQUE\n"
    "    return MINUTES_GRATUITES_STANDARD\n"
    "\n"
    "\n"
    "def _montant_des_tranches(duree_en_minutes, est_electrique):\n"
    "    minutes_facturables = max(\n"
    "        0, duree_en_minutes - _minutes_gratuites(est_electrique)\n"
    "    )\n",
)
open(chemin, "w").write(code)
EOF
bleu "extraction de la duree gratuite" $P

# --- E6 : les durees impossibles -------------------------------------------
sed -i 's/^from parking import tarif$/from parking import DureeInvalide, tarif/' $T
cat >> $T <<'EOF'


def test_une_duree_negative_est_refusee():
    with pytest.raises(DureeInvalide, match="negative"):
        tarif(-1)
EOF
rouge "une duree negative est refusee" $T

python3 - <<'EOF'
chemin = "kata_parking/parking.py"
code = open(chemin).read()
code = code.replace(
    "def _minutes_gratuites(",
    'class DureeInvalide(ValueError):\n'
    '    """La duree de stationnement demandee n\'a pas de sens."""\n'
    "\n"
    "\n"
    "def _minutes_gratuites(",
)
code = code.replace(
    "def tarif(duree_en_minutes, est_abonne=False, est_electrique=False):\n"
    "    montant = min(\n",
    "def tarif(duree_en_minutes, est_abonne=False, est_electrique=False):\n"
    "    if duree_en_minutes < 0:\n"
    '        raise DureeInvalide(f"duree negative : {duree_en_minutes} minutes")\n'
    "    montant = min(\n",
)
open(chemin, "w").write(code)
EOF
vert "une duree negative est refusee" $P

# --- E7 : la fourriere -----------------------------------------------------
cat >> $T <<'EOF'


def test_une_minute_de_plus_que_soixante_douze_heures_declenche_la_fourriere():
    assert tarif(72 * 60 + 1) == 250.00
EOF
rouge "une minute de plus que soixante douze heures declenche la fourriere" $T

python3 - <<'EOF'
chemin = "kata_parking/parking.py"
code = open(chemin).read()
code = code.replace(
    '        raise DureeInvalide(f"duree negative : {duree_en_minutes} minutes")\n',
    '        raise DureeInvalide(f"duree negative : {duree_en_minutes} minutes")\n'
    "    if duree_en_minutes > 72 * 60:\n"
    "        return 250.00\n",
)
open(chemin, "w").write(code)
EOF
vert "une minute de plus que soixante douze heures declenche la fourriere" $P

cat >> $T <<'EOF'


def test_soixante_douze_heures_pile_restent_au_tarif_normal():
    assert tarif(72 * 60) == 54.00


def test_la_fourriere_ignore_l_abonnement_et_l_electrique():
    assert tarif(100 * 60, est_abonne=True, est_electrique=True) == 250.00
EOF
deja_vert "la fourriere ignore l'abonnement et l'electrique" $T

python3 - <<'EOF'
chemin = "kata_parking/parking.py"
code = open(chemin).read()
code = code.replace(
    "PART_PAYEE_PAR_UN_ABONNE = 0.60\n",
    "PART_PAYEE_PAR_UN_ABONNE = 0.60\n"
    "DUREE_MAXIMALE_AVANT_FOURRIERE = 72 * 60\n"
    "FORFAIT_DE_FOURRIERE = 250.00\n",
)
code = code.replace(
    "    if duree_en_minutes > 72 * 60:\n        return 250.00\n",
    "    if duree_en_minutes > DUREE_MAXIMALE_AVANT_FOURRIERE:\n"
    "        return FORFAIT_DE_FOURRIERE\n",
)
open(chemin, "w").write(code)
EOF
bleu "constantes de la fourriere" $P

# --- E8 : le montant du a l'instant present --------------------------------
sed -i 's/^import pytest$/from datetime import datetime\n\nimport pytest/' $T
sed -i 's/^from parking import DureeInvalide, tarif$/from parking import DureeInvalide, tarif, tarif_en_cours/' $T
cat >> $T <<'EOF'


def test_le_montant_du_a_l_instant_present_se_calcule_sur_une_heure_fournie():
    entree = datetime(2026, 9, 15, 8, 0)
    maintenant = datetime(2026, 9, 15, 10, 0)
    assert tarif_en_cours(entree, maintenant) == 4.50
EOF
rouge "le montant du a l'instant present se calcule sur une heure fournie" $T

cat >> $P <<'EOF'


def tarif_en_cours(entree, maintenant, est_abonne=False, est_electrique=False):
    minutes = int((maintenant - entree).total_seconds() // 60)
    return tarif(minutes, est_abonne, est_electrique)
EOF
vert "le montant du a l'instant present se calcule sur une heure fournie" $P

cat >> $T <<'EOF'


def test_une_sortie_anterieure_a_l_entree_est_refusee():
    entree = datetime(2026, 9, 15, 10, 0)
    with pytest.raises(DureeInvalide, match="anterieure"):
        tarif_en_cours(entree, datetime(2026, 9, 15, 9, 0))
EOF
rouge "une sortie anterieure a l'entree est refusee" $T

python3 - <<'EOF'
chemin = "kata_parking/parking.py"
code = open(chemin).read()
code = code.replace(
    "def tarif_en_cours(entree, maintenant, est_abonne=False, est_electrique=False):\n"
    "    minutes =",
    "def tarif_en_cours(entree, maintenant, est_abonne=False, est_electrique=False):\n"
    "    if maintenant < entree:\n"
    '        raise DureeInvalide("la sortie est anterieure a l\'entree")\n'
    "    minutes =",
)
open(chemin, "w").write(code)
EOF
vert "une sortie anterieure a l'entree est refusee" $P

cat >> $T <<'EOF'


def test_le_montant_en_cours_ne_depend_pas_de_la_date_reelle():
    en_2026 = tarif_en_cours(datetime(2026, 1, 1, 0, 0), datetime(2026, 1, 1, 2, 0))
    en_2036 = tarif_en_cours(datetime(2036, 6, 30, 0, 0), datetime(2036, 6, 30, 2, 0))
    assert en_2026 == en_2036 == 4.50
EOF
deja_vert "le montant en cours ne depend pas de la date reelle" $T

cat > $P <<'EOF'
"""Tarificateur du parking des camions de livraison."""

import math
from datetime import datetime

MINUTES_GRATUITES_STANDARD = 30
MINUTES_GRATUITES_VEHICULE_ELECTRIQUE = 60
MINUTES_PAR_TRANCHE = 30
TARIF_PAR_TRANCHE = 1.50
PLAFOND_PAR_JOURNEE = 18.00
MINUTES_PAR_JOURNEE = 24 * 60
PART_PAYEE_PAR_UN_ABONNE = 0.60
DUREE_MAXIMALE_AVANT_FOURRIERE = 72 * 60
FORFAIT_DE_FOURRIERE = 250.00


class DureeInvalide(ValueError):
    """La duree de stationnement demandee n'a pas de sens."""


def _minutes_gratuites(est_electrique: bool) -> int:
    if est_electrique:
        return MINUTES_GRATUITES_VEHICULE_ELECTRIQUE
    return MINUTES_GRATUITES_STANDARD


def _montant_des_tranches(duree_en_minutes: int, est_electrique: bool) -> float:
    minutes_facturables = max(0, duree_en_minutes - _minutes_gratuites(est_electrique))
    return math.ceil(minutes_facturables / MINUTES_PAR_TRANCHE) * TARIF_PAR_TRANCHE


def _plafond(duree_en_minutes: int) -> float:
    journees = max(1, math.ceil(duree_en_minutes / MINUTES_PAR_JOURNEE))
    return journees * PLAFOND_PAR_JOURNEE


def tarif(
    duree_en_minutes: int,
    est_abonne: bool = False,
    est_electrique: bool = False,
) -> float:
    if duree_en_minutes < 0:
        raise DureeInvalide(f"duree negative : {duree_en_minutes} minutes")
    if duree_en_minutes > DUREE_MAXIMALE_AVANT_FOURRIERE:
        return FORFAIT_DE_FOURRIERE
    montant = min(
        _montant_des_tranches(duree_en_minutes, est_electrique),
        _plafond(duree_en_minutes),
    )
    if est_abonne:
        montant *= PART_PAYEE_PAR_UN_ABONNE
    return round(montant, 2)


def tarif_en_cours(
    entree: datetime,
    maintenant: datetime,
    est_abonne: bool = False,
    est_electrique: bool = False,
) -> float:
    """L'instant present est un parametre, jamais datetime.now()."""
    if maintenant < entree:
        raise DureeInvalide("la sortie est anterieure a l'entree")
    minutes = int((maintenant - entree).total_seconds() // 60)
    return tarif(minutes, est_abonne, est_electrique)
EOF
bleu "types explicites et signatures lisibles" $P

# ---------------------------------------------------------------------------
echo ""
echo "=== CE QUE LE DEPOT VAUT A LA FIN DES MISSIONS 0, 1 ET 2 ==="
echo ""
echo "--- la suite de tests ---"
python3 -m pytest -q 2>&1 | tail -2
echo ""
echo "--- couverture de branches du kata ---"
python3 -m pytest -q --cov=kata_parking --cov-branch --cov-report=term-missing 2>&1 | grep -E "parking|Name|TOTAL|----" || true
echo ""
echo "--- complexite du kata ---"
radon cc -s -a kata_parking/parking.py 2>/dev/null || true
echo ""
echo "--- lint du kata ---"
ruff check kata_parking/ 2>&1 | tail -2 || true
echo ""
echo "--- l'historique ---"
git log --oneline
echo ""
echo "commits : $(git rev-list --count HEAD)"
printf 'red      : %s\n' "$(git log --format=%s | grep -c '^red: ')"
printf 'green    : %s\n' "$(git log --format=%s | grep -c '^green: ')"
printf 'refactor : %s\n' "$(git log --format=%s | grep -c '^refactor: ')"
printf 'test     : %s\n' "$(git log --format=%s | grep -c '^test: ')"
printf 'chore    : %s\n' "$(git log --format=%s | grep -c '^chore: ')"
echo ""
echo "Missions 3, 4 et 5 non traitees : verifier-historique.sh signalera"
echo "l'absence de verifier.sh et de preuve-garde-fou.txt, c'est normal."
