# TP2, corrigé de la mission 1

Le corrigé vit sur la branche **`tp2-corrige`**, qui contient les commits réels.
Le script de ce dossier est ce qui l'a produite.

## Consulter la branche

```bash
git fetch origin
git log --oneline origin/tp2-corrige
git show origin/tp2-corrige:RAPPORT-CONCEPTION.md
git worktree add ../tp2-corrige tp2-corrige
```

## Régénérer

```bash
./rejouer-mission-1.sh /un/dossier/de/travail
```

Le script crée un dépôt neuf, il ne modifie rien sur place.

## Les sept commits

| Message | Étiquette |
|---|---|
| dépôt initialisé et gitignore | `[Mission 0]` |
| code de facturation à auditer | `[Mission 0]` |
| les cinq violations, une par principe | `[Partie 1]` |
| coût de la demande D1, formule decouverte | `[Partie 2] D1` |
| coût de la demande D2, code promo RENTREE | `[Partie 2] D2` |
| coût de la demande D3, palier à deux cents postes | `[Partie 2] D3` |
| graphe des dépendances et candidats à l'inversion | `[Partie 3]` |

Horodatés de 9h05 à 10h18, ce qui correspond aux 20 minutes de mission 0 et aux
40 minutes de mission 1 annoncées dans le sujet.

## Ce que le script vérifie tout seul

Les 25 tests sont verts **avant** que quoi que ce soit ne soit écrit.

À la fin, `git diff depart-tp2 HEAD -- '*.py'` est **vide**. La mission 1 interdit de
toucher au code, et le script s'arrête si un seul fichier Python a bougé.

Les 25 tests sont toujours verts.

## Les commandes, partie par partie

Tout ce que l'étudiant tape, dans l'ordre. Chaque bloc se termine par son commit.

### Mission 0, l'atelier

```bash
mkdir tp2-tonnom && cd tp2-tonnom
git init

python3 -m venv .venv
source .venv/bin/activate              # Windows : .venv\Scripts\activate
pip install pytest pytest-cov ruff radon xenon

printf '.venv/\n__pycache__/\n*.py[cod]\n.pytest_cache/\n.ruff_cache/\n.coverage\nessai.py\n' > .gitignore
git add .gitignore
git commit -m "chore: depot initialise et gitignore [Mission 0]"
```

```bash
cp -r /chemin/vers/tp2/depart/facturation .
cp    /chemin/vers/tp2/depart/pyproject.toml .

pytest                                  # 25 tests verts avant d'ecrire quoi que ce soit

git add facturation pyproject.toml
git commit -m "chore: code de facturation a auditer [Mission 0]"
git tag depart-tp2
```

### Partie 1, trouver les cinq violations

Une commande par principe. Les trois premières ne lisent aucun corps de fonction.

```bash
# D : un module metier qui importe un module technique, et qui lit l'horloge
grep -n "^from facturation.passerelles\|datetime.now()" facturation/facture.py

# I : une interface trop large, et les implementations qui mentent
grep -c "@abstractmethod" facturation/passerelles.py
grep -n "NotImplementedError" facturation/passerelles.py

# L : une methode redefinie dont le corps ne fait que lever
grep -rn "raise ResiliationImpossible\|raise NotImplementedError" --include="*.py" facturation/

# O : les enchainements de if sur un type, un code, un palier
grep -n "if formule ==\|if code ==\|if nombre_de_postes >=" facturation/tarifs.py

# S : une methode qui calcule, met en forme, puis envoie
grep -n "montant_hors_taxe\|corps = \|envoyer_courriel" facturation/facture.py
```

```bash
git add RAPPORT-CONCEPTION.md
git commit -m "chore: les cinq violations, une par principe [Partie 1]"
```

### Partie 2, chiffrer le coût de chaque demande

Le total des cas de test, puis ceux qui couvrent chaque fonction visée.

```bash
pytest --collect-only | grep -c "::"
```

Attention à un piège : **ne comptez pas par nom de fonction**. Certains tests portent le
nom de la fonction sans la cibler.

```bash
# faux : attrape aussi test_le_montant_est_le_prix_par_poste_fois_le_nombre_de_postes
pytest --collect-only | grep -c "prix_par_poste"          # renvoie 5

# juste : on nomme les tests, pas la fonction
pytest --collect-only | grep -c "test_chaque_formule_a_son_prix_par_poste\|test_une_formule_inconnue_est_refusee"
```

```bash
# D1, la formule decouverte
grep -n "FORMULE_" facturation/abonnements.py
grep -n "def prix_par_poste" -A 9 facturation/tarifs.py
pytest --collect-only | grep -c "test_chaque_formule_a_son_prix_par_poste\|test_une_formule_inconnue_est_refusee"

git add RAPPORT-CONCEPTION.md
git commit -m "chore: cout de la demande D1, formule decouverte [Partie 2] D1"
```

```bash
# D2, le code promo RENTREE
grep -n "def appliquer_code_promo" -A 12 facturation/tarifs.py
pytest --collect-only | grep -c "bienvenue\|noel\|code_promo_inconnu"

git add RAPPORT-CONCEPTION.md
git commit -m "chore: cout de la demande D2, code promo RENTREE [Partie 2] D2"
```

```bash
# D3, le palier a 200 postes
grep -n "def taux_de_remise_volume" -A 7 facturation/tarifs.py
pytest --collect-only | grep -c "remise_volume_suit"

git add RAPPORT-CONCEPTION.md
git commit -m "chore: cout de la demande D3, palier a deux cents postes [Partie 2] D3"
```

### Partie 3, le graphe des dépendances

```bash
grep -rn "^from \|^import " --include="*.py" . | grep -v test_

git add RAPPORT-CONCEPTION.md
git commit -m "chore: graphe des dependances et candidats a l inversion [Partie 3]"
```

### La vérification de fin de mission

La mission 1 interdit de toucher au code. Ces deux commandes doivent passer.

```bash
git diff --quiet depart-tp2 HEAD -- '*.py' && echo "aucun code modifie"
pytest
```

### Attention au double -q

`pyproject.toml` contient déjà `addopts = "-q"`. Si vous écrivez
`pytest --collect-only -q`, pytest passe en mode **très** silencieux et n'affiche plus
aucun identifiant de test : tous les comptages renvoient zéro. Écrivez
`pytest --collect-only`, sans `-q`.

---

## Les quatre points à faire passer en salle

**Trois violations sur cinq se trouvent sans lire un corps de fonction.** `D` se lit dans
l'import ligne 7 de `facture.py`, `I` dans la déclaration ligne 6 de `passerelles.py`,
`L` dans la signature ligne 48 de `abonnements.py`. Le rapport le dit explicitement,
parce que c'est la compétence à transmettre : on diagnostique une conception en lisant
les frontières, pas les algorithmes.

**Le `grep` sur les imports ne trouve que `D`.** Le rapport a une section « ce que le
graphe ne dit pas » : ni le couplage par héritage de `AbonnementAnnuel`, ni celui par
interface de `ClientSMTP` n'apparaissent, puisque parent et enfant sont dans le même
fichier. Un étudiant qui s'arrête à la commande trouve une violation sur cinq. C'est le
moment de dire que l'outil ne remplace pas la lecture.

**La colonne conséquence est ce qui distingue une bonne copie.** « Ce n'est pas
extensible » ne vaut rien. « Ajouter une formule rouvre une fonction couverte par
4 tests » vaut tout. Le corrigé donne pour chaque demande un **détail qui coûte cher**,
et ces trois détails ne se trouvent qu'en lisant vraiment.

**Le piège de D3.** L'ordre des `if` dans `taux_de_remise_volume` porte une règle métier
implicite : les paliers doivent être testés du plus grand au plus petit. Aucun des six
tests actuels ne l'attrape, ils vérifient des valeurs et pas un ordre. C'est exactement
le genre de règle qu'un étudiant casse en mission 4 en refactorisant de bonne foi.
Mieux vaut qu'il l'ait écrit en mission 1.

## Ce que le corrigé ne contient pas

Les missions 2 à 6. La branche s'arrête à la fin du diagnostic, code intact.
