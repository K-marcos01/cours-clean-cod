"""Les noms de ces tests se lisent comme le cahier des charges du parking."""

from datetime import datetime

import pytest
from parking import DureeInvalide, tarif, tarif_en_cours

UNE_HEURE = 60
UN_JOUR = 24 * 60


# --- E1 : la demi-heure offerte -------------------------------------------


@pytest.mark.parametrize("minutes", [0, 1, 15, 29, 30])
def test_un_stationnement_de_trente_minutes_ou_moins_est_gratuit(minutes):
    assert tarif(minutes) == 0.00


# --- E2 : la demi-heure commencee -----------------------------------------


def test_la_trente_et_unieme_minute_declenche_la_premiere_tranche():
    assert tarif(31) == 1.50


def test_une_heure_pile_ne_coute_qu_une_tranche():
    assert tarif(60) == 1.50


def test_la_soixante_et_unieme_minute_declenche_la_deuxieme_tranche():
    assert tarif(61) == 3.00


@pytest.mark.parametrize("minutes, attendu", [(90, 3.00), (120, 4.50), (150, 6.00)])
def test_chaque_demi_heure_commencee_ajoute_un_euro_cinquante(minutes, attendu):
    assert tarif(minutes) == attendu


# --- E3 : le plafond journalier -------------------------------------------


def test_le_plafond_est_atteint_a_six_heures_trente():
    assert tarif(390) == 18.00


def test_au_dela_du_plafond_le_montant_ne_bouge_plus_dans_la_journee():
    assert tarif(8 * UNE_HEURE) == 18.00
    assert tarif(UN_JOUR) == 18.00


def test_la_vingt_cinquieme_heure_ouvre_une_deuxieme_journee():
    assert tarif(25 * UNE_HEURE) == 36.00


def test_une_journee_commencee_compte_pour_une_journee_entiere():
    assert tarif(UN_JOUR + 1) == 36.00


# --- E4 : l'abonnement ----------------------------------------------------


def test_un_abonne_paie_soixante_pour_cent_du_montant():
    assert tarif(31, est_abonne=True) == 0.90


def test_la_remise_abonne_s_applique_aussi_sur_le_plafond():
    assert tarif(8 * UNE_HEURE, est_abonne=True) == 10.80


def test_un_abonne_ne_paie_rien_pendant_la_gratuite():
    assert tarif(30, est_abonne=True) == 0.00


# --- E5 : le vehicule electrique ------------------------------------------


@pytest.mark.parametrize("minutes", [30, 45, 59, 60])
def test_un_vehicule_electrique_est_gratuit_jusqu_a_une_heure(minutes):
    assert tarif(minutes, est_electrique=True) == 0.00


def test_la_soixante_et_unieme_minute_est_payante_pour_un_electrique():
    assert tarif(61, est_electrique=True) == 1.50


def test_l_avantage_electrique_se_cumule_avec_l_abonnement():
    assert tarif(61, est_abonne=True, est_electrique=True) == 0.90


# --- E6 : les durees impossibles ------------------------------------------


@pytest.mark.parametrize("minutes", [-1, -60])
def test_une_duree_negative_est_refusee(minutes):
    with pytest.raises(DureeInvalide, match="negative"):
        tarif(minutes)


def test_une_sortie_anterieure_a_l_entree_est_refusee():
    entree = datetime(2026, 9, 15, 10, 0)
    sortie = datetime(2026, 9, 15, 9, 0)
    with pytest.raises(DureeInvalide, match="anterieure"):
        tarif_en_cours(entree, sortie)


# --- E7 : la fourriere ----------------------------------------------------


def test_soixante_douze_heures_pile_restent_au_tarif_normal():
    assert tarif(72 * UNE_HEURE) == 54.00


def test_une_minute_de_plus_que_soixante_douze_heures_declenche_la_fourriere():
    assert tarif(72 * UNE_HEURE + 1) == 250.00


def test_la_fourriere_ignore_l_abonnement_et_l_electrique():
    duree = 100 * UNE_HEURE
    assert tarif(duree, est_abonne=True, est_electrique=True) == 250.00


# --- E8 : le montant du a l'instant present -------------------------------


def test_le_montant_en_cours_se_calcule_sur_un_instant_fourni():
    entree = datetime(2026, 9, 15, 8, 0)
    maintenant = datetime(2026, 9, 15, 9, 1)
    assert tarif_en_cours(entree, maintenant) == 3.00


def test_le_montant_en_cours_est_nul_pendant_la_premiere_demi_heure():
    entree = datetime(2026, 9, 15, 8, 0)
    assert tarif_en_cours(entree, datetime(2026, 9, 15, 8, 30)) == 0.00


def test_le_montant_en_cours_ne_depend_pas_de_la_date_reelle():
    # meme duree, a dix ans d'ecart, meme resultat
    en_2026 = tarif_en_cours(datetime(2026, 1, 1, 0, 0), datetime(2026, 1, 1, 2, 0))
    en_2036 = tarif_en_cours(datetime(2036, 6, 30, 0, 0), datetime(2036, 6, 30, 2, 0))
    assert en_2026 == en_2036 == 4.50
