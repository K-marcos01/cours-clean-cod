from datetime import datetime

from parking import calculer_montant

def test_stationnement_de_30_minutes_est_gratuit():
    entree = datetime(2024, 1, 1, 8, 0)
    sortie = datetime(2024, 1, 1, 8, 30)

    montant = calculer_montant(entree, sortie)

    assert montant == 0

def test_stationnement_de_45_minutes_facture_une_demi_heure():
    entree = datetime(2024, 1, 1, 8, 0)
    sortie = datetime(2024, 1, 1, 8, 45)

    montant = calculer_montant(entree, sortie)

    assert montant == 1.50