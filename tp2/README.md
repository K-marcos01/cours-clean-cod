# TP2 : cinq violations dans un code qui marche

Durée 5 heures. Travail individuel. Ce qui est rendu et noté, c'est un dépôt git.

Le support du jour 2 est dans `jour2/cours-jour2.md`. Garde-le ouvert.

---

## Le contexte

Tu reprends la facturation d'une application d'abonnements logiciels, en service depuis
trois ans. Le code est dans `depart/`, et il n'a rien d'un code sale.

25 tests, tous verts. Complexité maximale au rang A. Zéro problème ruff. Aucune fonction
de plus de vingt lignes. Des noms compréhensibles sans commentaire. Sur tous les critères
du jour 1, ce code est irréprochable.

Et pourtant, trois demandes arrivent lundi matin, et chacune oblige à rouvrir du code qui
marche.

**Personne ne te demande de corriger un bug.** On te demande de rendre ce code
modifiable.

---

## Ce qu'on attend de toi à la fin de la séance

Un fichier `RAPPORT-CONCEPTION.md` qui localise les cinq violations, une par principe,
avec fichier, ligne et conséquence concrète.

Un code métier qui ne connaît plus ni le réseau, ni l'horloge, ni la mise en forme.

Trois nouvelles règles de tarification, chacune dans ses propres fichiers, avec ses
propres tests, et **aucune ligne supprimée** dans le code existant.

Une violation du principe de substitution démontrée par une suite de tests partagée,
puis corrigée par composition.

---

## Les règles du jeu

**Règle 1.** Tu copies `depart/` dans ton propre dépôt et tu fais `git init`. Tu ne
travailles jamais sans dépôt.

**Règle 2.** Tu poses deux étiquettes git au cours de la journée. Elles servent à la
correction, ne les oublie pas.

```bash
git tag depart-tp2          # a la fin de la mission 0
git tag ouverture-terminee  # a la fin de la mission 4, premier temps
```

**Règle 3.** Les préfixes de commit du TP1 restent valables. Pour tout ce qui concerne
le découpage des commits, les messages et le rythme, la section `Commiter : quand, quoi,
comment` du sujet du TP1 s'applique telle quelle.

| Préfixe | Quand |
|---|---|
| `refactor:` | tu changes la structure sans changer le comportement |
| `feat:` | tu ajoutes un comportement, dans des fichiers neufs |
| `test:` | tu ajoutes un test sur du comportement existant |
| `fix:` | tu corriges un bug déjà prouvé par un test rouge |
| `chore:` | outillage, configuration, documentation |

**Règle 4.** Tes 25 tests de départ sont verts avant et après chaque commit `refactor:`.
Sans exception.

**Règle 5.** Tu ne modifies aucun test existant, sauf en mission 5 et avec justification
écrite. Si un test existant devient faux, c'est que tu as changé un comportement, donc
que tu n'as pas refactorisé.

**Règle 6.** Après l'étiquette `ouverture-terminee`, tu n'as plus le droit de supprimer
ni de modifier une ligne dans un fichier métier existant. Seuls les ajouts de lignes
d'import dans un fichier d'assemblage sont tolérés. C'est vérifié automatiquement.

---

# Mission 0 : prendre en main

**Durée indicative : 20 minutes.**

## Ce que tu produis

Un dossier `tp2-tonnom`, copie de `depart/`, initialisé en dépôt git.

Un environnement qui tourne : `pytest` doit afficher 25 tests verts du premier coup,
avant que tu n'écrives quoi que ce soit.

Un `.gitignore` qui exclut au minimum `.venv/`, `__pycache__/`, `.pytest_cache/` et
`.ruff_cache/`.

L'étiquette `depart-tp2` posée sur ce premier commit.

## Avant d'aller plus loin

Lis `depart/README.md`. Il contient les **neuf règles métier** de l'application. Elles
font foi pendant toute la séance. Quand le code s'en écarte, c'est le code qui a tort.

Lance aussi le code pour voir ce qu'il fait. Un fichier `essai.py` à la racine, que tu
supprimeras ensuite :

```python
from datetime import date

from facturation.abonnements import Abonnement
from facturation.facture import EmetteurDeFactures

abonnement = Abonnement("Dupont SARL", "pro", 12, date(2026, 1, 1))
print(EmetteurDeFactures().emettre(abonnement, "compta@dupont.fr"))
```

```bash
python essai.py
```

Un fichier plutôt qu'un `python -c` d'une ligne : sous Windows, `cmd` ne sait pas
découper une chaîne entre guillemets sur plusieurs lignes, et la commande échoue avec
une erreur de syntaxe.

**Critère d'acceptation.** `git tag` affiche `depart-tp2`, `pytest` est vert,
`git status` est propre.

---

# Mission 1 : le diagnostic

**Durée indicative : 40 minutes.**

Cinq violations ont été introduites dans ce code, **une par principe**. Elles sont toutes
localisables sans connaître le métier. Tu ne corriges rien pendant cette mission.

## Ce que tu produis

Un fichier `RAPPORT-CONCEPTION.md` à la racine. Un modèle est fourni dans `modeles/`.

**Partie 1, les cinq violations.** Une ligne par principe.

| Principe | Fichier et ligne | Le symptôme observable | La conséquence concrète |
|---|---|---|---|

Pour la colonne symptôme, on attend un fait vérifiable, pas une opinion. « La fonction
enchaîne trois `if` sur la formule » est un fait. « Le code est mal conçu » n'en est pas un.

Pour la colonne conséquence, on attend ce qui arrive à quelqu'un, pas une généralité.
« Ajouter une formule oblige à rouvrir une fonction couverte par quatre tests » est une
conséquence. « Ce n'est pas extensible » n'en est pas une.

**Partie 2, le coût des trois demandes.** Pour chacune des trois demandes ci-dessous,
tu ne codes rien. Tu identifies ce qu'il faudrait toucher.

| Demande | Fichiers à rouvrir | Fonctions à modifier | Tests existants à rejouer |
|---|---|---|---|

**D1.** Ajouter une formule `decouverte` à 4 euros par poste.

**D2.** Ajouter un code promotionnel `RENTREE` qui retire 10 %.

**D3.** Ajouter un troisième palier de remise sur le volume : 30 % à partir de 200 postes.

**Partie 3, le graphe des dépendances.** Pour chaque module, ce qu'il importe.

```bash
grep -rn "^from \|^import " --include="*.py" . | grep -v test_
```

Tu repères les dépendances qui vont du métier vers un détail technique et tu les marques.
Ce sont tes candidats à l'inversion.

## Un indice, et un seul

Trois des cinq violations se voient dans les **imports** et les **signatures**, sans lire
une seule ligne de corps de fonction.

**Critère d'acceptation.** Un commit `chore: diagnostic de conception`. Aucun fichier de
code modifié, vérifiable par `git diff depart-tp2 -- '*.py'`.

---

# Mission 2 : séparer les acteurs

**Durée indicative : 50 minutes.**

Ici tu refactorises. Donc aucun changement de comportement, aucun test modifié, tous les
tests verts après chaque pas.

## Ce que tu produis

Le code se répartit selon les acteurs identifiés en mission 1. Le calcul des montants, la
mise en forme de la facture et son acheminement ne doivent plus cohabiter dans la même
méthode.

Ce qui doit être vrai à la fin.

Il existe une fonction qui produit le **corps de la facture** sans rien envoyer, et on
peut la tester en une assertion sur une chaîne de caractères.

Il existe une fonction ou une méthode qui **calcule** la facture sans rien mettre en
forme, et on peut la tester sans construire une seule chaîne.

Le module qui contient les règles de tarification n'importe **aucun** module technique.

Tu peux le prouver en une commande, et cette commande figure dans ton rapport.

**Critère d'acceptation.** Une succession de commits `refactor:`, pas un commit géant.
Les 25 tests de départ sont inchangés, hors lignes d'import, vérifiable par
`git diff depart-tp2 -- '*test_*.py'`.

---

# Mission 3 : sortir le monde extérieur du métier

**Durée indicative : 60 minutes.**

Deux principes ici, et ils se répondent.

## Première partie, DIP

Le module de facturation connaît aujourd'hui deux choses qu'il ne devrait pas connaître :
un fournisseur d'envoi concret, et l'horloge de la machine.

Ce qui doit être vrai à la fin.

Aucun module métier n'importe `passerelles`. Vérifiable par `grep`.

Aucun appel à `datetime.now()` en dehors du point d'assemblage.

Il existe un test qui vérifie **le destinataire et le sujet** d'une facture envoyée,
sans qu'aucun courriel ne parte et sans capturer la sortie standard. Pas de `capsys`.

Il existe un test qui vérifie que le numéro de facture porte **l'année 2019**, ce qui est
aujourd'hui impossible à écrire.

## Deuxième partie, ISP

L'interface que le métier utilise pour envoyer doit être **à la taille de son besoin**.

Ce qui doit être vrai à la fin.

Le double que tu écris dans tes tests implémente **une seule** méthode.

Plus aucune classe du projet ne contient `NotImplementedError` pour une méthode qu'elle
est censée fournir.

Le protocole est déclaré **du côté du client**, pas du côté du fournisseur. Tu dois
pouvoir expliquer à l'oral pourquoi ça compte.

**Critère d'acceptation.** Les 25 tests de départ toujours verts, plus les deux tests
neufs décrits ci-dessus. La couverture de branches du module de facturation atteint
100 %.

---

# Mission 4 : la mission qui compte

**Durée indicative : 70 minutes. Elle pèse 7 points sur 20.**

Elle se déroule en deux temps, et l'ordre n'est pas négociable.

## Temps 1 : ouvrir, sans rien ajouter

**Environ 30 minutes.**

Tu prépares les points de variation pour que les trois demandes D1, D2 et D3 deviennent
des ajouts. Tu n'implémentes **aucune** des trois pendant ce temps.

À la fin de cette phase, le comportement est exactement le même qu'au début de la
journée. Les mêmes tests passent, et il n'y en a pas un de plus qui décrive une nouvelle
règle.

Le cours présente trois techniques d'ouverture, de la donnée au polymorphisme. Choisis
pour chaque point la plus **légère** qui fasse le travail, et sois capable de justifier
ton choix. Deux des trois se règlent sans écrire une seule classe.

```bash
git tag ouverture-terminee
```

## Temps 2 : étendre, sans rien modifier

**Environ 40 minutes.**

Tu implémentes D1, D2 et D3.

Contrainte absolue : à partir de l'étiquette, aucun fichier métier existant ne perd ni ne
voit modifier une seule ligne. Les trois règles arrivent dans des fichiers neufs, avec
leurs tests dans des fichiers neufs.

Seule tolérance : une ligne d'import ajoutée dans un fichier d'assemblage, pour que le
nouveau module soit chargé. Une ligne, pas dix.

## Les trois règles, en détail

**D1.** La formule `decouverte` coûte 4 euros par poste. Les trois formules existantes
ne changent pas. Une formule inconnue reste refusée.

**D2.** Le code `RENTREE` retire 10 % du montant, sans condition de première facture. Les
codes existants ne changent pas.

**D3.** Un troisième palier de remise sur le volume : 30 % à partir de 200 postes,
200 inclus. Les paliers à 10 et 50 postes restent en vigueur.

## Ce qui est vérifié

```bash
./outils/verifier-ocp.sh /chemin/vers/ton/depot
```

Le script compare les deux étiquettes. Il refuse toute ligne supprimée dans un fichier
existant, toute modification d'un fichier de test existant, et vérifie que chaque règle
est couverte par au moins un test neuf. Lance-le avant de rendre.

---

# Mission 5 : la hiérarchie qui ment

**Durée indicative : 40 minutes.**

Trois sous-types d'abonnement existent dans le code. L'un d'eux ne tient pas le contrat de
sa classe de base. Ce contrat est écrit noir sur blanc dans la docstring du parent.

## Ce que tu fais

**Un.** Tu écris une suite de tests qui décrit le contrat de la classe de base, et tu la
fais tourner sur **tous** les sous-types à la fois. Le cours montre la technique en une
slide. Un seul fichier de tests, pas un par classe.

**Deux.** Tu identifies le sous-type qui échoue, et tu écris dans ton rapport quelle
clause du contrat est brisée : une précondition renforcée, une postcondition affaiblie,
ou une exception nouvelle.

**Trois.** Tu corriges. Le cours donne trois issues possibles. La bonne, ici, transforme
un problème de substitution en un point de variation, ce que tu sais déjà traiter depuis
la mission 4.

**Quatre.** Après correction, la suite partagée passe sur tous les types qui prétendent
encore être des sous-types de la classe de base. Et la règle métier reste vraie : un
abonnement annuel ne peut toujours pas être résilié avant son terme.

Attention à ce dernier point. Supprimer la règle n'est pas la corriger.

**Critère d'acceptation.** Un commit `test:` contenant la suite partagée et montrant
l'échec, puis un ou plusieurs commits `refactor:` qui corrigent la hiérarchie. L'ordre
compte.

---

# Mission 6 : le bilan

**Durée indicative : 20 minutes.**

Tu complètes `RAPPORT-CONCEPTION.md`.

**Le coût des trois demandes, après.** Mêmes colonnes qu'en mission 1. C'est le delta qui
est noté.

**Pour chaque principe, ce que tu as fait et ce que ça t'a coûté.** Trois phrases
maximum par principe, dont une sur le coût : combien de fichiers un lecteur doit-il
ouvrir en plus pour suivre un appel.

**Le procès.** Une abstraction que tu as introduite et dont tu n'es pas sûr. Explique
pourquoi tu aurais pu ne pas la faire. Si tu n'arrives pas à écrire ce paragraphe
honnêtement, c'est probablement qu'elle n'avait pas lieu d'être, et il est encore temps
de la retirer.

Ce dernier paragraphe vaut autant de points que les cinq précédents réunis.

---

# Le barème

| Ce qui est évalué | Points |
|---|---|
| Hygiène du dépôt, étiquettes posées, messages de commit conformes | 1 |
| Mission 1 : les cinq violations localisées, avec fichier et ligne | 2 |
| Mission 1 : coût des trois demandes, chiffré en fichiers et en tests | 1 |
| Mission 2 : les trois acteurs séparés, métier sans dépendance technique | 2,5 |
| Mission 3 : DIP, aucun import technique dans le métier, horloge injectée | 2 |
| Mission 3 : ISP, un double de test à une seule méthode | 1,5 |
| Mission 4 : les trois points de variation ouverts avant toute extension | 2 |
| Mission 4 : les trois règles ajoutées, zéro ligne existante supprimée | 3 |
| Mission 4 : chaque règle couverte par ses propres tests neufs | 2 |
| Mission 5 : violation prouvée par une suite partagée avant correction | 1,5 |
| Mission 5 : correction qui préserve la règle métier | 0,5 |
| Mission 6 : le procès d'une de tes abstractions, écrit honnêtement | 1 |
| **Total** | **20** |

Pénalités.

Un test existant modifié sans justification écrite : moins 1 par fichier.

Une ligne supprimée dans un fichier métier après `ouverture-terminee` : moins 1 par
occurrence, dans la limite de 3 points.

Les trois règles implémentées avant l'ouverture, c'est-à-dire l'ordre inversé : moins 3.

Une interface ou une classe abstraite introduite sans qu'aucune deuxième implémentation
n'existe ni ne soit prévue : moins 1 par occurrence.

La règle métier de l'abonnement annuel supprimée au lieu d'être déplacée : moins 2.

---

# Si tu bloques

**Tu ne trouves pas les cinq violations.** Commence par les imports et les signatures.
Trois des cinq s'y voient sans lire un seul corps de fonction.

**Tu ne sais pas quelle technique d'ouverture choisir.** Prends la plus légère qui marche.
Un dictionnaire résout plus de cas que tu ne crois.

**Ton refactoring casse un test.** C'est l'information que tu cherchais : tu as changé un
comportement. Annule le dernier pas et refais-en un plus petit.

**Tu n'arrives pas à tester l'envoi sans capturer la sortie.** Demande-toi ce que ton code
appelle vraiment. Remplace l'objet qui sait envoyer par un objet qui sait se souvenir.

**Tu as corrigé LSP en supprimant la règle métier.** Relis la mission 5. La règle doit
survivre, c'est sa place dans la hiérarchie qui doit changer.

**Tu as fini en avance.** Trois pistes : ajoute un canal d'envoi par SMS et vérifie qu'il
reste additif, applique SOLID au code de ton TP1, ou écris la suite de tests partagée de
la mission 5 sous forme de classe de base réutilisable.
