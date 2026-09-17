"""Gestion du stock d'un entrepot.

Les regles metier de reference sont celles du sujet du TP1, sections M1 a M8.
Les trois ecarts trouves dans la version de Kevin sont corriges ici :
seuil d'alerte inclusif, stock inchange quand un retrait est refuse,
et remise accordee a partir de 100 unites incluses.

Limite connue : les montants sont des flottants arrondis au centime. Pour une
comptabilite reelle il faudrait des Decimal. Voir la piste du jour 3.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, replace

MULTIPLICATEUR_DE_REAPPROVISIONNEMENT = 3
QUANTITE_MINIMALE_POUR_REMISE = 100
TAUX_DE_REMISE_GROS_VOLUME = 0.10
JOURS_DE_LA_PERIODE_DE_VENTE = 30
CATEGORIE_PAR_DEFAUT = "autre"


class QuantiteInvalide(ValueError):
    """La quantite demandee est nulle ou negative."""


class StockInsuffisant(ValueError):
    """Le retrait demande depasse le stock disponible."""


class AucuneVenteSurLaPeriode(ValueError):
    """Impossible de calculer une rotation sans vente sur la periode."""


@dataclass(frozen=True)
class Article:
    """Un article du stock, immuable."""

    reference: str
    libelle: str
    quantite: int
    prix_unitaire: float
    seuil_alerte: int
    categorie: str = CATEGORIE_PAR_DEFAUT

    @property
    def valeur(self) -> float:
        """Valeur hors taxe du stock de cet article."""
        return self.quantite * self.prix_unitaire

    @property
    def est_en_alerte(self) -> bool:
        """M2 : un article au seuil exactement est en alerte."""
        return self.quantite <= self.seuil_alerte


def valeur_du_stock(articles: list[Article]) -> float:
    """M1 : somme des valeurs des articles, arrondie au centime."""
    return round(sum(article.valeur for article in articles), 2)


def articles_en_alerte(articles: list[Article]) -> list[str]:
    """M2 : references des articles dont la quantite est sous le seuil ou egale."""
    return [article.reference for article in articles if article.est_en_alerte]


def niveau_alerte(article: Article) -> str:
    """Gravite de la situation de stock d'un article."""
    if article.quantite == 0:
        return "rupture"
    if article.quantite * 2 <= article.seuil_alerte:
        return "critique"
    if article.est_en_alerte:
        return "alerte"
    return "normal"


def _verifier_quantite(quantite: int) -> None:
    """M4 : une quantite de mouvement nulle ou negative est refusee."""
    if quantite <= 0:
        raise QuantiteInvalide(f"quantite invalide : {quantite}")


def retirer(article: Article, quantite: int) -> Article:
    """M3 et M4 : renvoie un nouvel article, ou leve sans rien modifier."""
    _verifier_quantite(quantite)
    if quantite > article.quantite:
        raise StockInsuffisant(
            f"{article.reference} : {quantite} demandes, {article.quantite} disponibles"
        )
    return replace(article, quantite=article.quantite - quantite)


def ajouter(article: Article, quantite: int) -> Article:
    """M4 : renvoie un nouvel article avec la quantite ajoutee."""
    _verifier_quantite(quantite)
    return replace(article, quantite=article.quantite + quantite)


def quantite_a_commander(article: Article) -> int:
    """Quantite necessaire pour remonter a trois fois le seuil d'alerte."""
    if not article.est_en_alerte:
        return 0
    cible = article.seuil_alerte * MULTIPLICATEUR_DE_REAPPROVISIONNEMENT
    return cible - article.quantite


def cout_de_reapprovisionnement(article: Article) -> float:
    """M5 : remise de 10 pour cent a partir de 100 unites commandees, 100 incluses."""
    quantite = quantite_a_commander(article)
    if quantite == 0:
        return 0.0
    cout = quantite * article.prix_unitaire
    if quantite >= QUANTITE_MINIMALE_POUR_REMISE:
        cout *= 1 - TAUX_DE_REMISE_GROS_VOLUME
    return round(cout, 2)


def classer_par_valeur(articles: list[Article]) -> list[Article]:
    """M6 : tri par valeur de stock decroissante, sans modifier la liste d'origine."""
    return sorted(articles, key=lambda article: article.valeur, reverse=True)


def rotation_en_jours(article: Article, ventes_sur_la_periode: int) -> int:
    """M7 : jours de stock restants, arrondis a l'entier inferieur."""
    if ventes_sur_la_periode <= 0:
        raise AucuneVenteSurLaPeriode(
            f"{article.reference} : aucune vente sur {JOURS_DE_LA_PERIODE_DE_VENTE} jours"
        )
    ventes_par_jour = ventes_sur_la_periode / JOURS_DE_LA_PERIODE_DE_VENTE
    return math.floor(article.quantite / ventes_par_jour)


def valeur_par_categorie(articles: list[Article]) -> dict[str, float]:
    """Valeur du stock ventilee par categorie, arrondie au centime."""
    totaux: dict[str, float] = {}
    for article in articles:
        totaux[article.categorie] = totaux.get(article.categorie, 0.0) + article.valeur
    return {categorie: round(valeur, 2) for categorie, valeur in totaux.items()}
