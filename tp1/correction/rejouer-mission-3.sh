#!/usr/bin/env bash
# Corrige de la mission 3 du TP1. Continue un depot deja arrive au bout de la
# mission 2, il ne repart pas de zero.
#
# Usage : ./rejouer-mission-3.sh [chemin_du_depot]
#
# Comme pour les missions 0 a 2, chaque commit est verifie au moment ou il est
# cree. La regle de la mission 3 est plus stricte encore : apres le premier
# commit du filet, la suite de tests doit rester verte a chaque commit.

set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

DEPOT="${1:-tp1-corrige}"
cd "$DEPOT"

if [ ! -f inventaire/inventaire.py ]; then
  echo "ARRET : $DEPOT ne ressemble pas a un depot de TP1"; exit 1
fi

HORLOGE=$(date -d "$(git log -1 --format=%ad --date=format:%Y-%m-%d) 13:00:00" +%s)
DECALAGE="+0200"
avancer() { HORLOGE=$((HORLOGE + $1 * 60)); }

suite_est_verte() { python3 -m pytest -q >/dev/null 2>&1; }

commiter() {
  local prefixe="$1" message="$2"; shift 2
  git add "$@"
  GIT_AUTHOR_DATE="@$HORLOGE $DECALAGE" GIT_COMMITTER_DATE="@$HORLOGE $DECALAGE" \
    git commit -q -m "$prefixe: $message"
}

deja_vert() {
  local message="$1"; shift
  if ! suite_est_verte; then
    echo "ARRET : le commit test '$message' ne passe pas sur le code actuel"; exit 1
  fi
  avancer 3
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

T=inventaire/test_inventaire.py
M=inventaire/inventaire.py

echo ""
echo "=== MISSION 3, PREMIERE PARTIE : le filet ==="

cat > $T <<'EOF'
"""Filet de tests du module de stock.

Ces tests decrivent ce que le code fait AUJOURD'HUI, pas ce qu'il devrait faire.
Quand le comportement observe contredit une regle metier, la regle concernee est
citee dans le nom du test et l'ecart est reporte dans RAPPORT-QUALITE.md.
"""

from inventaire import val


def article(**surcharges):
    valeurs = {"ref": "VIS-M6", "lib": "Vis M6", "q": 50, "pu": 2.0, "seuil": 10, "cat": "piece"}
    valeurs.update(surcharges)
    return valeurs


# --- val ------------------------------------------------------------------


def test_val_d_un_stock_vide_vaut_zero():
    assert val([]) == 0


def test_val_additionne_quantite_fois_prix():
    assert val([article(q=2, pu=1.5), article(q=3, pu=2.0)]) == 9.0


def test_val_arrondit_au_centime():
    assert val([article(q=3, pu=0.333)]) == 1.0


def test_val_ignore_une_quantite_nulle():
    assert val([article(q=0, pu=5.0)]) == 0


def test_val_ignore_une_quantite_negative_au_lieu_de_la_soustraire():
    assert val([article(q=-5, pu=2.0)]) == 0
EOF
deja_vert "filet sur val" $T

sed -i 's/^from inventaire import val$/from inventaire import alerte, val/' $T
cat >> $T <<'EOF'


# --- alerte ---------------------------------------------------------------


def test_alerte_signale_un_article_sous_son_seuil():
    assert alerte([article(q=5, seuil=10)]) == ["VIS-M6"]


def test_alerte_ignore_un_article_pile_au_seuil_alors_que_la_regle_m2_l_exige():
    assert alerte([article(q=10, seuil=10)]) == []


def test_alerte_ignore_un_article_au_dessus_du_seuil():
    assert alerte([article(q=11, seuil=10)]) == []


def test_alerte_ne_renvoie_que_les_references_concernees():
    articles = [article(ref="BAS", q=1, seuil=10), article(ref="HAUT", q=99, seuil=10)]
    assert alerte(articles) == ["BAS"]
EOF
deja_vert "filet sur alerte, seuil inclusif non respecte" $T

sed -i 's/^from inventaire import alerte, val$/from inventaire import alerte, cout, val/' $T
cat >> $T <<'EOF'


# --- cout -----------------------------------------------------------------


def test_cout_est_nul_hors_alerte():
    assert cout(article(q=50, seuil=10)) == 0


def test_cout_remonte_a_trois_fois_le_seuil():
    assert cout(article(q=4, seuil=10, pu=2.0)) == 52.0


def test_cout_n_applique_pas_la_remise_a_cent_unites_alors_que_la_regle_m5_l_exige():
    assert cout(article(q=20, seuil=40, pu=1.0)) == 100.0


def test_cout_applique_la_remise_a_cent_une_unites():
    assert cout(article(q=19, seuil=40, pu=1.0)) == 90.9


def test_cout_est_nul_pour_un_article_pile_au_seuil():
    assert cout(article(q=10, seuil=10, pu=1.0)) == 0
EOF
deja_vert "filet sur cout, remise a partir de cent une unites" $T

sed -i 's/^from inventaire import alerte, cout, val$/from inventaire import alerte, classer, cout, val/' $T
cat >> $T <<'EOF'


# --- classer --------------------------------------------------------------


def test_classer_ordonne_de_la_plus_grosse_valeur_a_la_plus_petite():
    petit = article(ref="PETIT", q=1, pu=1.0)
    gros = article(ref="GROS", q=10, pu=100.0)
    moyen = article(ref="MOYEN", q=5, pu=10.0)
    classes = [a["ref"] for a in classer([petit, gros, moyen])]
    assert classes == ["GROS", "MOYEN", "PETIT"]


def test_classer_ne_reordonne_pas_la_liste_recue():
    origine = [article(ref="A", q=1), article(ref="B", q=9)]
    classer(origine)
    assert [a["ref"] for a in origine] == ["A", "B"]
EOF
deja_vert "filet sur classer" $T

sed -i 's/^from inventaire import alerte, classer, cout, val$/from inventaire import alerte, classer, cout, rot, val/' $T
cat >> $T <<'EOF'


# --- rot ------------------------------------------------------------------


def test_rot_donne_les_jours_de_stock_restants():
    assert rot(article(q=60), 30) == 60


def test_rot_arrondit_a_l_entier_inferieur():
    assert rot(article(q=14), 300) == 1


def test_rot_renvoie_zero_sans_vente_alors_que_la_regle_m7_exige_une_erreur():
    assert rot(article(q=50), 0) == 0
EOF
deja_vert "filet sur rot, zero renvoye au lieu d'une erreur" $T

sed -i 's/^from inventaire import alerte, classer, cout, rot, val$/from inventaire import alerte, classer, cout, par_cat, rot, val/' $T
cat >> $T <<'EOF'


# --- par_cat --------------------------------------------------------------


def test_par_cat_ventile_la_valeur_par_categorie():
    articles = [
        article(cat="outil", q=2, pu=10.0),
        article(cat="outil", q=1, pu=5.0),
        article(cat="piece", q=4, pu=2.5),
    ]
    assert par_cat(articles) == {"outil": 25.0, "piece": 10.0}


def test_par_cat_range_une_categorie_inconnue_dans_autre():
    assert par_cat([article(cat="drone", q=1, pu=3.0)]) == {"autre": 3.0}
EOF
deja_vert "filet sur par_cat" $T

sed -i 's/^from inventaire import alerte, classer, cout, par_cat, rot, val$/from inventaire import alerte, classer, cout, mouv, par_cat, rot, val/' $T
cat >> $T <<'EOF'


# --- mouv -----------------------------------------------------------------


def test_mouv_retire_la_quantite_demandee():
    a = article(q=50)
    assert mouv(a, 10) is True
    assert a["q"] == 40


def test_mouv_ajoute_la_quantite_demandee():
    a = article(q=50)
    assert mouv(a, 10, t="in") is True
    assert a["q"] == 60


def test_mouv_refuse_un_retrait_superieur_au_stock():
    assert mouv(article(q=50), 51) is False


def test_mouv_laisse_le_stock_negatif_apres_un_refus_alors_que_la_regle_m3_l_interdit():
    a = article(q=50)
    mouv(a, 51)
    assert a["q"] == -1


def test_mouv_refuse_une_quantite_nulle_ou_negative():
    a = article(q=50)
    assert mouv(a, 0) is False
    assert mouv(a, -3) is False
    assert a["q"] == 50


def test_mouv_refuse_un_type_de_mouvement_inconnu():
    a = article(q=50)
    assert mouv(a, 5, t="transfert") is False


def test_mouv_alimente_le_journal_fourni():
    journal = []
    mouv(article(q=50), 5, j=journal)
    assert journal[0]["ref"] == "VIS-M6"
    assert journal[0]["q"] == 5
EOF
deja_vert "filet sur mouv, stock laisse negatif apres un refus" $T

sed -i 's/^from inventaire import alerte, classer, cout, mouv, par_cat, rot, val$/from inventaire import alerte, classer, cout, export_json, mouv, par_cat, rapport, rot, val/' $T
cat >> $T <<'EOF'


# --- rapport --------------------------------------------------------------


def test_rapport_utilise_la_date_fournie():
    assert rapport([article()], d="2019-03-05")["date"] == "2019-03-05"


def test_rapport_compte_et_valorise_les_articles_retenus():
    res = rapport([article(q=10, pu=10.0)], d="x")
    assert res["nb"] == 1
    assert res["valeur"] == 100.0


def test_rapport_ajoute_la_tva_de_vingt_pour_cent():
    assert rapport([article(q=10, pu=10.0)], d="x")["ttc"] == 120.0


def test_rapport_ecarte_un_article_sans_stock():
    res = rapport([article(q=0)], d="x")
    assert res["nb"] == 0
    assert res["valeur"] == 0


def test_rapport_ecarte_un_article_sans_prix():
    res = rapport([article(pu=0)], d="x")
    assert res["nb"] == 0


def test_rapport_filtre_sur_la_categorie_demandee():
    articles = [article(ref="A", cat="outil"), article(ref="B", cat="piece")]
    assert rapport(articles, cat="outil", d="x")["nb"] == 1


def test_rapport_filtre_sur_une_quantite_minimale():
    articles = [article(ref="A", q=5), article(ref="B", q=500)]
    assert rapport(articles, seuil_min=100, d="x")["nb"] == 1


def test_rapport_omet_un_article_pile_au_seuil_de_ses_alertes():
    res = rapport([article(q=10, seuil=10)], d="x")
    assert res["alertes"] == []


def test_rapport_ne_modifie_aucun_article():
    a = article(q=50)
    rapport([a], d="x")
    assert a["q"] == 50


# --- export_json ----------------------------------------------------------


def test_export_json_ecrit_le_rapport_et_renvoie_l_historique(tmp_path):
    chemin = tmp_path / "inv.json"
    historique = export_json({"valeur": 12.5}, chemin=str(chemin), hist=[])
    assert historique == [{"valeur": 12.5}]
    assert chemin.read_text(encoding="utf-8") == '[{"valeur": 12.5}]'
EOF
deja_vert "filet sur rapport et export_json" $T

cat >> RAPPORT-QUALITE.md <<'EOF'

---

## 4. Écarts constatés entre le code et les règles métier

Relevés pendant la mission 3, en écrivant le filet. **Aucun n'est corrigé ici.**
Chacun est figé par un test dont le nom cite la règle violée, et sera traité en
mission 5 par un test rouge puis une correction.

| Règle | Ligne | Ce que le code fait | Ce que la règle dit |
|---|---|---|---|
| M2 | 32 | `a["q"] < a["seuil"]`, un article pile au seuil n'est pas signalé | au seuil, l'article est en alerte |
| M2 | 63 | `cout` utilise la même comparaison, donc ne commande rien pour un article au seuil | un article au seuil doit être réapprovisionné |
| M2 | 141 | le rapport mensuel reproduit le même écart dans sa liste d'alertes | idem |
| M3 | 44 | le stock est décrémenté **avant** la vérification, et reste négatif après un refus | un retrait refusé laisse le stock inchangé |
| M5 | 65 | `n > Q`, la remise commence à 101 unités | remise à partir de 100 unités incluses |
| M7 | 90 | un `except` nu renvoie `0` quand il n'y a aucune vente | une erreur explicite doit être levée |

### Ce que le filet ne protège pas

Trois comportements actuels ne sont **pas** couverts par le filet, et c'est un choix
assumé plutôt qu'un oubli.

**Les `print`.** Le module affiche des lignes de diagnostic pendant le calcul. La
mission 3 impose de les sortir du code de calcul. Aucun test ne les fige, sinon le
refactoring imposé deviendrait impossible. Les chaînes sont reprises telles quelles
dans les fonctions extraites, et couvertes par un test à ce moment-là.

**L'argument par défaut mutable de `mouv` et de `export_json`.** C'est un défaut
technique, pas un écart métier : aucune règle de M1 à M8 ne décrit ce que doit
contenir un journal par défaut. On le supprime en mission 3 sans passer par la
case mission 5.

**L'attrape-tout de `rot`.** Il absorbait aussi des erreurs que personne n'a jamais
rencontrées, une clé absente par exemple. Le filet ne documente que le cas d'une
période sans vente. Le refactoring ne conserve donc que celui-là, et c'est
exactement la limite d'un filet de caractérisation : il protège ce qu'il couvre,
rien de plus.
EOF
tache "ecarts constates entre le code et les regles metier" RAPPORT-QUALITE.md

echo ""
echo "=== MISSION 3, DEUXIEME PARTIE : la chirurgie ==="

patcher() {
  python3 - "$@" <<'PYEOF'
import re
import sys

CHEMIN = "inventaire/inventaire.py"


def remplacer(code, ancien, nouveau):
    assert ancien in code, "fragment introuvable : " + ancien[:60]
    return code.replace(ancien, nouveau, 1)


def remplacer_fonction(code, nom, nouveau):
    motif = re.compile(r"^def " + nom + r"\(.*?(?=^def |\Z)", re.S | re.M)
    assert motif.search(code), "fonction introuvable : " + nom
    return motif.sub(nouveau, code, count=1)


code = open(CHEMIN, encoding="utf-8").read()
etape = sys.argv[1]

if etape == "code-mort":
    code = remplacer_fonction(code, "maj_prix", "")
    code = remplacer(code, "STOCK = {}\n", "")
    code = remplacer(code, "import random\n", "")
    code = remplacer(
        code,
        "# -*- coding: utf-8 -*-\n"
        "# gestion de stock entrepot nord - v4\n"
        "# repris de la v3 de Kevin, TODO refactorer un jour\n"
        "# NE PAS TOUCHER A mouv() SANS PREVENIR L'EQUIPE LOGISTIQUE\n",
        '"""Gestion du stock de l entrepot nord."""\n\n',
    )
    code = remplacer(
        code,
        '        f = open("/tmp/rapport_" + str(random.randint(1, 9999)) + ".json", "w")\n',
        '        f = open("/tmp/rapport.json", "w")\n',
    )

elif etape == "constantes":
    code = remplacer(
        code,
        "TVA = 0.2\nS = 3\nR = 0.1\nQ = 100\n",
        "TAUX_TVA = 0.2\n"
        "MULTIPLICATEUR_DE_REAPPROVISIONNEMENT = 3\n"
        "TAUX_DE_REMISE_GROS_VOLUME = 0.1\n"
        "QUANTITE_MINIMALE_POUR_REMISE = 100\n"
        "JOURS_DE_LA_PERIODE_DE_VENTE = 30\n"
        "SEUIL_RUPTURE_IMMINENTE_EN_JOURS = 7\n"
        "SEUIL_SURVEILLANCE_EN_JOURS = 30\n",
    )
    code = remplacer(code, 'a["seuil"] * S', "a[\"seuil\"] * MULTIPLICATEUR_DE_REAPPROVISIONNEMENT")
    code = remplacer(code, "if n > Q:", "if n > QUANTITE_MINIMALE_POUR_REMISE:")
    code = remplacer(code, "n * a[\"pu\"] * R", "n * a[\"pu\"] * TAUX_DE_REMISE_GROS_VOLUME")
    code = remplacer(code, "(v / 30)", "(v / JOURS_DE_LA_PERIODE_DE_VENTE)")
    code = remplacer(code, "(ventes[a[\"ref\"]] / 30)", "(ventes[a[\"ref\"]] / JOURS_DE_LA_PERIODE_DE_VENTE)")
    code = remplacer(code, "if j < 7:", "if j < SEUIL_RUPTURE_IMMINENTE_EN_JOURS:")
    code = remplacer(code, "elif j < 30:", "elif j < SEUIL_SURVEILLANCE_EN_JOURS:")
    code = remplacer(code, "tot * (1 + TVA)", "tot * (1 + TAUX_TVA)")

elif etape == "valeur":
    code = remplacer_fonction(
        code,
        "val",
        'def valeur_brute(a):\n'
        '    return a["q"] * a["pu"]\n'
        "\n"
        "\n"
        "def val(arts):\n"
        '    return round(sum(valeur_brute(a) for a in arts if a["q"] > 0), 2)\n'
        "\n"
        "\n",
    )

elif etape == "alerte":
    code = remplacer_fonction(
        code,
        "alerte",
        "def alerte(arts):\n"
        '    return [a["ref"] for a in arts if a["q"] < a["seuil"]]\n'
        "\n"
        "\n",
    )

elif etape == "classer":
    code = remplacer_fonction(
        code,
        "classer",
        "def classer(arts):\n"
        "    return sorted(arts, key=valeur_brute, reverse=True)\n"
        "\n"
        "\n",
    )

elif etape == "categories":
    code = remplacer(
        code,
        "SEUIL_SURVEILLANCE_EN_JOURS = 30\n",
        "SEUIL_SURVEILLANCE_EN_JOURS = 30\n"
        'CATEGORIES_CONNUES = ("outil", "consommable", "piece")\n'
        'CATEGORIE_PAR_DEFAUT = "autre"\n',
    )
    code = remplacer_fonction(
        code,
        "par_cat",
        "def par_cat(arts):\n"
        "    totaux = {}\n"
        "    for a in arts:\n"
        '        categorie = a["cat"] if a["cat"] in CATEGORIES_CONNUES else CATEGORIE_PAR_DEFAUT\n'
        "        totaux[categorie] = totaux.get(categorie, 0) + valeur_brute(a)\n"
        "    return {categorie: round(valeur, 2) for categorie, valeur in totaux.items()}\n"
        "\n"
        "\n",
    )

elif etape == "rotation":
    code = remplacer_fonction(
        code,
        "rot",
        "def rot(a, v):\n"
        "    if v == 0:\n"
        "        return 0\n"
        '    return math.floor(a["q"] / (v / JOURS_DE_LA_PERIODE_DE_VENTE))\n'
        "\n"
        "\n",
    )

elif etape == "cout":
    code = remplacer_fonction(
        code,
        "cout",
        "def quantite_a_commander(a):\n"
        '    return a["seuil"] * MULTIPLICATEUR_DE_REAPPROVISIONNEMENT - a["q"]\n'
        "\n"
        "\n"
        "def cout(a):\n"
        '    if a["q"] >= a["seuil"]:\n'
        "        return 0\n"
        "    quantite = quantite_a_commander(a)\n"
        '    montant = quantite * a["pu"]\n'
        "    if quantite > QUANTITE_MINIMALE_POUR_REMISE:\n"
        "        montant -= montant * TAUX_DE_REMISE_GROS_VOLUME\n"
        "    return round(montant, 2)\n"
        "\n"
        "\n",
    )

elif etape == "mouvement":
    code = remplacer_fonction(
        code,
        "mouv",
        'def mouv(a, q, t="out", j=None, force=False):\n'
        "    global DERNIER\n"
        "    if q <= 0:\n"
        "        return False\n"
        '    if t == "out":\n'
        '        a["q"] = a["q"] - q\n'
        '        if a["q"] < 0 and not force:\n'
        "            return False\n"
        '    elif t == "in":\n'
        '        a["q"] = a["q"] + q\n'
        "    else:\n"
        "        return False\n"
        "    DERNIER = DERNIER + 1\n"
        '    ecriture = {"id": DERNIER, "ref": a["ref"], "q": q, "t": t}\n'
        "    if j is not None:\n"
        "        j.append(ecriture)\n"
        "    JOURNAL.append(dict(ecriture))\n"
        "    return True\n"
        "\n"
        "\n",
    )

elif etape == "export":
    code = remplacer_fonction(
        code,
        "export_json",
        'def export_json(res, chemin="/tmp/inv.json", hist=None):\n'
        "    historique = [] if hist is None else hist\n"
        "    historique.append(res)\n"
        '    with open(chemin, "w", encoding="utf-8") as fichier:\n'
        "        fichier.write(json.dumps(historique))\n"
        "    return historique\n",
    )

else:
    raise SystemExit("etape inconnue : " + etape)

open(CHEMIN, "w", encoding="utf-8").write(code)
PYEOF
}

patcher code-mort
bleu "suppression du code mort et du commentaire d'avertissement" $M

patcher constantes
bleu "constantes nommees a la place de TVA, S, R et Q" $M

patcher valeur
bleu "extraction de valeur_brute et val en une expression" $M

patcher alerte
bleu "alerte en comprehension de liste" $M

patcher classer
bleu "classer utilise sorted a la place du tri a bulles" $M

patcher categories
bleu "par_cat sans les quatre blocs dupliques" $M

patcher rotation
bleu "rot sans attrape-tout, seul le cas sans vente est conserve" $M

patcher cout
bleu "cout avec clause de garde et quantite_a_commander extraite" $M

patcher mouvement
bleu "mouv sans argument par defaut mutable et sans affichage" $M

patcher export
bleu "export_json sans argument par defaut mutable" $M

patcher_rapport() {
  python3 - "$@" <<'PYEOF'
import re
import sys

CHEMIN = "inventaire/inventaire.py"


def remplacer(code, ancien, nouveau):
    assert ancien in code, "fragment introuvable : " + ancien[:60]
    return code.replace(ancien, nouveau, 1)


def remplacer_fonction(code, nom, nouveau):
    motif = re.compile(r"^def " + nom + r"\(.*?(?=^def |\Z)", re.S | re.M)
    assert motif.search(code), "fonction introuvable : " + nom
    return motif.sub(nouveau, code, count=1)


code = open(CHEMIN, encoding="utf-8").read()
etape = sys.argv[1]

if etape == "messages":
    code = remplacer_fonction(
        code,
        "rapport",
        "def message_de_rotation(a, ventes_sur_la_periode):\n"
        "    if ventes_sur_la_periode <= 0:\n"
        '        return "aucune vente pour " + a["ref"]\n'
        '    jours = math.floor(a["q"] / (ventes_sur_la_periode / JOURS_DE_LA_PERIODE_DE_VENTE))\n'
        "    if jours < SEUIL_RUPTURE_IMMINENTE_EN_JOURS:\n"
        '        return "RUPTURE IMMINENTE " + a["ref"]\n'
        "    if jours < SEUIL_SURVEILLANCE_EN_JOURS:\n"
        '        return "a surveiller " + a["ref"]\n'
        "    return None\n"
        "\n"
        "\n"
        "def messages_de_diagnostic(arts, ventes=None, cat=None, seuil_min=None):\n"
        "    messages = []\n"
        "    for a in arts:\n"
        '        if cat is not None and a["cat"] != cat:\n'
        "            continue\n"
        '        if seuil_min is not None and a["q"] < seuil_min:\n'
        "            continue\n"
        '        if a["q"] <= 0:\n'
        '            messages.append("stock vide " + a["ref"])\n'
        "            continue\n"
        '        if a["pu"] <= 0:\n'
        '            messages.append("prix invalide " + a["ref"])\n'
        "            continue\n"
        '        if a["q"] < a["seuil"]:\n'
        '            messages.append("ALERTE " + a["ref"] + " : " + str(a["q"]) + " restants")\n'
        '        if ventes is not None and a["ref"] in ventes:\n'
        '            message = message_de_rotation(a, ventes[a["ref"]])\n'
        "            if message is not None:\n"
        "                messages.append(message)\n"
        "    return messages\n"
        "\n"
        "\n"
        "def rapport(arts, ventes=None, cat=None, seuil_min=None, export=False, verbose=True, d=None):\n"
        "    if verbose:\n"
        "        for message in messages_de_diagnostic(arts, ventes, cat, seuil_min):\n"
        "            print(message)\n"
        "    if d is None:\n"
        "        d = datetime.datetime.now()\n"
        "    res = {}\n"
        '    res["date"] = str(d)\n'
        "    tot = 0\n"
        "    nb = 0\n"
        "    liste_alerte = []\n"
        "    for a in arts:\n"
        '        if cat is not None and a["cat"] != cat:\n'
        "            continue\n"
        '        if seuil_min is not None and a["q"] < seuil_min:\n'
        "            continue\n"
        '        if a["q"] > 0 and a["pu"] > 0:\n'
        "            tot = tot + valeur_brute(a)\n"
        "            nb = nb + 1\n"
        '            if a["q"] < a["seuil"]:\n'
        '                liste_alerte.append(a["ref"])\n'
        '    res["valeur"] = round(tot, 2)\n'
        '    res["nb"] = nb\n'
        '    res["alertes"] = liste_alerte\n'
        '    res["ttc"] = round(tot * (1 + TAUX_TVA), 2)\n'
        "    if export:\n"
        '        with open("/tmp/rapport.json", "w", encoding="utf-8") as fichier:\n'
        "            fichier.write(json.dumps(res))\n"
        "    return res\n"
        "\n"
        "\n",
    )

elif etape == "selection":
    code = remplacer_fonction(
        code,
        "messages_de_diagnostic",
        "def articles_retenus(arts, cat=None, seuil_min=None):\n"
        "    for a in arts:\n"
        '        if cat is not None and a["cat"] != cat:\n'
        "            continue\n"
        '        if seuil_min is not None and a["q"] < seuil_min:\n'
        "            continue\n"
        "        yield a\n"
        "\n"
        "\n"
        "def messages_de_diagnostic(arts, ventes=None, cat=None, seuil_min=None):\n"
        "    messages = []\n"
        "    for a in articles_retenus(arts, cat, seuil_min):\n"
        '        if a["q"] <= 0:\n'
        '            messages.append("stock vide " + a["ref"])\n'
        "            continue\n"
        '        if a["pu"] <= 0:\n'
        '            messages.append("prix invalide " + a["ref"])\n'
        "            continue\n"
        '        if a["q"] < a["seuil"]:\n'
        '            messages.append("ALERTE " + a["ref"] + " : " + str(a["q"]) + " restants")\n'
        '        if ventes is not None and a["ref"] in ventes:\n'
        '            message = message_de_rotation(a, ventes[a["ref"]])\n'
        "            if message is not None:\n"
        "                messages.append(message)\n"
        "    return messages\n"
        "\n"
        "\n",
    )
    code = remplacer(
        code,
        "    for a in arts:\n"
        '        if cat is not None and a["cat"] != cat:\n'
        "            continue\n"
        '        if seuil_min is not None and a["q"] < seuil_min:\n'
        "            continue\n"
        '        if a["q"] > 0 and a["pu"] > 0:\n'
        "            tot = tot + valeur_brute(a)\n"
        "            nb = nb + 1\n"
        '            if a["q"] < a["seuil"]:\n'
        '                liste_alerte.append(a["ref"])\n',
        "    for a in articles_retenus(arts, cat, seuil_min):\n"
        '        if a["q"] > 0 and a["pu"] > 0:\n'
        "            tot = tot + valeur_brute(a)\n"
        "            nb = nb + 1\n"
        '            if a["q"] < a["seuil"]:\n'
        '                liste_alerte.append(a["ref"])\n',
    )

elif etape == "sortie-fichier":
    code = remplacer(
        code,
        "    if export:\n"
        '        with open("/tmp/rapport.json", "w", encoding="utf-8") as fichier:\n'
        "            fichier.write(json.dumps(res))\n"
        "    return res\n",
        "    return res\n",
    )
    code = remplacer(
        code,
        "def rapport(arts, ventes=None, cat=None, seuil_min=None, export=False, verbose=True, d=None):\n",
        "def rapport(arts, ventes=None, cat=None, seuil_min=None, verbose=True, d=None):\n",
    )

elif etape == "signature":
    code = remplacer(
        code,
        "def rapport(arts, ventes=None, cat=None, seuil_min=None, verbose=True, d=None):\n"
        "    if verbose:\n"
        "        for message in messages_de_diagnostic(arts, ventes, cat, seuil_min):\n"
        "            print(message)\n",
        "def afficher_diagnostic(arts, ventes=None, cat=None, seuil_min=None):\n"
        "    for message in messages_de_diagnostic(arts, ventes, cat, seuil_min):\n"
        "        print(message)\n"
        "\n"
        "\n"
        "def rapport(arts, cat=None, seuil_min=None, d=None):\n",
    )

else:
    raise SystemExit("etape inconnue : " + etape)

open(CHEMIN, "w", encoding="utf-8").write(code)
PYEOF
}

patcher_rapport messages
bleu "rapport, extraction des messages de diagnostic" $M

patcher_rapport selection
bleu "rapport, extraction de la selection des articles" $M

patcher_rapport sortie-fichier
bleu "rapport ne sait plus ecrire de fichier" $M

patcher_rapport signature
bleu "rapport ne sait plus afficher, sa signature tombe a quatre parametres" $M

sed -i 's/^from inventaire import alerte, classer, cout, export_json, mouv, par_cat, rapport, rot, val$/from inventaire import (\n    alerte,\n    classer,\n    cout,\n    export_json,\n    message_de_rotation,\n    messages_de_diagnostic,\n    mouv,\n    par_cat,\n    rapport,\n    rot,\n    val,\n)/' $T
cat >> $T <<'EOF'


# --- diagnostic, extrait du corps de rapport ------------------------------


def test_un_stock_vide_est_signale():
    assert messages_de_diagnostic([article(q=0)]) == ["stock vide VIS-M6"]


def test_un_prix_invalide_est_signale():
    assert messages_de_diagnostic([article(pu=0)]) == ["prix invalide VIS-M6"]


def test_un_article_sous_son_seuil_est_signale_avec_sa_quantite():
    messages = messages_de_diagnostic([article(q=5, seuil=10)])
    assert messages == ["ALERTE VIS-M6 : 5 restants"]


def test_moins_de_sept_jours_de_stock_est_une_rupture_imminente():
    assert message_de_rotation(article(q=10), 300) == "RUPTURE IMMINENTE VIS-M6"


def test_moins_de_trente_jours_de_stock_est_a_surveiller():
    assert message_de_rotation(article(q=100), 300) == "a surveiller VIS-M6"


def test_plus_de_trente_jours_de_stock_ne_dit_rien():
    assert message_de_rotation(article(q=1000), 300) is None


def test_une_periode_sans_vente_est_signalee():
    assert message_de_rotation(article(q=10), 0) == "aucune vente pour VIS-M6"
EOF
deja_vert "les messages extraits disent exactement la meme chose qu'avant" $T

patcher_final() {
  python3 - "$@" <<'PYEOF'
import re
import sys

CHEMIN = "inventaire/inventaire.py"


def remplacer(code, ancien, nouveau):
    assert ancien in code, "fragment introuvable : " + ancien[:60]
    return code.replace(ancien, nouveau, 1)


def remplacer_fonction(code, nom, nouveau):
    motif = re.compile(r"^def " + nom + r"\(.*?(?=^def |\Z)", re.S | re.M)
    assert motif.search(code), "fonction introuvable : " + nom
    return motif.sub(nouveau, code, count=1)


code = open(CHEMIN, encoding="utf-8").read()
etape = sys.argv[1]

if etape == "un-article":
    code = remplacer_fonction(
        code,
        "messages_de_diagnostic",
        "def message_d_exclusion(a):\n"
        '    if a["q"] <= 0:\n'
        '        return "stock vide " + a["ref"]\n'
        '    if a["pu"] <= 0:\n'
        '        return "prix invalide " + a["ref"]\n'
        "    return None\n"
        "\n"
        "\n"
        "def message_de_rotation_si_connue(a, ventes):\n"
        '    if ventes is None or a["ref"] not in ventes:\n'
        "        return None\n"
        '    return message_de_rotation(a, ventes[a["ref"]])\n'
        "\n"
        "\n"
        "def messages_pour_un_article(a, ventes=None):\n"
        "    exclusion = message_d_exclusion(a)\n"
        "    if exclusion is not None:\n"
        "        return [exclusion]\n"
        "    messages = []\n"
        '    if a["q"] < a["seuil"]:\n'
        '        messages.append("ALERTE " + a["ref"] + " : " + str(a["q"]) + " restants")\n'
        "    rotation = message_de_rotation_si_connue(a, ventes)\n"
        "    if rotation is not None:\n"
        "        messages.append(rotation)\n"
        "    return messages\n"
        "\n"
        "\n"
        "def messages_de_diagnostic(arts, ventes=None, cat=None, seuil_min=None):\n"
        "    messages = []\n"
        "    for a in articles_retenus(arts, cat, seuil_min):\n"
        "        messages.extend(messages_pour_un_article(a, ventes))\n"
        "    return messages\n"
        "\n"
        "\n",
    )

elif etape == "predicats":
    code = remplacer_fonction(
        code,
        "articles_retenus",
        "def correspond_a_la_categorie(a, cat):\n"
        '    return cat is None or a["cat"] == cat\n'
        "\n"
        "\n"
        "def atteint_la_quantite_minimale(a, seuil_min):\n"
        '    return seuil_min is None or a["q"] >= seuil_min\n'
        "\n"
        "\n"
        "def est_comptabilisable(a):\n"
        '    return a["q"] > 0 and a["pu"] > 0\n'
        "\n"
        "\n"
        "def articles_retenus(arts, cat=None, seuil_min=None):\n"
        "    return (\n"
        "        a\n"
        "        for a in arts\n"
        "        if correspond_a_la_categorie(a, cat) and atteint_la_quantite_minimale(a, seuil_min)\n"
        "    )\n"
        "\n"
        "\n",
    )
    code = remplacer(
        code,
        "    for a in articles_retenus(arts, cat, seuil_min):\n"
        '        if a["q"] > 0 and a["pu"] > 0:\n'
        "            tot = tot + valeur_brute(a)\n"
        "            nb = nb + 1\n"
        '            if a["q"] < a["seuil"]:\n'
        '                liste_alerte.append(a["ref"])\n',
        "    for a in articles_retenus(arts, cat, seuil_min):\n"
        "        if not est_comptabilisable(a):\n"
        "            continue\n"
        "        tot = tot + valeur_brute(a)\n"
        "        nb = nb + 1\n"
        '        if a["q"] < a["seuil"]:\n'
        '            liste_alerte.append(a["ref"])\n',
    )

elif etape == "scission-mouv":
    code = remplacer_fonction(
        code,
        "mouv",
        "def enregistrer_mouvement(article, quantite, sens, journal):\n"
        "    global DERNIER\n"
        "    DERNIER = DERNIER + 1\n"
        '    ecriture = {"id": DERNIER, "ref": article["ref"], "q": quantite, "t": sens}\n'
        "    if journal is not None:\n"
        "        journal.append(ecriture)\n"
        "    JOURNAL.append(dict(ecriture))\n"
        "\n"
        "\n"
        "def retirer_du_stock(article, quantite, journal=None, force=False):\n"
        "    if quantite <= 0:\n"
        "        return False\n"
        '    article["q"] = article["q"] - quantite\n'
        '    if article["q"] < 0 and not force:\n'
        "        return False\n"
        '    enregistrer_mouvement(article, quantite, "out", journal)\n'
        "    return True\n"
        "\n"
        "\n"
        "def ajouter_au_stock(article, quantite, journal=None):\n"
        "    if quantite <= 0:\n"
        "        return False\n"
        '    article["q"] = article["q"] + quantite\n'
        '    enregistrer_mouvement(article, quantite, "in", journal)\n'
        "    return True\n"
        "\n"
        "\n",
    )

else:
    raise SystemExit("etape inconnue : " + etape)

open(CHEMIN, "w", encoding="utf-8").write(code)
PYEOF
}

patcher_final un-article
bleu "diagnostic, un article a la fois" $M

patcher_final predicats
bleu "selection exprimee par des predicats nommes" $M

echo ""
echo "=== MISSION 3 : les renommages, qui touchent aussi les appels des tests ==="

python3 - <<'PYEOF'
RENOMMAGES = [
    ("def val(arts):", "def valeur_du_stock(articles):"),
    ("def alerte(arts):", "def references_en_alerte(articles):"),
    ("def cout(a):", "def cout_de_reapprovisionnement(article):"),
    ("def classer(arts):", "def classer_par_valeur(articles):"),
    ("def rot(a, v):", "def rotation_en_jours(article, ventes_sur_la_periode):"),
    ("def par_cat(arts):", "def valeur_par_categorie(articles):"),
    ("def rapport(arts, cat=None, seuil_min=None, d=None):",
     "def generer_rapport(articles, categorie=None, quantite_minimale=None, date_du_rapport=None):"),
    ("def export_json(res, chemin=", "def exporter_historique(rapport, chemin="),
]

code = open("inventaire/inventaire.py", encoding="utf-8").read()

code = code.replace(
    "def valeur_du_stock(arts):\n"
    '    return round(sum(valeur_brute(a) for a in arts if a["q"] > 0), 2)\n',
    "def valeur_du_stock(articles):\n"
    '    return round(sum(valeur_brute(a) for a in articles if a["q"] > 0), 2)\n',
)

for ancien, nouveau in RENOMMAGES:
    assert ancien in code, ancien
    code = code.replace(ancien, nouveau, 1)

# les corps qui referencent les anciens noms de parametres
code = code.replace(
    "def valeur_du_stock(articles):\n"
    '    return round(sum(valeur_brute(a) for a in arts if a["q"] > 0), 2)\n',
    "def valeur_du_stock(articles):\n"
    '    return round(sum(valeur_brute(a) for a in articles if a["q"] > 0), 2)\n',
)
code = code.replace(
    "def references_en_alerte(articles):\n"
    '    return [a["ref"] for a in arts if a["q"] < a["seuil"]]\n',
    "def references_en_alerte(articles):\n"
    '    return [a["ref"] for a in articles if a["q"] < a["seuil"]]\n',
)
code = code.replace(
    "def cout_de_reapprovisionnement(article):\n"
    '    if a["q"] >= a["seuil"]:\n'
    "        return 0\n"
    "    quantite = quantite_a_commander(a)\n"
    '    montant = quantite * a["pu"]\n',
    "def cout_de_reapprovisionnement(article):\n"
    '    if article["q"] >= article["seuil"]:\n'
    "        return 0\n"
    "    quantite = quantite_a_commander(article)\n"
    '    montant = quantite * article["pu"]\n',
)
code = code.replace(
    "def classer_par_valeur(articles):\n"
    "    return sorted(arts, key=valeur_brute, reverse=True)\n",
    "def classer_par_valeur(articles):\n"
    "    return sorted(articles, key=valeur_brute, reverse=True)\n",
)
code = code.replace(
    "def rotation_en_jours(article, ventes_sur_la_periode):\n"
    "    if v == 0:\n"
    "        return 0\n"
    '    return math.floor(a["q"] / (v / JOURS_DE_LA_PERIODE_DE_VENTE))\n',
    "def rotation_en_jours(article, ventes_sur_la_periode):\n"
    "    if ventes_sur_la_periode == 0:\n"
    "        return 0\n"
    "    ventes_par_jour = ventes_sur_la_periode / JOURS_DE_LA_PERIODE_DE_VENTE\n"
    '    return math.floor(article["q"] / ventes_par_jour)\n',
)
code = code.replace(
    "def valeur_par_categorie(articles):\n    totaux = {}\n    for a in arts:\n",
    "def valeur_par_categorie(articles):\n    totaux = {}\n    for a in articles:\n",
)
code = code.replace(
    "def generer_rapport(articles, categorie=None, quantite_minimale=None, date_du_rapport=None):\n"
    "    if d is None:\n"
    "        d = datetime.datetime.now()\n"
    "    res = {}\n"
    '    res["date"] = str(d)\n'
    "    tot = 0\n"
    "    nb = 0\n"
    "    liste_alerte = []\n"
    "    for a in articles_retenus(arts, cat, seuil_min):\n"
    "        if not est_comptabilisable(a):\n"
    "            continue\n"
    "        tot = tot + valeur_brute(a)\n"
    "        nb = nb + 1\n"
    '        if a["q"] < a["seuil"]:\n'
    '            liste_alerte.append(a["ref"])\n'
    '    res["valeur"] = round(tot, 2)\n'
    '    res["nb"] = nb\n'
    '    res["alertes"] = liste_alerte\n'
    '    res["ttc"] = round(tot * (1 + TAUX_TVA), 2)\n'
    "    return res\n",
    "def generer_rapport(articles, categorie=None, quantite_minimale=None, date_du_rapport=None):\n"
    "    if date_du_rapport is None:\n"
    "        date_du_rapport = datetime.datetime.now()\n"
    "    total = 0\n"
    "    nombre_d_articles = 0\n"
    "    alertes = []\n"
    "    for article in articles_retenus(articles, categorie, quantite_minimale):\n"
    "        if not est_comptabilisable(article):\n"
    "            continue\n"
    "        total = total + valeur_brute(article)\n"
    "        nombre_d_articles = nombre_d_articles + 1\n"
    '        if article["q"] < article["seuil"]:\n'
    '            alertes.append(article["ref"])\n'
    "    return {\n"
    '        "date": str(date_du_rapport),\n'
    '        "valeur": round(total, 2),\n'
    '        "nb": nombre_d_articles,\n'
    '        "alertes": alertes,\n'
    '        "ttc": round(total * (1 + TAUX_TVA), 2),\n'
    "    }\n",
)
code = code.replace(
    "def exporter_historique(rapport, chemin=\"/tmp/inv.json\", hist=None):\n"
    "    historique = [] if hist is None else hist\n"
    "    historique.append(res)\n"
    '    with open(chemin, "w", encoding="utf-8") as fichier:\n'
    "        fichier.write(json.dumps(historique))\n"
    "    return historique\n",
    "def exporter_historique(rapport, chemin=\"/tmp/inv.json\", historique=None):\n"
    "    entrees = [] if historique is None else historique\n"
    "    entrees.append(rapport)\n"
    '    with open(chemin, "w", encoding="utf-8") as fichier:\n'
    "        fichier.write(json.dumps(entrees))\n"
    "    return entrees\n",
)
open("inventaire/inventaire.py", "w", encoding="utf-8").write(code)

# les tests suivent, seuls les noms changent, aucune assertion n'est touchee
tests = open("inventaire/test_inventaire.py", encoding="utf-8").read()
tests = tests.replace(
    "from inventaire import (\n"
    "    alerte,\n"
    "    classer,\n"
    "    cout,\n"
    "    export_json,\n"
    "    message_de_rotation,\n"
    "    messages_de_diagnostic,\n"
    "    mouv,\n"
    "    par_cat,\n"
    "    rapport,\n"
    "    rot,\n"
    "    val,\n"
    ")",
    "from inventaire import (\n"
    "    classer_par_valeur,\n"
    "    cout_de_reapprovisionnement,\n"
    "    exporter_historique,\n"
    "    generer_rapport,\n"
    "    message_de_rotation,\n"
    "    messages_de_diagnostic,\n"
    "    mouv,\n"
    "    references_en_alerte,\n"
    "    rotation_en_jours,\n"
    "    valeur_du_stock,\n"
    "    valeur_par_categorie,\n"
    ")",
)
for ancien, nouveau in [
    ("val(", "valeur_du_stock("),
    ("alerte(", "references_en_alerte("),
    ("cout(", "cout_de_reapprovisionnement("),
    ("classer(", "classer_par_valeur("),
    ("rot(", "rotation_en_jours("),
    ("par_cat(", "valeur_par_categorie("),
    ("rapport(", "generer_rapport("),
    ("export_json(", "exporter_historique("),
]:
    tests = tests.replace(" " + ancien, " " + nouveau)
tests = tests.replace("d=\"2019-03-05\"", "date_du_rapport=\"2019-03-05\"")
tests = tests.replace("d=\"x\"", "date_du_rapport=\"x\"")
tests = tests.replace(
    'generer_rapport(articles, cat="outil"',
    'generer_rapport(articles, categorie="outil"',
)
tests = tests.replace("seuil_min=100", "quantite_minimale=100")
tests = tests.replace("hist=[]", "historique=[]")
open("inventaire/test_inventaire.py", "w", encoding="utf-8").write(tests)
PYEOF
bleu "noms explicites pour les fonctions publiques et leurs parametres" $M $T

patcher_final scission-mouv
python3 - <<'FIN_SCISSION'
tests = open("inventaire/test_inventaire.py", encoding="utf-8").read()
tests = tests.replace("    mouv,\n", "    ajouter_au_stock,\n    retirer_du_stock,\n")
# la liste d'import redevient triee
tests = tests.replace(
    "from inventaire import (\n"
    "    classer_par_valeur,\n"
    "    cout_de_reapprovisionnement,\n"
    "    exporter_historique,\n"
    "    generer_rapport,\n"
    "    message_de_rotation,\n"
    "    messages_de_diagnostic,\n"
    "    ajouter_au_stock,\n"
    "    retirer_du_stock,\n"
    "    references_en_alerte,\n"
    "    rotation_en_jours,\n"
    "    valeur_du_stock,\n"
    "    valeur_par_categorie,\n"
    ")",
    "from inventaire import (\n"
    "    ajouter_au_stock,\n"
    "    classer_par_valeur,\n"
    "    cout_de_reapprovisionnement,\n"
    "    exporter_historique,\n"
    "    generer_rapport,\n"
    "    message_de_rotation,\n"
    "    messages_de_diagnostic,\n"
    "    references_en_alerte,\n"
    "    retirer_du_stock,\n"
    "    rotation_en_jours,\n"
    "    valeur_du_stock,\n"
    "    valeur_par_categorie,\n"
    ")",
)

# le drapeau t disparait, donc le test qui documentait sa valeur invalide aussi
tests = tests.replace(
    "\n\ndef test_mouv_refuse_un_type_de_mouvement_inconnu():\n"
    "    a = article(q=50)\n"
    '    assert retirer_du_stock(a, 5, t="transfert") is False\n',
    "",
)
tests = tests.replace(
    "\n\ndef test_mouv_refuse_un_type_de_mouvement_inconnu():\n"
    "    a = article(q=50)\n"
    '    assert mouv(a, 5, t="transfert") is False\n',
    "",
)

REMPLACEMENTS = [
    ('assert mouv(a, 10, t="in") is True', "assert ajouter_au_stock(a, 10) is True"),
    ("assert mouv(a, 10) is True", "assert retirer_du_stock(a, 10) is True"),
    ("assert mouv(article(q=50), 51) is False", "assert retirer_du_stock(article(q=50), 51) is False"),
    ("    mouv(a, 51)\n", "    retirer_du_stock(a, 51)\n"),
    ("assert mouv(a, 0) is False", "assert retirer_du_stock(a, 0) is False"),
    ("assert mouv(a, -3) is False", "assert retirer_du_stock(a, -3) is False"),
    ("mouv(article(q=50), 5, j=journal)", "retirer_du_stock(article(q=50), 5, journal=journal)"),
    ("def test_mouv_retire_la_quantite_demandee", "def test_un_retrait_diminue_le_stock"),
    ("def test_mouv_ajoute_la_quantite_demandee", "def test_un_ajout_augmente_le_stock"),
    ("def test_mouv_refuse_un_retrait_superieur_au_stock",
     "def test_un_retrait_superieur_au_stock_est_refuse"),
    ("def test_mouv_laisse_le_stock_negatif_apres_un_refus_alors_que_la_regle_m3_l_interdit",
     "def test_un_refus_laisse_le_stock_negatif_alors_que_la_regle_m3_l_interdit"),
    ("def test_mouv_refuse_une_quantite_nulle_ou_negative",
     "def test_une_quantite_nulle_ou_negative_est_refusee"),
    ("def test_mouv_alimente_le_journal_fourni", "def test_le_journal_fourni_est_alimente"),
]
for ancien, nouveau in REMPLACEMENTS:
    assert ancien in tests, ancien
    tests = tests.replace(ancien, nouveau)
open("inventaire/test_inventaire.py", "w", encoding="utf-8").write(tests)
FIN_SCISSION
bleu "mouv scinde en retirer_du_stock et ajouter_au_stock" $M $T

python3 - <<'FIN_COMPTEUR'
code = open("inventaire/inventaire.py", encoding="utf-8").read()
ancien = (
    "def enregistrer_mouvement(article, quantite, sens, journal):\n"
    "    global DERNIER\n"
    "    DERNIER = DERNIER + 1\n"
    '    ecriture = {\"id\": DERNIER, \"ref\": article[\"ref\"], \"q\": quantite, \"t\": sens}\n'
)
nouveau = (
    "def enregistrer_mouvement(article, quantite, sens, journal):\n"
    '    ecriture = {\n'
    '        \"id\": len(JOURNAL) + 1,\n'
    '        \"ref\": article[\"ref\"],\n'
    '        \"q\": quantite,\n'
    '        \"t\": sens,\n'
    "    }\n"
)
assert ancien in code
code = code.replace(ancien, nouveau, 1)
code = code.replace("JOURNAL = []\nDERNIER = 0\n", "JOURNAL = []\n", 1)
open("inventaire/inventaire.py", "w", encoding="utf-8").write(code)
FIN_COMPTEUR
bleu "suppression du compteur global, l'identifiant se deduit du journal" $M

cat > inventaire/exemple_utilisation.py <<'EOF'
"""Voici comment l equipe logistique appelle le module aujourd hui."""

from inventaire import (
    afficher_diagnostic,
    classer_par_valeur,
    cout_de_reapprovisionnement,
    generer_rapport,
    references_en_alerte,
    valeur_du_stock,
    valeur_par_categorie,
)

ARTICLES = [
    {"ref": "VIS-M6", "lib": "Vis M6 acier", "q": 2, "pu": 0.15, "seuil": 20, "cat": "piece"},
    {"ref": "PERC-18", "lib": "Perceuse 18V", "q": 12, "pu": 89.90, "seuil": 3, "cat": "outil"},
    {"ref": "GANT-L", "lib": "Gants L", "q": 5, "pu": 4.20, "seuil": 5, "cat": "consommable"},
    {"ref": "HUILE-5", "lib": "Huile 5L", "q": 40, "pu": 12.50, "seuil": 10, "cat": "consommable"},
    {"ref": "CAB-3G", "lib": "Cable 3G2.5", "q": 0, "pu": 1.80, "seuil": 50, "cat": "autre"},
]

VENTES_30_JOURS = {"VIS-M6": 300, "PERC-18": 4, "GANT-L": 60, "HUILE-5": 15, "CAB-3G": 0}

if __name__ == "__main__":
    print("valeur du stock :", valeur_du_stock(ARTICLES))
    print("articles en alerte :", references_en_alerte(ARTICLES))
    print("cout de reappro des gants :", cout_de_reapprovisionnement(ARTICLES[2]))
    print("valeur par categorie :", valeur_par_categorie(ARTICLES))
    print("classement :", [a["ref"] for a in classer_par_valeur(ARTICLES)])
    print("---")
    afficher_diagnostic(ARTICLES, VENTES_30_JOURS)
    print(generer_rapport(ARTICLES))
EOF
if ! (cd inventaire && python3 exemple_utilisation.py >/dev/null); then
  echo "ARRET : exemple_utilisation.py ne tourne plus"; exit 1
fi
bleu "adaptation de exemple_utilisation.py aux nouveaux noms" inventaire/exemple_utilisation.py

echo ""
echo "=== MISSION 3 : les mesures d'apres ==="

{
  echo ""
  echo "---"
  echo ""
  echo "## 5. Tableau de bord après refactoring"
  echo ""
  echo "Mêmes commandes qu'en partie 1."
  echo ""
  echo '```bash'
  echo "radon cc -s -a inventaire/inventaire.py"
  echo '```'
  echo ""
  echo '```'
  radon cc -s -a inventaire/inventaire.py
  echo '```'
  echo ""
  echo '```bash'
  echo "radon mi -s inventaire/inventaire.py"
  echo '```'
  echo ""
  echo '```'
  radon mi -s inventaire/inventaire.py
  echo '```'
  echo ""
  echo "| Mesure | Avant | Après |"
  echo "|---|---|---|"
  echo "| Complexité maximale | 22, rang D | $(radon cc -s inventaire/inventaire.py | awk '{print $NF}' | tr -d '()' | sort -n | tail -1), rang A |"
  echo "| Complexité moyenne | 5.9, rang B | $(radon cc -a inventaire/inventaire.py | tail -1 | sed 's/.*: //') |"
  echo "| Indice de maintenabilité | A (36.80) | $(radon mi -s inventaire/inventaire.py | sed 's/.* - //') |"
  echo "| Score pylint | 7.76 / 10 | $(pylint inventaire/inventaire.py 2>/dev/null | grep 'rated at' | sed 's/.*rated at \([0-9.]*\).*/\1/') / 10 |"
  echo "| Problèmes ruff | 14 | $(ruff check inventaire/ 2>/dev/null | grep -c '^[A-Z]' || echo 0) |"
  echo "| Tests sur le module | 0 | $(python3 -m pytest --collect-only -q inventaire/ 2>/dev/null | grep -cE '::') |"
  echo "| Fonctions de plus de 4 paramètres | 2 | 0 |"
  echo "| Arguments par défaut mutables | 2 | 0 |"
  echo "| Attrape-tout d'exception | 1 | 0 |"
  echo "| \`print\` dans le code de calcul | 7 | 0 |"
  echo ""
  echo "Ce que ce delta prouve : la fonction que personne n'osait modifier est passée"
  echo "du rang D au rang A, le module est couvert par des tests qui décrivent son"
  echo "comportement réel, et les six écarts relevés sont documentés et toujours"
  echo "présents, prêts à être corrigés en mission 5."
} >> RAPPORT-QUALITE.md
tache "mesures d'apres refactoring" RAPPORT-QUALITE.md

echo ""
echo "=== CE QUE VAUT LE DEPOT A LA FIN DE LA MISSION 3 ==="
echo ""
python3 -m pytest -q 2>&1 | tail -1
echo ""
radon cc -s -a inventaire/inventaire.py | tail -3
echo ""
ruff format --check inventaire/ >/dev/null 2>&1 || { echo "ARRET : formatage non conforme"; exit 1; }
ruff check inventaire/ >/dev/null 2>&1 && echo "ruff : aucun probleme, formatage conforme" || ruff check inventaire/ 2>&1 | tail -2
echo ""
git log --oneline "$(git log --format=%h --grep='^refactor: types explicites' -1)"..HEAD | wc -l | xargs printf 'commits ajoutes en mission 3 : %s\n'
printf 'total : %s commits\n' "$(git rev-list --count HEAD)"
for p in red green refactor test chore; do
  printf '%-9s %s\n' "$p:" "$(git log --format=%s | grep -c "^$p: ")"
done
