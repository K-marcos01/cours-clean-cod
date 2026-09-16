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

def test_stationnement_de_10_heures_est_plafonne_a_18_euros():
    entree = datetime(2024, 1, 1, 8, 0)
    sortie = datetime(2024, 1, 1, 18, 0)

    montant = calculer_montant(entree, sortie)

    assert montant == 18

def test_stationnement_de_25_heures_plafonne_a_deux_tranches():
    entree = datetime(2024, 1, 1, 8, 0)
    sortie = datetime(2024, 1, 2, 9, 0)  # 25 heures plus tard

    montant = calculer_montant(entree, sortie)

    assert montant == 36

def test_camion_abonne_paie_soixante_pourcent():
    entree = datetime(2024, 1, 1, 8, 0)
    sortie = datetime(2024, 1, 1, 8, 31)

    montant = calculer_montant(entree, sortie, abonne=True)

    assert montant == 0.90

def test_camion_electrique_a_60_minutes_gratuites():
    entree = datetime(2024, 1, 1, 8, 0)
    sortie = datetime(2024, 1, 1, 9, 0)  # 60 minutes

    montant = calculer_montant(entree, sortie, electrique=True)

    assert montant == 0

import pytest


def test_sortie_avant_entree_leve_une_erreur():
    entree = datetime(2024, 1, 1, 9, 0)
    sortie = datetime(2024, 1, 1, 8, 0)  # avant l'entree

    with pytest.raises(ValueError, match="sortie"):
        calculer_montant(entree, sortie)

def test_stationnement_de_73_heures_est_un_forfait_fourriere():
    entree = datetime(2024, 1, 1, 8, 0)
    sortie = datetime(2024, 1, 4, 9, 0)  # 73 heures plus tard

    montant = calculer_montant(entree, sortie)

    assert montant == 250

def test_stationnement_de_72_heures_exactement_nest_pas_fourriere():
    entree = datetime(2024, 1, 1, 8, 0)
    sortie = datetime(2024, 1, 4, 8, 0)  # exactement 72 heures

    montant = calculer_montant(entree, sortie)

    assert montant == 54

def test_fourriere_ignore_abonnement_et_electrique():
    entree = datetime(2024, 1, 1, 8, 0)
    sortie = datetime(2024, 1, 4, 9, 0)  # 73 heures

    montant = calculer_montant(entree, sortie, abonne=True, electrique=True)

    assert montant == 250

def test_camion_encore_stationne_utilise_instant_present():
    entree = datetime(2024, 1, 1, 8, 0)
    maintenant = datetime(2024, 1, 1, 8, 45)

    montant = calculer_montant(entree, maintenant=maintenant)

    assert montant == 1.50