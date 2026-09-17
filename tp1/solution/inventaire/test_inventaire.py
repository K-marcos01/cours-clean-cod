"""Filet de tests du module de stock. Un test, un comportement."""

from datetime import date

import pytest
from rapport import formater_rapport, generer_rapport

from inventaire import (
    Article,
    AucuneVenteSurLaPeriode,
    QuantiteInvalide,
    StockInsuffisant,
    ajouter,
    articles_en_alerte,
    classer_par_valeur,
    cout_de_reapprovisionnement,
    niveau_alerte,
    quantite_a_commander,
    retirer,
    rotation_en_jours,
    valeur_du_stock,
    valeur_par_categorie,
)


def article(**surcharges) -> Article:
    """Construit un article de test, surchargeable champ par champ."""
    valeurs = {
        "reference": "VIS-M6",
        "libelle": "Vis M6 acier",
        "quantite": 50,
        "prix_unitaire": 2.0,
        "seuil_alerte": 10,
        "categorie": "piece",
    }
    valeurs.update(surcharges)
    return Article(**valeurs)


# --- M1 : valeur du stock -------------------------------------------------


def test_un_stock_vide_vaut_zero():
    assert valeur_du_stock([]) == 0


def test_la_valeur_du_stock_est_la_somme_des_lignes():
    articles = [article(quantite=2, prix_unitaire=1.5), article(quantite=3, prix_unitaire=2.0)]
    assert valeur_du_stock(articles) == 9.0


def test_la_valeur_du_stock_est_arrondie_au_centime():
    assert valeur_du_stock([article(quantite=3, prix_unitaire=0.333)]) == 1.0


# --- M2 : alertes ---------------------------------------------------------


@pytest.mark.parametrize(
    "quantite, attendu",
    [(0, True), (5, True), (9, True), (10, True), (11, False), (50, False)],
)
def test_un_article_est_en_alerte_jusqu_au_seuil_inclus(quantite, attendu):
    assert article(quantite=quantite, seuil_alerte=10).est_en_alerte is attendu


def test_un_article_exactement_au_seuil_est_signale():
    en_alerte = article(reference="GANT-L", quantite=5, seuil_alerte=5)
    assert articles_en_alerte([en_alerte]) == ["GANT-L"]


def test_seules_les_references_en_alerte_sont_renvoyees():
    articles = [
        article(reference="BAS", quantite=1, seuil_alerte=10),
        article(reference="HAUT", quantite=99, seuil_alerte=10),
    ]
    assert articles_en_alerte(articles) == ["BAS"]


@pytest.mark.parametrize(
    "quantite, niveau",
    [
        (0, "rupture"),
        (4, "critique"),
        (5, "critique"),
        (6, "alerte"),
        (10, "alerte"),
        (11, "normal"),
    ],
)
def test_le_niveau_d_alerte_depend_de_la_distance_au_seuil(quantite, niveau):
    assert niveau_alerte(article(quantite=quantite, seuil_alerte=10)) == niveau


# --- M3 et M4 : mouvements ------------------------------------------------


def test_un_retrait_diminue_la_quantite():
    assert retirer(article(quantite=50), 10).quantite == 40


def test_un_retrait_egal_au_stock_est_accepte():
    assert retirer(article(quantite=50), 50).quantite == 0


def test_un_retrait_superieur_au_stock_est_refuse():
    with pytest.raises(StockInsuffisant, match="51 demandes"):
        retirer(article(quantite=50), 51)


def test_un_retrait_refuse_laisse_le_stock_intact():
    origine = article(quantite=50)
    with pytest.raises(StockInsuffisant):
        retirer(origine, 51)
    assert origine.quantite == 50


@pytest.mark.parametrize("quantite", [0, -1, -100])
def test_un_mouvement_de_quantite_nulle_ou_negative_est_refuse(quantite):
    with pytest.raises(QuantiteInvalide):
        retirer(article(), quantite)
    with pytest.raises(QuantiteInvalide):
        ajouter(article(), quantite)


def test_un_ajout_augmente_la_quantite():
    assert ajouter(article(quantite=50), 25).quantite == 75


def test_un_mouvement_ne_modifie_jamais_l_article_d_origine():
    origine = article(quantite=50)
    retirer(origine, 10)
    ajouter(origine, 10)
    assert origine.quantite == 50


# --- M5 : reapprovisionnement ---------------------------------------------


def test_un_article_hors_alerte_ne_coute_rien_a_reapprovisionner():
    assert cout_de_reapprovisionnement(article(quantite=50, seuil_alerte=10)) == 0.0


def test_la_quantite_commandee_remonte_a_trois_fois_le_seuil():
    assert quantite_a_commander(article(quantite=4, seuil_alerte=10)) == 26


def test_le_cout_sans_remise_est_la_quantite_fois_le_prix():
    en_alerte = article(quantite=4, seuil_alerte=10, prix_unitaire=2.0)
    assert cout_de_reapprovisionnement(en_alerte) == 52.0


def test_la_remise_s_applique_a_exactement_cent_unites():
    # seuil 40 donne une cible de 120, quantite 20 donne 100 unites commandees
    en_alerte = article(quantite=20, seuil_alerte=40, prix_unitaire=1.0)
    assert quantite_a_commander(en_alerte) == 100
    assert cout_de_reapprovisionnement(en_alerte) == 90.0


def test_la_remise_ne_s_applique_pas_a_quatre_vingt_dix_neuf_unites():
    en_alerte = article(quantite=21, seuil_alerte=40, prix_unitaire=1.0)
    assert quantite_a_commander(en_alerte) == 99
    assert cout_de_reapprovisionnement(en_alerte) == 99.0


# --- M6 : classement ------------------------------------------------------


def test_le_classement_va_de_la_plus_grosse_valeur_a_la_plus_petite():
    petit = article(reference="PETIT", quantite=1, prix_unitaire=1.0)
    gros = article(reference="GROS", quantite=10, prix_unitaire=100.0)
    moyen = article(reference="MOYEN", quantite=5, prix_unitaire=10.0)
    classes = classer_par_valeur([petit, gros, moyen])
    assert [a.reference for a in classes] == ["GROS", "MOYEN", "PETIT"]


def test_le_classement_ne_modifie_pas_la_liste_d_origine():
    origine = [article(reference="A", quantite=1), article(reference="B", quantite=9)]
    classer_par_valeur(origine)
    assert [a.reference for a in origine] == ["A", "B"]


# --- M7 : rotation --------------------------------------------------------


def test_la_rotation_donne_les_jours_de_stock_restants():
    # 60 en stock, 30 vendus sur 30 jours, soit 1 par jour
    assert rotation_en_jours(article(quantite=60), 30) == 60


def test_la_rotation_est_arrondie_a_l_entier_inferieur():
    # 10 en stock, 300 vendus sur 30 jours, soit 10 par jour, donc 1 jour
    assert rotation_en_jours(article(quantite=14), 300) == 1


def test_une_rotation_sans_vente_leve_une_erreur_explicite():
    with pytest.raises(AucuneVenteSurLaPeriode, match="aucune vente"):
        rotation_en_jours(article(), 0)


# --- ventilation ----------------------------------------------------------


def test_la_valeur_est_ventilee_par_categorie():
    articles = [
        article(categorie="outil", quantite=2, prix_unitaire=10.0),
        article(categorie="outil", quantite=1, prix_unitaire=5.0),
        article(categorie="piece", quantite=4, prix_unitaire=2.5),
    ]
    assert valeur_par_categorie(articles) == {"outil": 25.0, "piece": 10.0}


def test_une_categorie_inconnue_n_est_pas_perdue():
    assert valeur_par_categorie([article(categorie="drone", quantite=1, prix_unitaire=3.0)]) == {
        "drone": 3.0
    }


# --- M8 : rapport ---------------------------------------------------------


def test_le_rapport_utilise_la_date_fournie_et_jamais_l_horloge():
    rapport = generer_rapport([article()], date(2019, 3, 5))
    assert rapport.date_du_rapport == "2019-03-05"


def test_le_rapport_calcule_la_valeur_toutes_taxes():
    rapport = generer_rapport([article(quantite=10, prix_unitaire=10.0)], date(2026, 1, 1))
    assert rapport.valeur_hors_taxe == 100.0
    assert rapport.valeur_toutes_taxes == 120.0


def test_le_rapport_distingue_alerte_et_rupture():
    articles = [
        article(reference="VIDE", quantite=0, seuil_alerte=10),
        article(reference="BASSE", quantite=8, seuil_alerte=10),
        article(reference="OK", quantite=80, seuil_alerte=10),
    ]
    rapport = generer_rapport(articles, date(2026, 1, 1))
    assert rapport.references_en_alerte == ["VIDE", "BASSE"]
    assert rapport.references_en_rupture == ["VIDE"]


def test_le_rapport_ne_modifie_aucun_article():
    origine = article(quantite=50)
    generer_rapport([origine], date(2026, 1, 1))
    assert origine.quantite == 50


def test_le_rapport_formate_annonce_l_absence_d_alerte():
    rapport = generer_rapport([article(quantite=50, seuil_alerte=10)], date(2026, 1, 1))
    assert "aucune" in formater_rapport(rapport)
