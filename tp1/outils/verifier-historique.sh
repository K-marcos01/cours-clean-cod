#!/usr/bin/env bash
# Verifie qu'un depot du TP1 a reellement ete construit en TDD.
#
# Usage : ./verifier-historique.sh [chemin_du_depot] [nb_commits_red_a_rejouer]
#
# Ce que le script controle :
#   1. la convention de messages de commit
#   2. l'alternance red -> green
#   3. l'absence de code de production dans les commits red
#   4. le fait qu'un commit red est reellement rouge, en le rejouant
#
# Le meme script est utilise pour la correction. Lance-le avant de rendre.

set -uo pipefail

DEPOT="${1:-.}"
NB_REJOUES="${2:-3}"

if ! git -C "$DEPOT" rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERREUR : $DEPOT n'est pas un depot git."
  exit 2
fi

DEPOT="$(cd "$DEPOT" && pwd)"
PREFIXES="red|green|refactor|test|fix|chore"
ROUGE=$'\033[31m'; VERT=$'\033[32m'; JAUNE=$'\033[33m'; GRAS=$'\033[1m'; FIN=$'\033[0m'

ok()   { echo "${VERT}  ok${FIN}    $1"; }
ko()   { echo "${ROUGE}  ko${FIN}    $1"; }
warn() { echo "${JAUNE}  note${FIN}  $1"; }
titre(){ echo ""; echo "${GRAS}$1${FIN}"; }

PROBLEMES=0
incr() { PROBLEMES=$((PROBLEMES + 1)); }

# ---------------------------------------------------------------------------
titre "1. Volume et forme de l'historique"

TOTAL=$(git -C "$DEPOT" rev-list --count HEAD)
echo "  $TOTAL commits au total"

NON_CONFORMES=$(git -C "$DEPOT" log --format="%s" | grep -cvE "^($PREFIXES): .+" || true)
if [ "$NON_CONFORMES" -eq 0 ]; then
  ok "tous les messages respectent la convention"
else
  ko "$NON_CONFORMES message(s) hors convention :"
  git -C "$DEPOT" log --format="%h %s" | grep -vE "^[0-9a-f]+ ($PREFIXES): .+" | sed 's/^/        /'
  incr
fi

for p in red green refactor test fix chore; do
  N=$(git -C "$DEPOT" log --format="%s" | grep -cE "^$p: " || true)
  printf "  %-9s %s\n" "$p:" "$N"
done

# ---------------------------------------------------------------------------
titre "2. Alternance rouge puis vert"

mapfile -t SUJETS < <(git -C "$DEPOT" log --reverse --format="%h|%s")
PREC_TYPE=""
GREEN_ORPHELINS=0
for ligne in "${SUJETS[@]}"; do
  sha="${ligne%%|*}"; msg="${ligne#*|}"; type="${msg%%:*}"
  if [ "$type" = "green" ] && [ "$PREC_TYPE" != "red" ]; then
    ko "commit green sans red juste avant : $sha $msg"
    GREEN_ORPHELINS=$((GREEN_ORPHELINS + 1))
  fi
  PREC_TYPE="$type"
done
if [ "$GREEN_ORPHELINS" -eq 0 ]; then
  ok "chaque green est precede d'un red"
else
  incr
fi

NB_RED=$(git -C "$DEPOT" log --format="%s" | grep -cE "^red: " || true)
if [ "$NB_RED" -lt 8 ]; then
  ko "seulement $NB_RED commits red, le minimum attendu est 8"
  incr
else
  ok "$NB_RED commits red, au-dessus du minimum attendu"
fi

# ---------------------------------------------------------------------------
titre "3. Contenu des commits red"

SALES=0
while read -r sha; do
  [ -z "$sha" ] && continue
  PROD=$(git -C "$DEPOT" show --stat --format="" --name-only "$sha" \
         | grep -E '\.py$' | grep -vE '(^|/)(test_[^/]*\.py|conftest\.py)$' | grep -vE '(^|/)tests?/' || true)
  if [ -n "$PROD" ]; then
    ko "$sha contient du code de production : $(echo "$PROD" | tr '\n' ' ')"
    SALES=$((SALES + 1))
  fi
done < <(git -C "$DEPOT" log --format="%h" --grep="^red: ")
if [ "$SALES" -eq 0 ]; then
  ok "aucun commit red ne contient de code de production"
else
  incr
fi

# ---------------------------------------------------------------------------
titre "4. Rejeu de $NB_REJOUES commits red tires au hasard"

if ! command -v python3 >/dev/null 2>&1; then
  warn "python3 introuvable, rejeu ignore"
else
  TMP="$(mktemp -d)"
  trap 'git -C "$DEPOT" worktree prune >/dev/null 2>&1; rm -rf "$TMP"' EXIT
  MENSONGES=0
  REJOUES=0
  while read -r sha; do
    [ -z "$sha" ] && continue
    CIBLE="$TMP/$sha"
    if ! git -C "$DEPOT" worktree add --detach -q "$CIBLE" "$sha" 2>/dev/null; then
      warn "impossible de rejouer $sha"
      continue
    fi
    SORTIE="$(cd "$CIBLE" && python3 -m pytest -q 2>&1)"
    CODE=$?
    RESUME="$(echo "$SORTIE" | grep -iE "passed|failed|error|interrupted" | tail -1)"
    if [ "$CODE" -ne 0 ]; then
      ok "$sha est bien rouge   ($RESUME)"
    else
      ko "$sha est VERT alors qu'il est annonce red   ($RESUME)"
      MENSONGES=$((MENSONGES + 1))
    fi
    REJOUES=$((REJOUES + 1))
    git -C "$DEPOT" worktree remove --force "$CIBLE" >/dev/null 2>&1
  done < <(git -C "$DEPOT" log --format="%h" --grep="^red: " | shuf | head -n "$NB_REJOUES")
  [ "$MENSONGES" -gt 0 ] && incr
  [ "$REJOUES" -eq 0 ] && warn "aucun commit red rejoue"
fi

# ---------------------------------------------------------------------------
titre "5. Hygiene du depot"

if git -C "$DEPOT" ls-files | grep -qE '(^|/)\.venv/'; then
  ko "le dossier .venv est versionne"
  incr
else
  ok "pas d'environnement virtuel versionne"
fi

if git -C "$DEPOT" ls-files | grep -qE '__pycache__|\.pyc$'; then
  ko "des fichiers compiles sont versionnes"
  incr
else
  ok "pas de fichier compile versionne"
fi

for f in RAPPORT-QUALITE.md requirements-dev.txt .pre-commit-config.yaml verifier.sh preuve-garde-fou.txt; do
  if git -C "$DEPOT" ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    ok "$f present"
  else
    ko "$f manquant"
    incr
  fi
done

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
titre "6. Rythme de travail"

mapfile -t HORODATAGES < <(git -C "$DEPOT" log --reverse --format="%ct")
NB="${#HORODATAGES[@]}"
if [ "$NB" -ge 3 ]; then
  ETENDUE=$(( (HORODATAGES[NB-1] - HORODATAGES[0]) / 60 ))
  ECARTS=()
  for ((i = 1; i < NB; i++)); do
    ECARTS+=( $(( HORODATAGES[i] - HORODATAGES[i-1] )) )
  done
  MEDIANE=$(printf '%s\n' "${ECARTS[@]}" | sort -n \
    | awk '{a[NR]=$1} END {print (NR % 2) ? a[(NR+1)/2] : int((a[NR/2] + a[NR/2+1]) / 2)}')
  TRES_COURTS=$(printf '%s\n' "${ECARTS[@]}" | awk '$1 < 30' | wc -l)
  LONGS=$(printf '%s\n' "${ECARTS[@]}" | awk '$1 > 900' | wc -l)

  echo "  etendue de l'historique       : $ETENDUE minutes"
  echo "  ecart median entre 2 commits  : ${MEDIANE}s"
  echo "  ecarts de moins de 30 secondes: $TRES_COURTS sur ${#ECARTS[@]}"
  echo "  ecarts de plus de 15 minutes  : $LONGS sur ${#ECARTS[@]}"

  if [ "$ETENDUE" -lt 60 ]; then
    warn "moins d'une heure entre le premier et le dernier commit, pour un TP de 5 heures"
  else
    ok "l'historique s'etale sur $ETENDUE minutes"
  fi
  if [ "${#ECARTS[@]}" -gt 0 ] && [ $(( TRES_COURTS * 100 / ${#ECARTS[@]} )) -gt 70 ]; then
    warn "plus de 70 pour cent des commits sont espaces de moins de 30 secondes"
  fi
  if [ "$LONGS" -gt $(( NB / 4 )) ]; then
    warn "beaucoup de trous de plus de 15 minutes, les pas sont probablement trop grands"
  fi
else
  warn "trop peu de commits pour analyser le rythme"
fi

# ---------------------------------------------------------------------------
titre "Bilan"
if [ "$PROBLEMES" -eq 0 ]; then
  echo "${VERT}  Aucun probleme bloquant detecte.${FIN}"
  exit 0
fi
echo "${ROUGE}  $PROBLEMES categorie(s) de probleme a corriger avant de rendre.${FIN}"
exit 1
