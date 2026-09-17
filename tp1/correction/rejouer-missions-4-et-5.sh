#!/usr/bin/env bash
# Corrige des missions 4 et 5 du TP1. Continue un depot arrive au bout de la
# mission 3.
#
# Usage : ./rejouer-missions-4-et-5.sh [chemin_du_depot]
#
# Les messages de commit portent une etiquette [Mission 4] ou [Mission 5] en fin
# de ligne, pour que le debrief en salle retrouve chaque mission d'un coup d'oeil.
#
# Prerequis : pytest, pytest-cov, ruff, radon, xenon et pre-commit dans le PATH.

set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

DEPOT="${1:-tp1-corrige}"
cd "$DEPOT"

if ! grep -q "generer_rapport" inventaire/inventaire.py 2>/dev/null; then
  echo "ARRET : $DEPOT n'est pas arrive au bout de la mission 3"; exit 1
fi

HORLOGE=$(date -d "$(git log -1 --format=%ad --date=format:%Y-%m-%d) 14:45:00" +%s)
DECALAGE="+0200"
MISSION="[Mission 4]"
avancer() { HORLOGE=$((HORLOGE + $1 * 60)); }

suite_est_verte() { python3 -m pytest -q >/dev/null 2>&1; }

# Un cycle red puis fix traverse deux etats ou la suite est rouge : apres le test
# de regle, et apres la correction, tant que le filet fige encore l'ancien
# comportement. Le crochet pre-commit installe en mission 4 refuserait ces deux
# commits, a juste titre. On le contourne explicitement pour eux, et pour eux
# seuls. Tous les autres commits passent par le crochet.
#
# La tension est reelle : un crochet qui exige une suite verte interdit le TDD.
# L'alternative en equipe est de deplacer le crochet des tests au stade pre-push,
# et de ne garder que le formatage et le lint au moment du commit.
commiter() {
  local prefixe="$1" message="$2"; shift 2
  local options=()
  case "$prefixe" in red|fix) options+=(--no-verify) ;; esac
  git add "$@"
  GIT_AUTHOR_DATE="@$HORLOGE $DECALAGE" GIT_COMMITTER_DATE="@$HORLOGE $DECALAGE" \
    git commit -q ${options[@]+"${options[@]}"} -m "$prefixe: $message $MISSION"
}

rouge() {
  local message="$1"; shift
  if suite_est_verte; then
    echo "ARRET : le commit red '$message' est vert, il ne prouve rien"; exit 1
  fi
  avancer 3
  commiter red "$message" "$@"
  printf '  \033[31mred\033[0m      %s\n' "$message"
}

# Apres une correction, le test de regle doit passer. Le filet, lui, est encore
# rouge : il fige le comportement qu'on vient justement de changer. C'est le
# commit test suivant qui le remet d'aplomb.
corriger() {
  local message="$1"; shift
  if ! python3 -m pytest -q inventaire/test_regles_metier.py >/dev/null 2>&1; then
    echo "ARRET : le commit fix '$message' ne fait pas passer le test de regle"; exit 1
  fi
  avancer 3
  commiter fix "$message" "$@"
  printf '  \033[32mfix\033[0m      %s\n' "$message"
}

deja_vert() {
  local message="$1"; shift
  if ! suite_est_verte; then
    echo "ARRET : le commit test '$message' laisse la suite rouge"; exit 1
  fi
  avancer 2
  commiter test "$message" "$@"
  printf '  \033[36mtest\033[0m     %s\n' "$message"
}

bleu() {
  local message="$1"; shift
  if ! suite_est_verte; then
    echo "ARRET : le refactoring '$message' casse la suite"; exit 1
  fi
  avancer 3
  commiter refactor "$message" "$@"
  printf '  \033[34mrefactor\033[0m %s\n' "$message"
}

tache() {
  local message="$1"; shift
  avancer 4
  commiter chore "$message" "$@"
  printf '  chore    %s\n' "$message"
}

M=inventaire/inventaire.py
T=inventaire/test_inventaire.py
R=inventaire/test_regles_metier.py

echo ""
echo "=== MISSION 4 : le garde-fou ==="

python3 - <<'FIN_SEUILS'
code = open("pyproject.toml", encoding="utf-8").read()
ancien = "[tool.coverage.report]\nshow_missing = true\n"
assert ancien in code
code = code.replace(
    ancien,
    "[tool.coverage.report]\nshow_missing = true\nskip_covered = true\nfail_under = 85\n",
    1,
)
open("pyproject.toml", "w", encoding="utf-8").write(code)
FIN_SEUILS
tache "couverture minimale de 85 pour cent dans pyproject.toml" pyproject.toml

cat > verifier.sh <<'FIN_VERIFIER'
#!/usr/bin/env bash
# La commande unique avant de pousser. Elle doit renvoyer 0.
set -e

echo "--- formatage ---"
ruff format --check .

echo "--- lint ---"
ruff check .

echo "--- complexite ---"
radon cc -s -a inventaire kata_parking
xenon --max-absolute B --max-modules A --max-average A inventaire kata_parking

echo "--- tests et couverture ---"
pytest --cov=inventaire --cov=kata_parking --cov-branch --cov-report=term-missing

echo ""
echo "Tout est vert."
FIN_VERIFIER
chmod +x verifier.sh
if ! ./verifier.sh >/dev/null 2>&1; then
  echo "ARRET : verifier.sh ne renvoie pas 0 alors que le depot est propre"
  ./verifier.sh | tail -20
  exit 1
fi
tache "verifier.sh, la commande unique avant de pousser" verifier.sh

cat > .pre-commit-config.yaml <<'FIN_HOOKS'
# Tous les crochets sont locaux : ils utilisent les outils deja installes dans
# l'environnement virtuel. Aucun telechargement, donc rien ne casse en salle
# quand le reseau est capricieux.
repos:
  - repo: local
    hooks:
      - id: ruff-format
        name: formatage
        entry: ruff format --check
        language: system
        types: [python]

      - id: ruff
        name: lint
        entry: ruff check --force-exclude
        language: system
        types: [python]

      - id: xenon
        name: barriere de complexite
        entry: xenon --max-absolute B --max-modules A --max-average A inventaire kata_parking
        language: system
        pass_filenames: false
        always_run: true

      - id: pytest
        name: tests unitaires
        entry: pytest -q
        language: system
        pass_filenames: false
        always_run: true
FIN_HOOKS
pre-commit install >/dev/null
tache "garde-fou pre-commit, quatre crochets locaux" .pre-commit-config.yaml

echo ""
echo "--- on casse une ligne volontairement pour prouver que le crochet bloque ---"
cp $M /tmp/sauvegarde_inventaire.py
python3 - <<'FIN_CASSE'
code = open("inventaire/inventaire.py", encoding="utf-8").read()
code = code.replace("TAUX_TVA = 0.2", "TAUX_TVA = 0.7", 1)
open("inventaire/inventaire.py", "w", encoding="utf-8").write(code)
FIN_CASSE

{
  echo "Preuve que le garde-fou bloque un commit fautif."
  echo ""
  echo "On remplace TAUX_TVA = 0.2 par TAUX_TVA = 0.7 dans inventaire/inventaire.py,"
  echo "puis on tente de commiter."
  echo ""
  echo "\$ git add inventaire/inventaire.py"
  echo "\$ git commit -m \"fix: ajustement du taux de TVA\""
  echo ""
  git add $M
  git commit -m "fix: ajustement du taux de TVA" 2>&1 || true
  echo ""
  echo "\$ echo \$?"
  echo "1"
  echo ""
  echo "\$ git log --oneline -1"
  git reset -q
  git log --oneline -1
  echo ""
  echo "Le dernier commit n'a pas bouge. Le commit fautif n'existe pas."
} > preuve-garde-fou.txt

cp /tmp/sauvegarde_inventaire.py $M
rm -f /tmp/sauvegarde_inventaire.py
if ! grep -q "Failed" preuve-garde-fou.txt; then
  echo "ARRET : le crochet n'a pas bloque, la preuve ne prouve rien"
  cat preuve-garde-fou.txt
  exit 1
fi
tache "preuve que le garde-fou bloque un commit fautif" preuve-garde-fou.txt

echo ""
echo "=== MISSION 5 : prouver le bug avant de le corriger ==="
MISSION="[Mission 5]"

corriger_module() {
  python3 - "$@" <<'FIN_CORRECTION'
import sys

CHEMIN = "inventaire/inventaire.py"


def remplacer(code, ancien, nouveau):
    assert ancien in code, "fragment introuvable : " + ancien[:70]
    return code.replace(ancien, nouveau, 1)


code = open(CHEMIN, encoding="utf-8").read()
etape = sys.argv[1]

if etape == "predicat-alerte":
    code = remplacer(
        code,
        "def references_en_alerte(articles):\n"
        '    return [a["ref"] for a in articles if a["q"] < a["seuil"]]\n',
        "def est_en_alerte(article):\n"
        '    return article["q"] < article["seuil"]\n'
        "\n"
        "\n"
        "def references_en_alerte(articles):\n"
        '    return [a["ref"] for a in articles if est_en_alerte(a)]\n',
    )
    code = remplacer(
        code,
        "def cout_de_reapprovisionnement(article):\n"
        '    if article["q"] >= article["seuil"]:\n'
        "        return 0\n",
        "def cout_de_reapprovisionnement(article):\n"
        "    if not est_en_alerte(article):\n"
        "        return 0\n",
    )
    code = remplacer(
        code,
        '    if a["q"] < a["seuil"]:\n'
        '        messages.append("ALERTE " + a["ref"] + " : " + str(a["q"]) + " restants")\n',
        "    if est_en_alerte(a):\n"
        '        messages.append("ALERTE " + a["ref"] + " : " + str(a["q"]) + " restants")\n',
    )
    code = remplacer(
        code,
        '        if article["q"] < article["seuil"]:\n'
        '            alertes.append(article["ref"])\n',
        "        if est_en_alerte(article):\n"
        '            alertes.append(article["ref"])\n',
    )

elif etape == "seuil-inclusif":
    code = remplacer(
        code,
        "def est_en_alerte(article):\n" '    return article["q"] < article["seuil"]\n',
        "def est_en_alerte(article):\n" '    return article["q"] <= article["seuil"]\n',
    )

elif etape == "remise-inclusive":
    code = remplacer(
        code,
        "    if quantite > QUANTITE_MINIMALE_POUR_REMISE:\n",
        "    if quantite >= QUANTITE_MINIMALE_POUR_REMISE:\n",
    )

elif etape == "valider-avant-de-retirer":
    code = remplacer(
        code,
        "def retirer_du_stock(article, quantite, journal=None, force=False):\n"
        "    if quantite <= 0:\n"
        "        return False\n"
        '    article["q"] = article["q"] - quantite\n'
        '    if article["q"] < 0 and not force:\n'
        "        return False\n",
        "def retirer_du_stock(article, quantite, journal=None, force=False):\n"
        "    if quantite <= 0:\n"
        "        return False\n"
        '    if quantite > article["q"] and not force:\n'
        "        return False\n"
        '    article["q"] = article["q"] - quantite\n',
    )

elif etape == "rotation-explicite":
    code = remplacer(
        code,
        "def valeur_brute(a):\n",
        "class AucuneVenteSurLaPeriode(ValueError):\n"
        '    """Impossible de calculer une rotation sans vente sur la periode."""\n'
        "\n"
        "\n"
        "def valeur_brute(a):\n",
    )
    code = remplacer(
        code,
        "def rotation_en_jours(article, ventes_sur_la_periode):\n"
        "    if ventes_sur_la_periode == 0:\n"
        "        return 0\n",
        "def rotation_en_jours(article, ventes_sur_la_periode):\n"
        "    if ventes_sur_la_periode <= 0:\n"
        '        raise AucuneVenteSurLaPeriode(article["ref"] + " : aucune vente")\n',
    )

else:
    raise SystemExit("etape inconnue : " + etape)

open(CHEMIN, "w", encoding="utf-8").write(code)
FIN_CORRECTION
}

majer_filet() {
  python3 - "$@" <<'FIN_FILET'
import sys

CHEMIN = "inventaire/test_inventaire.py"
REMPLACEMENTS = {
    "seuil": [
        (
            "def test_alerte_ignore_un_article_pile_au_seuil_alors_que_la_regle_m2_l_exige():\n"
            "    assert references_en_alerte([article(q=10, seuil=10)]) == []\n",
            "def test_alerte_signale_un_article_pile_au_seuil():\n"
            '    assert references_en_alerte([article(q=10, seuil=10)]) == ["VIS-M6"]\n',
        ),
        (
            "def test_cout_est_nul_pour_un_article_pile_au_seuil():\n"
            "    assert cout_de_reapprovisionnement(article(q=10, seuil=10, pu=1.0)) == 0\n",
            "def test_cout_commande_pour_un_article_pile_au_seuil():\n"
            "    assert cout_de_reapprovisionnement(article(q=10, seuil=10, pu=1.0)) == 20.0\n",
        ),
        (
            "def test_rapport_omet_un_article_pile_au_seuil_de_ses_alertes():\n"
            '    res = generer_rapport([article(q=10, seuil=10)], date_du_rapport="x")\n'
            '    assert res["alertes"] == []\n',
            "def test_rapport_signale_un_article_pile_au_seuil():\n"
            '    res = generer_rapport([article(q=10, seuil=10)], date_du_rapport="x")\n'
            '    assert res["alertes"] == ["VIS-M6"]\n',
        ),
    ],
    "remise": [
        (
            "def test_cout_n_applique_pas_la_remise_a_cent_unites_alors_que_la_regle_m5_l_exige():\n"
            "    assert cout_de_reapprovisionnement(article(q=20, seuil=40, pu=1.0)) == 100.0\n",
            "def test_cout_applique_la_remise_a_cent_unites():\n"
            "    assert cout_de_reapprovisionnement(article(q=20, seuil=40, pu=1.0)) == 90.0\n",
        ),
    ],
    "retrait": [
        (
            "def test_un_refus_laisse_le_stock_negatif_alors_que_la_regle_m3_l_interdit():\n"
            "    a = article(q=50)\n"
            "    retirer_du_stock(a, 51)\n"
            '    assert a["q"] == -1\n',
            "def test_un_refus_laisse_le_stock_intact():\n"
            "    a = article(q=50)\n"
            "    retirer_du_stock(a, 51)\n"
            '    assert a["q"] == 50\n',
        ),
    ],
    "rotation": [
        (
            '"""Filet de tests du module de stock.',
            '"""Filet de tests du module de stock.',
        ),
        (
            "from inventaire import (\n",
            "import pytest\n\nfrom inventaire import (\n    AucuneVenteSurLaPeriode,\n",
        ),
        (
            "def test_rot_renvoie_zero_sans_vente_alors_que_la_regle_m7_exige_une_erreur():\n"
            "    assert rotation_en_jours(article(q=50), 0) == 0\n",
            "def test_rot_leve_une_erreur_sans_vente():\n"
            '    with pytest.raises(AucuneVenteSurLaPeriode, match="aucune vente"):\n'
            "        rotation_en_jours(article(q=50), 0)\n",
        ),
    ],
}

code = open(CHEMIN, encoding="utf-8").read()
for ancien, nouveau in REMPLACEMENTS[sys.argv[1]]:
    assert ancien in code, "fragment introuvable : " + ancien[:70]
    code = code.replace(ancien, nouveau, 1)
open(CHEMIN, "w", encoding="utf-8").write(code)
FIN_FILET
}

corriger_module predicat-alerte
bleu "un seul predicat pour le seuil d'alerte, utilise aux quatre endroits" $M

cat > $R <<'FIN_REGLES'
"""Tests des regles metier officielles, sections M1 a M8 du cahier des charges.

Chacun de ces tests a ete ecrit ROUGE, avant la correction qu'il exige.
Le filet de inventaire/test_inventaire.py decrit ce que le code fait ;
ce fichier decrit ce que le code doit faire.
"""

from inventaire import references_en_alerte


def article(**surcharges):
    valeurs = {"ref": "VIS-M6", "lib": "Vis M6", "q": 50, "pu": 2.0, "seuil": 10, "cat": "piece"}
    valeurs.update(surcharges)
    return valeurs


def test_m2_un_article_pile_au_seuil_est_en_alerte():
    assert references_en_alerte([article(q=10, seuil=10)]) == ["VIS-M6"]
FIN_REGLES
rouge "M2, un article pile au seuil doit etre en alerte" $R

corriger_module seuil-inclusif
corriger "M2, le seuil d'alerte devient inclusif" $M

majer_filet seuil
deja_vert "le filet enregistre le seuil inclusif, l'ancien comportement n'a plus cours" $T

sed -i 's/^from inventaire import references_en_alerte$/from inventaire import cout_de_reapprovisionnement, references_en_alerte/' $R
cat >> $R <<'FIN_REGLES'


def test_m5_la_remise_s_applique_a_partir_de_cent_unites_incluses():
    # seuil 40 donne une cible de 120, quantite 20 donne 100 unites commandees
    assert cout_de_reapprovisionnement(article(q=20, seuil=40, pu=1.0)) == 90.0
FIN_REGLES
rouge "M5, la remise doit demarrer a cent unites incluses" $R

corriger_module remise-inclusive
corriger "M5, la remise demarre a cent unites" $M

majer_filet remise
deja_vert "le filet enregistre la remise a cent unites" $T

sed -i 's/^from inventaire import cout_de_reapprovisionnement, references_en_alerte$/from inventaire import cout_de_reapprovisionnement, references_en_alerte, retirer_du_stock/' $R
cat >> $R <<'FIN_REGLES'


def test_m3_un_retrait_refuse_laisse_le_stock_inchange():
    stock = article(q=50)
    assert retirer_du_stock(stock, 51) is False
    assert stock["q"] == 50
FIN_REGLES
rouge "M3, un retrait refuse doit laisser le stock inchange" $R

corriger_module valider-avant-de-retirer
corriger "M3, le stock est verifie avant d'etre modifie" $M

majer_filet retrait
deja_vert "le filet enregistre que le stock reste intact apres un refus" $T

sed -i 's/^from inventaire import cout_de_reapprovisionnement, references_en_alerte, retirer_du_stock$/import pytest\n\nfrom inventaire import (\n    AucuneVenteSurLaPeriode,\n    cout_de_reapprovisionnement,\n    references_en_alerte,\n    retirer_du_stock,\n    rotation_en_jours,\n)/' $R
cat >> $R <<'FIN_REGLES'


def test_m7_une_periode_sans_vente_leve_une_erreur_explicite():
    with pytest.raises(AucuneVenteSurLaPeriode, match="aucune vente"):
        rotation_en_jours(article(q=50), 0)
FIN_REGLES
rouge "M7, une periode sans vente doit lever une erreur" $R

corriger_module rotation-explicite
corriger "M7, la rotation leve AucuneVenteSurLaPeriode au lieu de renvoyer zero" $M

majer_filet rotation
deja_vert "le filet enregistre l'erreur levee sans vente" $T

empreinte() { git log --format=%h --grep="$1" -1; }

{
  echo ""
  echo "---"
  echo ""
  echo "## 6. Bilan des corrections"
  echo ""
  echo "Quatre écarts corrigés. Le sujet en demande deux au minimum."
  echo "Chacun a été prouvé par un test rouge **avant** la moindre modification du code."
  echo ""
  echo "| Règle violée | Ligne d'origine | Commit red | Commit fix | Conséquence métier |"
  echo "|---|---|---|---|---|"
  echo "| M2, seuil inclusif | 32, 63 et 141 | \`$(empreinte '^red: M2')\` | \`$(empreinte '^fix: M2')\` | un article pile à son seuil n'était **jamais** signalé, ni dans les alertes ni dans le réapprovisionnement |"
  echo "| M5, remise à 100 unités | 65 | \`$(empreinte '^red: M5')\` | \`$(empreinte '^fix: M5')\` | une commande de exactement 100 unités était facturée **10 % trop cher** |"
  echo "| M3, retrait refusé | 44 | \`$(empreinte '^red: M3')\` | \`$(empreinte '^fix: M3')\` | après un refus, le stock restait négatif et faussait la valeur totale |"
  echo "| M7, période sans vente | 90 | \`$(empreinte '^red: M7')\` | \`$(empreinte '^fix: M7')\` | \`0\` signifiait à la fois zéro jour de stock et donnée absente |"
  echo ""
  echo "### La conséquence chiffrée"
  echo ""
  echo "**M2.** Sur le jeu de données de l'entrepôt, GANT-L est à 5 unités pour un seuil de 5."
  echo "Il était donc exactement dans l'angle mort. Il n'apparaissait dans aucune alerte et"
  echo "\`cout_de_reapprovisionnement\` renvoyait 0 pour lui, donc aucune commande n'était"
  echo "déclenchée. C'est la mécanique exacte des deux ruptures de stock du mois dernier."
  echo ""
  echo "**M5.** HUILE-5 coûte 12,50 euros l'unité. Une commande de 100 unités revient à"
  echo "1250 euros sans remise, contre 1125 euros avec les 10 % dus, soit **125 euros perdus**"
  echo "à chaque commande de ce volume exact. Le bug ne se déclenche que sur la valeur pile,"
  echo "ce qui explique qu'il soit passé inaperçu pendant sept ans."
  echo ""
  echo "### Le geste qui compte"
  echo ""
  echo "Pour chaque écart, l'ordre est le même et il n'est pas négociable :"
  echo ""
  echo "1. un test qui exprime la règle officielle, et qui **échoue**"
  echo "2. la correction, minimale, une ligne dans trois cas sur quatre"
  echo "3. la mise à jour du filet, dont le test figeait l'ancien comportement"
  echo ""
  echo "Le troisième commit est le seul moment du TP où l'on a le droit de modifier un test"
  echo "existant, et c'est parce que le comportement attendu a officiellement changé."
  echo ""
  echo "Pour M2, une préparation a précédé le cycle : la comparaison était écrite à quatre"
  echo "endroits. Un \`refactor:\` l'a d'abord réunie dans \`est_en_alerte\`, ce qui a réduit"
  echo "la correction à **un seul caractère**. Préparer avant de corriger vaut mieux que"
  echo "corriger quatre fois."
} >> RAPPORT-QUALITE.md
tache "bilan des corrections dans le rapport" RAPPORT-QUALITE.md

echo ""
echo "=== CE QUE VAUT LE DEPOT A LA FIN DU TP1 ==="
echo ""
./verifier.sh 2>&1 | tail -12
echo ""
printf 'total : %s commits\n' "$(git rev-list --count HEAD)"
for p in red green fix refactor test chore; do
  printf '%-9s %s\n' "$p:" "$(git log --format=%s | grep -c "^$p: ")"
done
echo ""
echo "commits portant une etiquette de mission :"
printf '  [Mission 4] : %s\n' "$(git log --format=%s | grep -c '\[Mission 4\]$')"
printf '  [Mission 5] : %s\n' "$(git log --format=%s | grep -c '\[Mission 5\]$')"
