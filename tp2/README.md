# TP2 : ajouter trois règles sans toucher à une seule ligne existante

Durée 5 heures. Travail individuel. Ce qui est rendu et noté, c'est un dépôt git.

Le support du jour 2 est dans `jour2/cours-jour2.md`. Garde-le ouvert.

---

## Le contexte

Trois mois ont passé. Ton module de stock tourne, il est testé, personne ne s'en plaint.

Ce matin la responsable logistique arrive avec trois demandes. Aucune n'est compliquée.
Aucune n'ajoute de règle métier difficile. Et pourtant, si tu les traites comme on
traite habituellement ce genre de demande, tu vas rouvrir du code qui marchait,
rejouer 76 tests, et prendre le risque d'une régression sur des règles qui n'ont
rien à voir.

L'objectif de la journée est de rendre ces trois demandes, et toutes celles qui
suivront, **additives**.

---

## Ce qu'on attend de toi à la fin de la séance

Un dépôt dont l'historique montre deux phases nettement séparées : d'abord tu ouvres,
ensuite tu étends.

Un fichier `RAPPORT-CONCEPTION.md` qui chiffre la rigidité avant et après, en nombre
de fichiers rouverts et de tests à rejouer.

Trois nouvelles règles métier, chacune dans ses propres fichiers, chacune avec ses
propres tests, et **aucune ligne supprimée** dans le code existant.

Deux patrons appliqués, justifiés, et surtout contre-argumentés.

Une violation du principe de substitution démontrée par un test, puis corrigée.

---

## Les règles du jeu

**Règle 1.** Tu pars de ton dépôt du TP1. Si tu ne l'as pas terminé, tu pars de
`tp1/solution/`, qui est complète et testée. Personne ne démarre de zéro.

**Règle 2.** Tu poses deux étiquettes git au cours de la journée. Elles servent à la
correction, ne les oublie pas.

```bash
git tag depart-tp2          # à la fin de la mission 0
git tag ouverture-terminee  # à la fin de la mission 3, première partie
```

**Règle 3.** Les préfixes de commit du jour 1 restent valables. Deux s'ajoutent :

| Préfixe | Quand |
|---|---|
| `refactor:` | tu changes la structure sans changer le comportement |
| `feat:` | tu ajoutes un comportement, dans des fichiers neufs |
| `test:` | tu ajoutes un test sur du comportement existant |
| `fix:` | tu corriges un bug déjà prouvé par un test rouge |
| `chore:` | outillage, configuration, documentation |

**Règle 4.** Tes tests sont verts avant et après chaque commit `refactor:`. Sans exception.

Pour tout ce qui concerne le découpage des commits, ce que chaque préfixe a le droit de
contenir, les messages, le rythme et les commandes de rattrapage, la section
`Commiter : quand, quoi, comment` du sujet du TP1 s'applique telle quelle. Relis-la si
tu hésites.

**Règle 5.** Après l'étiquette `ouverture-terminee`, tu n'as plus le droit de supprimer
ni de modifier une ligne dans un fichier métier existant. Seuls les ajouts de lignes
d'import dans un fichier d'assemblage sont tolérés. C'est vérifié automatiquement.

**Règle 6.** Tu ne modifies aucun test existant. Si un test existant devient faux,
c'est que tu as changé un comportement, donc que tu n'as pas refactorisé.

---

# Mission 0 : le point de départ

**Durée indicative : 20 minutes.**

## Ce que tu produis

Un dépôt de travail, soit le tien issu du TP1, soit une copie de `tp1/solution/`.

Un environnement qui tourne : `pytest` doit être vert du premier coup, avant que tu
n'écrives quoi que ce soit.

Une mesure de départ notée quelque part : nombre de tests, couverture de branches,
temps d'exécution de la suite.

L'étiquette `depart-tp2` posée sur ce premier commit.

**Critère d'acceptation.** `git tag` affiche `depart-tp2`, `pytest` est vert, et
`git status` est propre.

---

# Mission 1 : l'audit de rigidité

**Durée indicative : 40 minutes.**

Hier tu as mesuré la qualité du code. Aujourd'hui tu mesures la qualité de la
**conception**, et ça ne se mesure pas avec les mêmes outils. Aucun outil ne te donnera
ce chiffre. Tu vas le produire à la main.

## Ce que tu produis

Un fichier `RAPPORT-CONCEPTION.md` à la racine. Un modèle est fourni dans `modeles/`.

**Partie 1, le coût des trois demandes.** Pour chacune des trois demandes ci-dessous,
tu ne codes rien. Tu ouvres le code, tu identifies exactement ce qu'il faudrait toucher,
et tu remplis une ligne.

| Demande | Fichiers à rouvrir | Fonctions à modifier | Tests existants à rejouer | Principe SOLID en cause |
|---|---|---|---|---|

Les trois demandes :

**D1.** Ajouter un niveau d'alerte `prealerte`, qui s'applique quand la quantité est
inférieure ou égale au double du seuil, et qui se place entre `alerte` et `normal`.

**D2.** Ajouter un deuxième palier de remise de réapprovisionnement : 20 % à partir de
500 unités commandées, 500 incluses. Le palier existant à 100 unités reste actif.

**D3.** Permettre d'exporter le rapport mensuel au format CSV, en plus du JSON.

**Partie 2, la carte des acteurs.** Tu listes les acteurs qui peuvent demander un
changement sur ce code, et pour chacun, les fichiers qu'il fait bouger. Un fichier qui
apparaît en face de deux acteurs différents est un fichier qui viole SRP, et tu le
signales.

**Partie 3, le graphe des dépendances.** Tu listes, pour chaque module, ce qu'il importe.

```bash
grep -rn "^from \|^import " --include="*.py" . | grep -v test_
```

Tu repères les dépendances qui vont du métier vers un détail technique, et tu les
marques. Ce sont tes candidats à l'inversion.

**Critère d'acceptation.** Un commit `chore: audit de conception` contenant
`RAPPORT-CONCEPTION.md`. Aucun fichier de code modifié, vérifiable par `git diff`.

---

# Mission 2 : séparer les acteurs et inverser les dépendances

**Durée indicative : 70 minutes.**

Ici tu refactorises. Donc : aucun changement de comportement, aucun test modifié,
tous les tests verts après chaque pas.

## Première partie, SRP

Tu sépares le code selon les acteurs identifiés en mission 1. Le calcul métier, la mise
en forme et l'écriture des fichiers ne doivent plus cohabiter.

Ce qui doit être vrai à la fin :

Le module qui contient les règles métier n'importe **aucun** module technique. Ni `json`,
ni `csv`, ni `open`, ni un client de base de données.

Le sens des dépendances va de la technique vers le métier, jamais l'inverse.

Tu peux le prouver en une commande, et cette commande doit figurer dans ton rapport.

## Deuxième partie, DIP

Tu rends testable la fonction qui écrit sur le disque. Le cours donne la technique et
le vocabulaire, à toi de l'appliquer ici.

Ce qui doit être vrai à la fin :

Il existe un test qui vérifie le contenu exporté **sans qu'aucun fichier ne soit créé**
sur le disque. Pas de `tmp_path`, pas de fichier temporaire : le test doit tourner
entièrement en mémoire.

La couverture de branches du code métier atteint 100 %.

Aucun appel à `open` en dehors du module d'infrastructure.

**Critère d'acceptation.** Une succession de commits `refactor:`, pas un commit géant.
`pytest` vert à chaque commit. Le fichier de tests du TP1 est **inchangé**, hors lignes
d'import, vérifiable par `git diff depart-tp2 -- '*test_*.py'`.

---

# Mission 3 : la mission qui compte

**Durée indicative : 80 minutes. Elle pèse 8 points sur 20.**

Elle se déroule en deux temps, et l'ordre n'est pas négociable.

## Temps 1 : ouvrir, sans rien ajouter

**Environ 40 minutes.**

Tu prépares les trois points de variation identifiés en mission 1, pour que les trois
demandes deviennent des ajouts. Tu n'implémentes **aucune** des trois demandes pendant
ce temps.

À la fin de cette phase, le comportement du logiciel est exactement le même qu'au début
de la journée. Les mêmes 76 tests passent, et il n'y en a pas un de plus qui décrive une
nouvelle règle.

Le cours présente trois techniques d'ouverture, du plus léger au plus lourd. Choisis pour
chaque point de variation la plus légère qui fasse le travail, et sois capable de
justifier ton choix à l'oral.

Quand c'est fait :

```bash
git tag ouverture-terminee
```

## Temps 2 : étendre, sans rien modifier

**Environ 40 minutes.**

Tu implémentes D1, D2 et D3.

Contrainte absolue : à partir de l'étiquette `ouverture-terminee`, aucun fichier métier
existant ne perd ni ne voit modifier une seule ligne. Les trois règles arrivent dans des
fichiers neufs, avec leurs tests dans des fichiers neufs.

Seule tolérance : une ligne d'import ajoutée dans un fichier d'assemblage, pour que le
nouveau module soit chargé. Une ligne, pas dix.

## Ce qui est vérifié

```bash
./outils/verifier-ocp.sh /chemin/vers/ton/depot
```

Le script compare l'étiquette `ouverture-terminee` et ton dernier commit. Il refuse toute
ligne supprimée dans un fichier existant, refuse toute modification d'un fichier de test
existant, et vérifie que chacune des trois règles est couverte par au moins un test neuf.

Lance-le avant de rendre.

## Les trois règles, en détail

**D1, le niveau prealerte.** Un article dont la quantité est inférieure ou égale au
double de son seuil, mais supérieure à son seuil, est en `prealerte`. Les niveaux
existants ne changent pas. Un article exactement au seuil reste en `alerte`.

**D2, le palier à 500.** Une remise de 20 % s'applique à partir de 500 unités commandées,
500 incluses. Entre 100 et 499 incluses, la remise de 10 % reste applicable. En dessous
de 100, aucune remise. Les deux remises ne se cumulent pas.

**D3, l'export CSV.** Le rapport s'exporte aussi en CSV : une ligne d'en-têtes, une ligne
de valeurs. Le choix du format se fait sans que le module de calcul ne connaisse
l'existence du CSV.

---

# Mission 4 : deux patrons, et leur procès

**Durée indicative : 50 minutes.**

Tu choisis **deux** patrons parmi les six vus en cours et tu les appliques à ton code.
Au moins l'un des deux doit être Adapter ou Decorator : si tu ne prends que des Strategy,
tu n'auras exploré qu'une seule idée de la journée.

## Ce que tu produis

Pour chaque patron, une section dans `RAPPORT-CONCEPTION.md` avec quatre paragraphes,
chacun de trois phrases maximum.

**Le problème.** Quel symptôme concret, dans ton code, à quelle ligne. Pas « pour être
extensible », mais « la fonction X contient un if qui grossira à chaque nouveau Y ».

**Le choix.** Pourquoi ce patron plutôt qu'un autre. Nomme le patron que tu as écarté et
dis pourquoi.

**Le coût.** Combien de fichiers un lecteur doit-il ouvrir en plus pour suivre un appel,
après ton changement.

**Le procès.** Pourquoi tu aurais pu ne pas le faire. Si tu n'arrives pas à écrire ce
paragraphe honnêtement, c'est probablement que le patron n'avait pas lieu d'être.

Le quatrième paragraphe vaut autant de points que les trois autres réunis.

**Critère d'acceptation.** Les tests restent verts, et un des deux patrons doit permettre
de supprimer du code, pas seulement d'en ajouter. Dis lequel et combien de lignes.

---

# Mission 5 : la hiérarchie qui ment

**Durée indicative : 30 minutes.**

Le fichier `depart/extensions_collegue.py` contient une petite hiérarchie ajoutée en 2023
par le remplaçant de Kevin. Elle n'a jamais été relue et n'a aucun test.

Copie-la dans ton dépôt. Au moins un de ces sous-types ne tient pas le contrat de sa
classe de base.

## Ce que tu fais

**Un.** Tu écris une suite de tests qui décrit le contrat de la classe de base, et tu la
fais tourner sur **tous** les sous-types à la fois. Le cours montre la technique en une
slide. Un seul fichier de tests, pas un par classe.

**Deux.** Tu identifies le ou les sous-types qui échouent, et pour chacun, tu écris dans
ton rapport quelle clause du contrat est brisée : une précondition renforcée, une
postcondition affaiblie, ou une exception nouvelle.

**Trois.** Tu corriges. La bonne correction n'est presque jamais de modifier le test.
Elle consiste à reconnaître que la relation n'était pas un héritage.

**Quatre.** Après correction, la suite de tests partagée passe sur tous les types qui
prétendent encore être des sous-types de la classe de base.

**Critère d'acceptation.** Un commit `test:` contenant la suite partagée et montrant
l'échec, puis un ou plusieurs commits `refactor:` ou `fix:` qui corrigent la hiérarchie.
L'ordre compte.

---

# Le barème

| Ce qui est évalué | Points |
|---|---|
| Hygiène du dépôt, étiquettes posées, messages de commit conformes | 1 |
| Mission 1 : audit chiffré en fichiers, fonctions et tests | 1,5 |
| Mission 1 : carte des acteurs et graphe des dépendances | 0,5 |
| Mission 2 : séparation par acteur, métier sans dépendance technique | 2 |
| Mission 2 : export testé sans toucher au disque, 100 % de branches | 2 |
| Mission 3 : les trois points de variation ouverts avant toute extension | 2 |
| Mission 3 : les trois règles ajoutées, zéro ligne existante supprimée | 4 |
| Mission 3 : chaque règle couverte par ses propres tests neufs | 2 |
| Mission 4 : deux patrons appliqués et justifiés | 1,5 |
| Mission 4 : le procès de chaque patron, écrit honnêtement | 1,5 |
| Mission 5 : violation prouvée par un test avant correction | 2 |
| **Total** | **20** |

Pénalités.

Un test existant modifié sans justification écrite : moins 1 par fichier.

Une ligne supprimée dans un fichier métier après `ouverture-terminee` : moins 1 par
occurrence, dans la limite de 4 points.

Les trois règles implémentées avant l'ouverture, c'est-à-dire l'ordre inversé : moins 3.

Une interface ou une fabrique introduite sans qu'aucune deuxième implémentation
n'existe ni ne soit prévue : moins 1 par occurrence.

---

# Si tu bloques

**Tu ne sais pas quelle technique d'ouverture choisir.** Prends la plus légère qui marche.
Un paramètre avec une valeur par défaut résout plus de cas que tu ne crois.

**Ton refactoring casse un test.** C'est l'information que tu cherchais : tu as changé un
comportement. Annule le dernier pas et refais-en un plus petit.

**Tu ne vois pas comment tester l'export sans fichier.** Demande-toi ce que ton code
appelle vraiment. Remplace l'objet qui sait écrire par un objet qui sait se souvenir.

**Tu n'arrives pas à écrire le procès de ton patron.** C'est un résultat, pas un blocage.
Écris-le tel quel : « je n'arrive pas à justifier pourquoi j'aurais pu m'en passer »,
et retire le patron. Tu auras compris la leçon de l'acte 4.

**Tu as fini en avance.** Trois pistes : ajoute une quatrième règle inventée par toi et
vérifie qu'elle reste additive ; remplace un des deux patrons par sa version Python la
plus légère et compare le nombre de lignes ; ou écris la suite de tests partagée de la
mission 5 sous forme de classe de base réutilisable.
