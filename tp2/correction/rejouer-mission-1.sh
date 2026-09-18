#!/usr/bin/env bash
# Corrige des missions 0 et 1 du TP2, rejoue commit par commit.
#
# Usage : ./rejouer-mission-1.sh [dossier_de_sortie]
#
# Les messages de commit portent une etiquette en fin de ligne : [Mission 0]
# pour la prise en main, puis [Partie 1], [Partie 2] D1, D2, D3 et [Partie 3]
# pour les trois parties du diagnostic.
#
# La mission 1 interdit de modifier le code. Le script le verifie a la fin.

set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

SORTIE="${1:-tp2-corrige}"
ICI="$(cd "$(dirname "$0")" && pwd)"
DEPART="$ICI/../depart"

NOM="$(git config --get user.name || echo "Corrige TP2")"
COURRIEL="$(git config --get user.email || echo "corrige@example.org")"

rm -rf "$SORTIE"; mkdir -p "$SORTIE"; cd "$SORTIE"
git init -q
git config user.name "$NOM"
git config user.email "$COURRIEL"

HORLOGE=$(date -d "${DATE_DU_TP:-2026-09-16} 09:00:00" +%s)
DECALAGE="+0200"
avancer() { HORLOGE=$((HORLOGE + $1 * 60)); }

tache() {
  local message="$1" etiquette="$2"; shift 2
  git add "$@"
  GIT_AUTHOR_DATE="@$HORLOGE $DECALAGE" GIT_COMMITTER_DATE="@$HORLOGE $DECALAGE" \
    git commit -q -m "chore: $message $etiquette"
  printf '  chore    %-58s %s\n' "$message" "$etiquette"
}

echo ""
echo "=== MISSION 0 : prendre en main ==="

cat > .gitignore <<'EOF'
.venv/
__pycache__/
*.py[cod]
.pytest_cache/
.ruff_cache/
.coverage
htmlcov/
essai.py
EOF
avancer 5
tache "depot initialise et gitignore" "[Mission 0]" .gitignore

cp -r "$DEPART/facturation" .
cp "$DEPART/pyproject.toml" .
avancer 10
tache "code de facturation a auditer" "[Mission 0]" facturation pyproject.toml
git tag depart-tp2

if ! python3 -m pytest -q >/dev/null 2>&1; then
  echo "ARRET : la suite n'est pas verte au depart"; exit 1
fi
echo "  verification : 25 tests verts avant d'ecrire quoi que ce soit"

echo ""
echo "=== MISSION 1 : le diagnostic ==="

cat > RAPPORT-CONCEPTION.md <<'EOF'
# Rapport de conception

Nom : corrigé de référence
Date : jour 2
Empreinte du commit `depart-tp2` : voir `git rev-parse --short depart-tp2`

---

## 1. Les cinq violations

Une par principe. Le symptôme est un fait vérifiable, la conséquence décrit ce qui
arrive à quelqu'un.

| Principe | Fichier et ligne | Le symptôme observable | La conséquence concrète |
|---|---|---|---|
| **S** | `facturation/facture.py:33` | `emettre` calcule les montants (l. 44 et 45), assemble le corps du courriel (l. 48 à 57), puis déclenche l'envoi (l. 58) | trois acteurs peuvent demander de la modifier ; vérifier un montant oblige à capturer la sortie standard, comme le montrent les trois tests d'émission |
| **O** | `facturation/tarifs.py:21`, `:31` et `:39` | les **trois** fonctions de tarification enchaînent des `if` : sur la formule, sur le palier de volume, sur le code promo | chacune des trois demandes de lundi rouvre une de ces fonctions, couverte par 4, 6 et 4 tests |
| **L** | `facturation/abonnements.py:48` | `AbonnementAnnuel.resilier` lève `ResiliationImpossible` alors que le contrat écrit lignes 19 à 30 promet de renvoyer la date de fin et n'autorise que `ValueError` | tout code qui parcourt une liste d'abonnements pour résilier ceux arrivés à terme plante dès qu'un abonnement annuel s'y trouve |
| **I** | `facturation/passerelles.py:6` | `PasserelleDeCommunication` déclare 6 méthodes abstraites ; `ClientSMTP` en lève `NotImplementedError` sur 2 (l. 40 et 43) ; la facturation n'en appelle qu'une seule | un double de test doit implémenter 6 méthodes pour un besoin d'une ; et l'implémentation ment, ce qui viole aussi L |
| **D** | `facturation/facture.py:7` et `:40` | le module métier importe la classe concrète `ClientSMTP`, et appelle `datetime.now()` au milieu du calcul | impossible d'écrire un test sur le numéro de facture d'une année donnée, ni sur le destinataire sans capturer la sortie standard |

### Trois formes de la même violation

Les trois fonctions violent OCP, mais pas de la même façon, et la forme décide de la
technique d'ouverture.

| Fonction | Ce qui varie | Forme | Comment on l'ouvre |
|---|---|---|---|
| `prix_par_poste` | un catalogue de **valeurs** indépendantes | aiguillage sur une clé | un dictionnaire |
| `appliquer_code_promo` | un catalogue de **comportements** | aiguillage sur une clé, chaque cas a sa logique | un registre de fonctions |
| `taux_de_remise_volume` | une **échelle ordonnée** de seuils | cascade dont l'ordre est la règle | une table triée |

La différence tient en une phrase. Dans les deux premières, les cas sont **indépendants** :
ajouter `decouverte` ne change rien à `pro`. Dans la troisième, les cas forment une
**échelle** : l'ordre des `if` encode la règle « on teste du palier le plus haut vers le
plus bas », et cette règle n'est écrite nulle part.

### Ce que la lecture des imports suffisait à trouver

Trois des cinq se voient sans ouvrir un seul corps de fonction.

**D** se lit dans l'import de `facture.py` ligne 7 : un module métier qui importe un
module nommé `passerelles`, c'est une dépendance qui descend au lieu de monter.

**I** se lit dans la déclaration de `passerelles.py` ligne 6 : six méthodes abstraites
dans une seule interface.

**L** se lit dans la signature de `abonnements.py` ligne 48 : une méthode redéfinie dont
le corps ne fait que lever une exception.

Les deux autres demandent de lire un corps de fonction, mais un seul coup d'oeil suffit :
un enchaînement de `if` pour **O**, une méthode qui fait trois choses pour **S**.
EOF
avancer 20
tache "les cinq violations, une par principe" "[Partie 1]" RAPPORT-CONCEPTION.md

# La partie 2 est redigee demande par demande, et commitee de meme. Chaque commit
# doit pouvoir se relire seul.

cat >> RAPPORT-CONCEPTION.md <<'EOF'

---

## 2. Le coût des trois demandes, avant

Aucune ligne de code écrite pour remplir cette partie. On ouvre, on lit, on compte.

### D1, la formule `decouverte` à 4 euros par poste

| | |
|---|---|
| Fichiers à rouvrir | **2** : `abonnements.py` pour la constante, `tarifs.py` pour le prix |
| Fonctions à modifier | **1** : `prix_par_poste`, plus un bloc de constantes |
| Tests couvrant directement la fonction | **4** : `test_chaque_formule_a_son_prix_par_poste` compte pour 3 cas, plus `test_une_formule_inconnue_est_refusee` |
| Tests rejoués en pratique | **25**, parce que personne ne rejoue un sous-ensemble |

Le détail qui coûte cher : la constante `FORMULE_DECOUVERTE` doit vivre dans
`abonnements.py`, à côté des trois autres, alors que le prix vit dans `tarifs.py`. Une
seule notion métier, deux fichiers à garder en phase. Le jour où quelqu'un ajoute la
constante sans le prix, `prix_par_poste` lève `FormuleInconnue` sur une formule qui
existe pourtant au catalogue.
EOF
avancer 12
tache "cout de la demande D1, formule decouverte" "[Partie 2] D1" RAPPORT-CONCEPTION.md

cat >> RAPPORT-CONCEPTION.md <<'EOF'

### D2, le code promotionnel `RENTREE` à 10 pour cent

| | |
|---|---|
| Fichiers à rouvrir | **1** : `tarifs.py` |
| Fonctions à modifier | **1** : `appliquer_code_promo` |
| Tests couvrant directement la fonction | **4** : les deux cas de `BIENVENUE`, celui de `NOEL`, celui du code inconnu |
| Tests rejoués en pratique | **25** |

Le détail qui coûte cher : la fonction mélange deux choses. Le **routage** vers la bonne
promotion, et le **calcul** de chacune. Chaque nouveau code ajoute une branche au
routage, et le corps de `BIENVENUE` contient déjà un `if` imbriqué sur
`premiere_facture`. La complexité du routage grandit avec le nombre de codes, celle du
calcul avec les conditions de chacun, et les deux vivent au même endroit.

Autre détail : la signature impose `premiere_facture` à **tous** les codes, alors qu'un
seul s'en sert. `NOEL` reçoit un paramètre dont il n'a rien à faire, et `RENTREE` sera
dans le même cas. C'est ISP appliqué à une signature de fonction.
EOF
avancer 8
tache "cout de la demande D2, code promo RENTREE" "[Partie 2] D2" RAPPORT-CONCEPTION.md

cat >> RAPPORT-CONCEPTION.md <<'EOF'

### D3, le palier de remise à 200 postes

| | |
|---|---|
| Fichiers à rouvrir | **1** : `tarifs.py` |
| Fonctions à modifier | **1** : `taux_de_remise_volume` |
| Tests couvrant directement la fonction | **6** : le test paramétré couvre 1, 9, 10, 49, 50 et 500 postes |
| Tests rejoués en pratique | **25** |

Le détail qui coûte cher : l'ordre des `if` porte une règle métier **implicite**. Les
paliers doivent être testés du plus grand au plus petit, sinon un abonnement de 200
postes obtient 10 pour cent au lieu de 30. Rien dans le code ne dit que cet ordre est
significatif.

Bonne nouvelle mesurée : si on inverse les deux `if`, les cas à **50 et 500 postes
échouent**. Deux tests sur six attrapent la régression. Le risque n'est donc pas une
rupture silencieuse, c'est que la règle soit **invisible au lecteur**. Ouvrir ce point
de variation avec une table triée rend l'ordre explicite, et rend l'ordre d'insertion
sans importance.

### Synthèse des trois demandes

| Demande | Fichiers | Fonctions | Tests couvrant la fonction | Rejoués en pratique |
|---|---|---|---|---|
| D1 formule `decouverte` | 2 | 1 | 4 | 25 |
| D2 code promo `RENTREE` | 1 | 1 | 4 | 25 |
| D3 palier à 200 postes | 1 | 1 | 6 | 25 |

Aucune des trois n'ajoute de complexité métier. Les trois obligent à rouvrir du code qui
marchait. Et l'application ne fait que 200 lignes.
EOF
avancer 8
tache "cout de la demande D3, palier a deux cents postes" "[Partie 2] D3" RAPPORT-CONCEPTION.md

{
  echo ""
  echo "---"
  echo ""
  echo "## 3. Le graphe des dépendances"
  echo ""
  echo "Commande utilisée :"
  echo ""
  echo '```bash'
  echo 'grep -rn "^from \|^import " --include="*.py" . | grep -v test_'
  echo '```'
  echo ""
  echo "Sortie brute :"
  echo ""
  echo '```'
  grep -rn "^from \|^import " --include="*.py" . | grep -v test_ | sed 's|^\./||'
  echo '```'
  echo ""
  echo "### Lecture"
  echo ""
  echo "| Module | Ce qu'il importe | Sens | Dépendance à inverser ? |"
  echo "|---|---|---|---|"
  echo "| \`abonnements.py\` | \`dataclasses\`, \`datetime\` | bibliothèque standard | non |"
  echo "| \`tarifs.py\` | \`facturation.abonnements\` | métier vers métier | non |"
  echo "| \`passerelles.py\` | \`abc\` | bibliothèque standard | non |"
  echo "| \`facture.py\` | \`facturation.abonnements\`, \`facturation.tarifs\` | métier vers métier | non |"
  echo "| \`facture.py\` | **\`facturation.passerelles\`** | **métier vers technique** | **oui** |"
  echo "| \`facture.py\` | \`datetime.datetime\` puis \`.now()\` | dépendance cachée | **oui** |"
  echo ""
  echo "### Les deux candidats à l'inversion"
  echo ""
  echo "**L'import ligne 7 de \`facture.py\`.** C'est le seul endroit du projet où un module"
  echo "métier connaît un module technique. La flèche descend, elle doit remonter : après"
  echo "correction, ce sera \`passerelles.py\` qui connaîtra un protocole défini du côté du"
  echo "métier, et \`facture.py\` n'importera plus rien de \`passerelles\`."
  echo ""
  echo "**L'appel \`datetime.now()\` ligne 40.** Celui-là ne se voit pas dans le graphe des"
  echo "imports, parce que \`datetime\` est une bibliothèque standard et que l'import paraît"
  echo "anodin. C'est pourtant une dépendance vers le monde extérieur, au même titre qu'un"
  echo "appel réseau. Elle ne s'inverse pas par un protocole, elle se règle en faisant entrer"
  echo "la date par un paramètre."
  echo ""
  echo "### Ce que le graphe ne dit pas"
  echo ""
  echo "Il ne montre ni le couplage par **héritage** de \`AbonnementAnnuel\` vers"
  echo "\`Abonnement\`, ni le couplage par **interface** de \`ClientSMTP\` vers"
  echo "\`PasserelleDeCommunication\`. Les deux sont dans le même fichier que leur parent,"
  echo "donc invisibles à un \`grep\` sur les imports. Les violations **L** et **I** ne se"
  echo "trouvent pas par cette commande, seulement par la lecture."
} >> RAPPORT-CONCEPTION.md
avancer 15
tache "graphe des dependances et candidats a l inversion" "[Partie 3]" RAPPORT-CONCEPTION.md

echo ""
echo "=== VERIFICATION : la mission 1 n'a touche a aucun code ==="
if ! git diff --quiet depart-tp2 HEAD -- '*.py'; then
  echo "ARRET : du code Python a ete modifie pendant la mission 1"
  git diff --stat depart-tp2 HEAD -- '*.py'
  exit 1
fi
echo "  git diff depart-tp2 HEAD -- '*.py' est vide"
if ! python3 -m pytest -q >/dev/null 2>&1; then
  echo "ARRET : la suite n'est plus verte"; exit 1
fi
echo "  les 25 tests sont toujours verts"

echo ""
echo "=== L'HISTORIQUE PRODUIT ==="
git log --format="%ad  %s" --date=format:"%H:%M" --reverse
echo ""
printf 'commits : %s\n' "$(git rev-list --count HEAD)"
printf 'etiquettes : %s\n' "$(git tag | tr '\n' ' ')"
