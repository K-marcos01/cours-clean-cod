# Mission 2, séparer les acteurs : le corrigé

Ce qui est corrigé ici, c'est la violation de **S** établie dans `analyse-solid.md` :
la numérotation et la présentation sont implémentées sur place dans
`EmetteurDeFactures`, alors qu'elles n'ont pas le même propriétaire.

Tout le code de ce document a été exécuté : 33 tests verts, ruff sans remarque, et le
fichier de tests d'origine identique à l'octet près.

---

## Ce que la mission ne fait pas, volontairement

`ClientSMTP()` reste construit en dur et `datetime.now()` reste dans `emettre`. Ce sont
les deux violations de **D**, elles appartiennent à la mission 3. Mélanger les deux
missions empêcherait de voir ce que chacune apporte.

Aucun test existant n'est modifié et aucun comportement ne change : c'est un
refactoring. `EmetteurDeFactures()` se construit toujours sans argument et `emettre`
garde sa signature.

---

## Les dossiers

**Aucun dossier créé.** L'application fait 200 lignes : trois fichiers neufs suffisent à
donner un domicile à chaque acteur. Créer `metier/`, `presentation/` et
`infrastructure/` obligerait à déplacer les fichiers existants, donc à toucher les
imports du fichier de tests, pour un bénéfice nul à cette taille.

```
facturation/
    __init__.py
    abonnements.py            inchangé
    tarifs.py                 inchangé
    passerelles.py            inchangé
    facture.py                MODIFIÉ   l'orchestration seule
    document.py               NEUF      la facture en tant que donnée
    numerotation.py           NEUF      acteur : la comptabilité
    presentation.py           NEUF      acteur : la communication
    test_facturation.py       inchangé, identique à l'octet près
    test_numerotation.py      NEUF
    test_presentation.py      NEUF
    test_emission.py          NEUF
```

---

## `facture.py`, avant

Une classe, et dedans : la donnée `Facture`, la règle de numérotation, la mise en forme
du document et l'orchestration.

```python
"""Emission des factures d'abonnement."""

from dataclasses import dataclass
from datetime import date, datetime

from facturation.abonnements import Abonnement
from facturation.passerelles import ClientSMTP
from facturation.tarifs import montant_hors_taxe, montant_toutes_taxes

PREFIXE_DE_NUMERO = "FA"


@dataclass
class Facture:
    numero: str
    client: str
    emise_le: date
    montant_ht: float
    montant_ttc: float


class EmetteurDeFactures:
    """Calcule, met en forme et envoie les factures."""

    def __init__(self) -> None:
        self.compteur = 0
        self.passerelle = ClientSMTP()

    def numeroter(self, emise_le: date) -> str:
        self.compteur += 1
        return f"{PREFIXE_DE_NUMERO}-{emise_le.year}-{self.compteur:04d}"

    def emettre(
        self,
        abonnement: Abonnement,
        adresse: str,
        code_promo: str | None = None,
        premiere_facture: bool = False,
    ) -> Facture:
        emise_le = datetime.now().date()
        facture = Facture(
            numero=self.numeroter(emise_le),
            client=abonnement.client,
            emise_le=emise_le,
            montant_ht=montant_hors_taxe(abonnement, code_promo, premiere_facture),
            montant_ttc=montant_toutes_taxes(abonnement, code_promo, premiere_facture),
        )
        corps = "\n".join(
            [
                f"Facture {facture.numero}",
                f"Client        : {facture.client}",
                f"Emise le      : {facture.emise_le.isoformat()}",
                f"Formule       : {abonnement.formule}, {abonnement.nombre_de_postes} postes",
                f"Montant HT    : {facture.montant_ht:.2f}",
                f"Montant TTC   : {facture.montant_ttc:.2f}",
            ]
        )
        self.passerelle.envoyer_courriel(adresse, f"Votre facture {facture.numero}", corps)
        return facture
```

| Élément | Rôle | Acteur |
|---|---|---|
| `Facture` | la donnée | aucun, c'est un enregistrement |
| `self.compteur`, `numeroter()` | la règle de numérotation | la comptabilité |
| le bloc `corps` et l'objet du courriel | la présentation | la communication |
| `emettre()` | l'orchestration | le flux d'émission |

## `facture.py`, après

Il ne reste que l'orchestration. `emettre` est coupée en deux étapes publiques,
`etablir` et `envoyer`, et ne fait plus que les enchaîner.

```python
"""Emission des factures d'abonnement."""

from datetime import date, datetime

from facturation.abonnements import Abonnement
from facturation.document import Facture
from facturation.numerotation import Numeroteur
from facturation.passerelles import ClientSMTP
from facturation.presentation import corps_de_la_facture, objet_du_courriel
from facturation.tarifs import montant_hors_taxe, montant_toutes_taxes


class EmetteurDeFactures:
    """Orchestre l'emission : etablir la facture, puis l'envoyer."""

    def __init__(self) -> None:
        self.numeroteur = Numeroteur()
        self.passerelle = ClientSMTP()

    def etablir(
        self,
        abonnement: Abonnement,
        emise_le: date,
        code_promo: str | None = None,
        premiere_facture: bool = False,
    ) -> Facture:
        return Facture(
            numero=self.numeroteur.suivant(emise_le),
            client=abonnement.client,
            emise_le=emise_le,
            montant_ht=montant_hors_taxe(abonnement, code_promo, premiere_facture),
            montant_ttc=montant_toutes_taxes(abonnement, code_promo, premiere_facture),
        )

    def envoyer(self, facture: Facture, abonnement: Abonnement, adresse: str) -> None:
        self.passerelle.envoyer_courriel(
            adresse, objet_du_courriel(facture), corps_de_la_facture(facture, abonnement)
        )

    def emettre(
        self,
        abonnement: Abonnement,
        adresse: str,
        code_promo: str | None = None,
        premiere_facture: bool = False,
    ) -> Facture:
        facture = self.etablir(abonnement, datetime.now().date(), code_promo, premiere_facture)
        self.envoyer(facture, abonnement, adresse)
        return facture
```

| Avant | Après |
|---|---|
| `Facture` définie ici | importée de `document.py` |
| `self.compteur` et `numeroter()` | `self.numeroteur = Numeroteur()`, la règle vit dans `numerotation.py` |
| le bloc `corps` écrit dans `emettre` | `corps_de_la_facture()` dans `presentation.py` |
| l'objet du courriel écrit dans l'appel d'envoi | `objet_du_courriel()` dans `presentation.py` |
| `emettre` fait tout d'un bloc | `etablir` produit la facture, `envoyer` l'achemine, `emettre` enchaîne les deux |

`etablir` reçoit la date en paramètre alors que `emettre` lit encore l'horloge. C'est
voulu : la mission 3 n'aura plus qu'à remonter ce `datetime.now()` d'un cran.

---

## Les trois fichiers neufs

### `document.py`, la donnée

```python
"""La facture en tant que donnee. Aucun comportement, aucune dependance."""

from dataclasses import dataclass
from datetime import date


@dataclass
class Facture:
    numero: str
    client: str
    emise_le: date
    montant_ht: float
    montant_ttc: float
```

Pourquoi un fichier à part : `presentation.py` a besoin de `Facture`, et `facture.py` a
besoin de `presentation.py`. Laisser `Facture` dans `facture.py` crée un import
circulaire. La donnée descend donc d'un étage, là où tout le monde peut la lire sans
dépendre de l'orchestration.

### `numerotation.py`, la comptabilité

```python
"""La regle de numerotation des factures. Acteur : la comptabilite."""

from datetime import date

PREFIXE_DE_NUMERO = "FA"


class Numeroteur:
    """Attribue des numeros sequentiels de la forme FA-<annee>-<compteur>."""

    def __init__(self) -> None:
        self.compteur = 0

    def suivant(self, emise_le: date) -> str:
        self.compteur += 1
        return f"{PREFIXE_DE_NUMERO}-{emise_le.year}-{self.compteur:04d}"
```

Avant, c'était `numeroter()` et `self.compteur` dans `EmetteurDeFactures`, plus la
constante `PREFIXE_DE_NUMERO` en tête de `facture.py`. Le jour où la comptabilité veut
repartir de 1 chaque année, c'est ce fichier qu'on ouvre, et lui seul.

### `presentation.py`, la communication

```python
"""La presentation d'une facture. Acteur : la communication."""

from facturation.abonnements import Abonnement
from facturation.document import Facture


def objet_du_courriel(facture: Facture) -> str:
    return f"Votre facture {facture.numero}"


def corps_de_la_facture(facture: Facture, abonnement: Abonnement) -> str:
    return "\n".join(
        [
            f"Facture {facture.numero}",
            f"Client        : {facture.client}",
            f"Emise le      : {facture.emise_le.isoformat()}",
            f"Formule       : {abonnement.formule}, {abonnement.nombre_de_postes} postes",
            f"Montant HT    : {facture.montant_ht:.2f}",
            f"Montant TTC   : {facture.montant_ttc:.2f}",
        ]
    )
```

Avant, c'était le bloc `corps = ...` et la chaîne `f"Votre facture ..."` au milieu de
`emettre`. Ce sont maintenant deux fonctions pures : une facture entre, du texte sort,
rien d'autre ne se passe.

---

## Les tests neufs, et ce que chacun prouve

Le fichier `test_facturation.py` n'est pas touché. Les trois fichiers suivants
s'ajoutent.

### `test_numerotation.py`

```python
"""La regle de numerotation se teste sans construire une seule facture."""

from datetime import date

from facturation.numerotation import Numeroteur


def test_le_premier_numero_porte_l_annee_et_le_compteur_sur_quatre_chiffres():
    assert Numeroteur().suivant(date(2019, 3, 5)) == "FA-2019-0001"


def test_les_numeros_se_suivent_sans_rupture():
    numeroteur = Numeroteur()
    numeros = [numeroteur.suivant(date(2019, 3, 5)) for _ in range(3)]
    assert numeros == ["FA-2019-0001", "FA-2019-0002", "FA-2019-0003"]
```

La règle R8 du cahier des charges, le format `FA-<année>-<compteur>`, est testée **en
entier** pour la première fois. Le test d'origine ne pouvait écrire que
`endswith("-0001")`. Et aucune chaîne de présentation n'est construite.

### `test_presentation.py`

```python
"""La presentation se teste sans numeroter ni envoyer."""

from datetime import date

from facturation.abonnements import Abonnement
from facturation.document import Facture
from facturation.presentation import corps_de_la_facture, objet_du_courriel

FACTURE = Facture("FA-2019-0042", "Dupont SARL", date(2019, 3, 5), 57.0, 68.4)
ABONNEMENT = Abonnement("Dupont SARL", "pro", 3, date(2019, 1, 1))


def test_l_objet_porte_le_numero_de_la_facture():
    assert objet_du_courriel(FACTURE) == "Votre facture FA-2019-0042"


def test_le_corps_affiche_les_deux_montants_avec_deux_decimales():
    corps = corps_de_la_facture(FACTURE, ABONNEMENT)
    assert "Montant HT    : 57.00" in corps
    assert "Montant TTC   : 68.40" in corps


def test_le_corps_rappelle_la_formule_et_le_nombre_de_postes():
    assert "Formule       : pro, 3 postes" in corps_de_la_facture(FACTURE, ABONNEMENT)
```

Une assertion sur une chaîne, sans `capsys`, sans envoi, sans compteur.

### `test_emission.py`

```python
"""Ce que la separation rend possible : relancer un envoi sans consommer de numero."""

from datetime import date

import pytest

from facturation.abonnements import Abonnement
from facturation.facture import EmetteurDeFactures
from facturation.presentation import corps_de_la_facture

ABONNEMENT = Abonnement("Dupont SARL", "pro", 3, date(2019, 1, 1))


class PasserelleEnPanne:
    def envoyer_courriel(self, *_):
        raise ConnectionError("serveur mail injoignable")


def test_etablir_calcule_la_facture_sans_rien_envoyer(capsys):
    facture = EmetteurDeFactures().etablir(ABONNEMENT, date(2019, 3, 5))
    assert facture.numero == "FA-2019-0001"
    assert facture.montant_ht == 57.0
    assert capsys.readouterr().out == ""


def test_produire_le_texte_ne_fait_pas_avancer_le_compteur():
    emetteur = EmetteurDeFactures()
    facture = emetteur.etablir(ABONNEMENT, date(2019, 3, 5))
    corps_de_la_facture(facture, ABONNEMENT)
    corps_de_la_facture(facture, ABONNEMENT)
    assert emetteur.etablir(ABONNEMENT, date(2019, 3, 5)).numero == "FA-2019-0002"


def test_un_envoi_en_echec_se_relance_avec_la_meme_facture(capsys):
    emetteur = EmetteurDeFactures()
    facture = emetteur.etablir(ABONNEMENT, date(2019, 3, 5))
    passerelle_d_origine = emetteur.passerelle
    emetteur.passerelle = PasserelleEnPanne()
    with pytest.raises(ConnectionError):
        emetteur.envoyer(facture, ABONNEMENT, "compta@dupont.fr")
    emetteur.passerelle = passerelle_d_origine
    emetteur.envoyer(facture, ABONNEMENT, "compta@dupont.fr")
    assert "FA-2019-0001" in capsys.readouterr().out
    assert emetteur.etablir(ABONNEMENT, date(2019, 3, 5)).numero == "FA-2019-0002"
```

Les deux derniers tests sont la raison d'être de la mission. Ils démontrent que le
défaut mesuré dans l'analyse a disparu : produire le texte ne consomme plus de numéro,
et un envoi en échec se relance **avec la même facture**, donc sans trou dans la
séquence.

---

## Le défaut d'origine, avant et après

| Situation | Avant | Après |
|---|---|---|
| obtenir le texte d'une facture | impossible sans appeler `emettre`, donc sans numéroter et envoyer | `corps_de_la_facture(facture, abonnement)`, fonction pure |
| un envoi échoue | le numéro est consommé, la facture suivante porte `0002`, le `0001` n'existe nulle part | on rappelle `envoyer` avec la même facture, le `0001` finit par partir |
| tester le format du numéro | `endswith("-0001")` seulement | `== "FA-2019-0001"` |
| changer la présentation | rouvrir `emettre` | ouvrir `presentation.py` |

---

## La suite de commits

Des petits pas, les 25 tests verts après chacun.

| # | Message | Ce qui bouge |
|---|---|---|
| 1 | `refactor: la donnee Facture descend dans document.py` | `document.py` neuf, `facture.py` l'importe |
| 2 | `refactor: la presentation de la facture sort de emettre` | `presentation.py` neuf, `emettre` appelle les deux fonctions |
| 3 | `test: la presentation se teste sans numeroter ni envoyer` | `test_presentation.py` |
| 4 | `refactor: la regle de numerotation sort de l emetteur` | `numerotation.py` neuf, `numeroter()` et `self.compteur` disparaissent |
| 5 | `test: la regle de numerotation se teste seule` | `test_numerotation.py` |
| 6 | `refactor: emettre se decoupe en etablir puis envoyer` | `facture.py` |
| 7 | `test: relancer un envoi ne consomme plus de numero` | `test_emission.py` |

Le commit 1 vient en premier pour une raison mécanique : sans lui, le commit 2 crée un
import circulaire.

---

## Les vérifications

```bash
pytest                                                        # 33 passed
ruff check . && ruff format --check .

# le fichier de tests d'origine n'a pas bougé
git diff --quiet depart-tp2 HEAD -- facturation/test_facturation.py && echo "intact"

# les modules des acteurs n'importent rien de technique
grep -n "^from \|^import " facturation/tarifs.py facturation/numerotation.py facturation/presentation.py
```

Sortie de la dernière commande :

```
facturation/tarifs.py:3:from facturation.abonnements import (
facturation/presentation.py:3:from facturation.abonnements import Abonnement
facturation/presentation.py:4:from facturation.document import Facture
facturation/numerotation.py:3:from datetime import date
```

Aucun `smtplib`, aucun `passerelles`, aucun `open`. Le seul fichier qui connaît encore un
détail technique est `facture.py`, par son import de `ClientSMTP`. C'est la mission 3.
