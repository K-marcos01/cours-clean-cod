"""La version inversee : le metier connait un protocole, pas un disque."""

import json
from dataclasses import asdict, dataclass
from typing import Protocol


@dataclass(frozen=True)
class RapportMensuel:
    date_du_rapport: str
    valeur_hors_taxe: float


class Destination(Protocol):
    """Ce dont le metier a besoin. Rien de plus."""

    def deposer(self, nom: str, contenu: str) -> None: ...


def exporter_rapport(rapport: RapportMensuel, destination: Destination) -> None:
    destination.deposer(
        f"rapport-{rapport.date_du_rapport}.json",
        json.dumps(asdict(rapport), ensure_ascii=False, indent=2),
    )


class DisqueLocal:
    """Le detail. Il depend du protocole, le protocole ne depend pas de lui."""

    def __init__(self, dossier: str) -> None:
        self.dossier = dossier

    def deposer(self, nom: str, contenu: str) -> None:
        with open(f"{self.dossier}/{nom}", "w", encoding="utf-8") as fichier:
            fichier.write(contenu)
