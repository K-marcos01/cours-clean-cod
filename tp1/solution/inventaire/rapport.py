"""Construction et restitution du rapport mensuel de stock.

M8 : le calcul ne modifie aucune donnee et ne lit aucune ressource exterieure.
La date est fournie par l'appelant, jamais lue depuis l'horloge systeme.
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from datetime import date

from inventaire import Article, articles_en_alerte, niveau_alerte, valeur_du_stock

TAUX_TVA = 0.20


@dataclass(frozen=True)
class RapportMensuel:
    """Le resultat du calcul, sans aucune mise en forme."""

    date_du_rapport: str
    nombre_d_articles: int
    valeur_hors_taxe: float
    valeur_toutes_taxes: float
    references_en_alerte: list[str]
    references_en_rupture: list[str]


def generer_rapport(articles: list[Article], date_du_rapport: date) -> RapportMensuel:
    """Calcule le rapport. Fonction pure, aucun effet de bord."""
    valeur_ht = valeur_du_stock(articles)
    return RapportMensuel(
        date_du_rapport=date_du_rapport.isoformat(),
        nombre_d_articles=len(articles),
        valeur_hors_taxe=valeur_ht,
        valeur_toutes_taxes=round(valeur_ht * (1 + TAUX_TVA), 2),
        references_en_alerte=articles_en_alerte(articles),
        references_en_rupture=[
            article.reference for article in articles if niveau_alerte(article) == "rupture"
        ],
    )


def formater_rapport(rapport: RapportMensuel) -> str:
    """Met en forme le rapport pour un lecteur humain."""
    lignes = [
        f"Rapport de stock du {rapport.date_du_rapport}",
        f"  articles suivis      : {rapport.nombre_d_articles}",
        f"  valeur hors taxe     : {rapport.valeur_hors_taxe:.2f}",
        f"  valeur toutes taxes  : {rapport.valeur_toutes_taxes:.2f}",
        f"  references en alerte : {', '.join(rapport.references_en_alerte) or 'aucune'}",
        f"  references en rupture: {', '.join(rapport.references_en_rupture) or 'aucune'}",
    ]
    return "\n".join(lignes)


def exporter_rapport(rapport: RapportMensuel, chemin: str) -> None:
    """Ecrit le rapport en JSON a l'emplacement demande."""
    with open(chemin, "w", encoding="utf-8") as fichier:
        json.dump(asdict(rapport), fichier, ensure_ascii=False, indent=2)
