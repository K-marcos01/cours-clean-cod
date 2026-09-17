"""La version du TP1 : le metier connait le disque."""

import json
from dataclasses import asdict, dataclass


@dataclass(frozen=True)
class RapportMensuel:
    date_du_rapport: str
    valeur_hors_taxe: float


def exporter_rapport(rapport: RapportMensuel, chemin: str) -> None:
    with open(chemin, "w", encoding="utf-8") as fichier:
        json.dump(asdict(rapport), fichier, ensure_ascii=False, indent=2)
