import math

MINUTES_PAR_DEMI_HEURE = 30
TARIF_DEMI_HEURE = 1.50
PLAFOND_24H = 18
MINUTES_PAR_JOUR = 24 * 60
REMISE_ABONNE = 0.60
FRANCHISE_NORMALE = 30
FRANCHISE_ELECTRIQUE = 60
FOURRIERE_SEUIL_HEURES = 72
FOURRIERE_FORFAIT = 250


def _resoudre_sortie(sortie, maintenant):
    if sortie is None:
        return maintenant
    return sortie


def _valider_dates(entree, sortie):
    if sortie < entree:
        raise ValueError(
            "l'heure de sortie ne peut pas etre anterieure a l'heure d'entree"
        )


def _est_en_fourriere(minutes):
    return minutes > FOURRIERE_SEUIL_HEURES * 60


def _calculer_franchise(electrique):
    if electrique:
        return FRANCHISE_ELECTRIQUE
    return FRANCHISE_NORMALE


def _calculer_tarif_normal(minutes, franchise):
    if minutes <= franchise:
        return 0
    minutes_facturables = minutes - franchise
    demi_heures = math.ceil(minutes_facturables / MINUTES_PAR_DEMI_HEURE)
    return demi_heures * TARIF_DEMI_HEURE


def _appliquer_plafond(montant, minutes):
    tranches_de_24h = math.ceil(minutes / MINUTES_PAR_JOUR)
    plafond = PLAFOND_24H * tranches_de_24h
    return min(montant, plafond)


def _appliquer_remise_abonne(montant, abonne):
    if abonne:
        return montant * REMISE_ABONNE
    return montant


def calculer_montant(entree, sortie=None, abonne=False, electrique=False, maintenant=None):
    sortie = _resoudre_sortie(sortie, maintenant)
    _valider_dates(entree, sortie)

    minutes = (sortie - entree).total_seconds() / 60

    if _est_en_fourriere(minutes):
        return FOURRIERE_FORFAIT

    franchise = _calculer_franchise(electrique)
    montant = _calculer_tarif_normal(minutes, franchise)
    montant = _appliquer_plafond(montant, minutes)
    montant = _appliquer_remise_abonne(montant, abonne)

    return round(montant, 2)