#!/usr/bin/env bash
# Rejoue la mission 3 du TP2 en miniature : un point de variation ferme,
# puis ouvert, puis etendu sans qu'une seule ligne existante ne bouge.
#
# Usage : ./rejouer-demo.sh [dossier_de_sortie]
#
# A la fin, le script de correction du TP2 tourne sur le depot produit.
# C'est exactement ce que les etudiants doivent obtenir cet apres-midi.

set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

SORTIE="${1:-ouverture-demo}"
OUTILS="$(cd "$(dirname "$0")/../../../tp2/outils" && pwd)"
rm -rf "$SORTIE"; mkdir -p "$SORTIE"; cd "$SORTIE"

git init -q
git config user.name "Demo TP2"
git config user.email "demo@example.org"
printf '__pycache__/\n.pytest_cache/\n.venv/\n' > .gitignore

echo ""
echo ">>> ETAT 1 : ferme a l'extension"
mkdir -p metier && touch metier/__init__.py
cat > metier/alertes.py <<'EOF'
def niveau_alerte(quantite, seuil):
    if quantite == 0:
        return "rupture"
    if quantite * 2 <= seuil:
        return "critique"
    if quantite <= seuil:
        return "alerte"
    return "normal"
EOF
cat > test_alertes.py <<'EOF'
from metier.alertes import niveau_alerte


def test_stock_nul_est_en_rupture():
    assert niveau_alerte(0, 10) == "rupture"


def test_moitie_du_seuil_est_critique():
    assert niveau_alerte(5, 10) == "critique"


def test_au_seuil_est_en_alerte():
    assert niveau_alerte(10, 10) == "alerte"


def test_au_dessus_du_seuil_est_normal():
    assert niveau_alerte(99, 10) == "normal"
EOF
python3 -m pytest -q 2>&1 | tail -1
git add -A && git commit -q -m "chore: point de depart du tp2"
git tag depart-tp2

echo ""
echo ">>> ETAT 2 : ouvert, et le comportement n'a pas bouge"
cat > metier/alertes.py <<'EOF'
REGLES = []


def regle(nom, priorite):
    """Enregistre un niveau d'alerte. La priorite decide de l'ordre d'examen."""

    def enregistrer(predicat):
        REGLES.append((priorite, nom, predicat))
        return predicat

    return enregistrer


def niveau_alerte(quantite, seuil):
    for _, nom, convient in sorted(REGLES):
        if convient(quantite, seuil):
            return nom
    return "normal"
EOF
mkdir -p metier/regles
cat > metier/regles/__init__.py <<'EOF'
from metier.regles import base  # noqa: F401
EOF
cat > metier/regles/base.py <<'EOF'
from metier.alertes import regle


@regle("rupture", priorite=10)
def est_en_rupture(quantite, seuil):
    return quantite == 0


@regle("critique", priorite=20)
def est_critique(quantite, seuil):
    return quantite * 2 <= seuil


@regle("alerte", priorite=30)
def est_en_alerte(quantite, seuil):
    return quantite <= seuil
EOF
cat > conftest.py <<'EOF'
import metier.regles  # noqa: F401
EOF
python3 -m pytest -q 2>&1 | tail -1
echo "    les memes 4 tests passent, aucun n'a ete touche"
git add -A && git commit -q -m "refactor: ouverture du point de variation des niveaux d'alerte"
git tag ouverture-terminee

echo ""
echo ">>> ETAT 3 : etendu, sans modifier une seule ligne existante"
cat > metier/regles/prealerte.py <<'EOF'
from metier.alertes import regle


@regle("prealerte", priorite=40)
def est_en_prealerte(quantite, seuil):
    return quantite <= seuil * 2
EOF
echo "from metier.regles import prealerte  # noqa: F401" >> metier/regles/__init__.py
cat > test_prealerte.py <<'EOF'
from metier.alertes import niveau_alerte


def test_entre_le_seuil_et_son_double_est_en_prealerte():
    assert niveau_alerte(15, 10) == "prealerte"


def test_au_double_du_seuil_est_encore_en_prealerte():
    assert niveau_alerte(20, 10) == "prealerte"


def test_au_dela_du_double_redevient_normal():
    assert niveau_alerte(21, 10) == "normal"
EOF
python3 -m pytest -q 2>&1 | tail -1
git add -A && git commit -q -m "feat: niveau d'alerte prealerte"

echo ""
echo "=============================================="
echo "Ce que git a vu entre l'ouverture et maintenant :"
git diff --numstat ouverture-terminee..HEAD
echo ""
echo "Une seule ligne ajoutee dans un fichier existant, et c'est un import."
echo "=============================================="
echo ""
"$OUTILS/verifier-ocp.sh" . || true
