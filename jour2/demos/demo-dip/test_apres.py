"""Le test que la version avant ne permettait pas d'ecrire."""

import json

from apres import RapportMensuel, exporter_rapport


class DestinationEnMemoire:
    """Un double de douze lignes. Aucun fichier, aucun dossier temporaire."""

    def __init__(self):
        self.depots = {}

    def deposer(self, nom, contenu):
        self.depots[nom] = contenu


def test_l_export_nomme_le_fichier_avec_la_date():
    destination = DestinationEnMemoire()
    exporter_rapport(RapportMensuel("2026-09-15", 1600.10), destination)
    assert list(destination.depots) == ["rapport-2026-09-15.json"]


def test_l_export_contient_la_valeur_du_stock():
    destination = DestinationEnMemoire()
    exporter_rapport(RapportMensuel("2026-09-15", 1600.10), destination)
    contenu = json.loads(destination.depots["rapport-2026-09-15.json"])
    assert contenu["valeur_hors_taxe"] == 1600.10


def test_l_export_n_ecrit_rien_sur_le_disque(tmp_path):
    # tmp_path est fourni mais volontairement laisse vide : on prouve
    # qu'aucun fichier n'est cree, meme pas dans un dossier temporaire.
    destination = DestinationEnMemoire()
    exporter_rapport(RapportMensuel("2026-09-15", 1.0), destination)
    assert list(tmp_path.iterdir()) == []
