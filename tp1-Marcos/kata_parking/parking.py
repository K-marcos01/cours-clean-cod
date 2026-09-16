import math

MINUTES_PAR_DEMI_HEURE = 30
TARIF_DEMI_HEURE = 1.50
PLAFOND_24H = 18
MINUTES_PAR_JOUR = 24 * 60


def calculer_montant(entree, sortie):
    duree = sortie - entree
    minutes = duree.total_seconds() / 60

    if minutes <= 30:
        return 0

    minutes_facturables = minutes - 30
    demi_heures = math.ceil(minutes_facturables / MINUTES_PAR_DEMI_HEURE)
    montant = demi_heures * TARIF_DEMI_HEURE

    tranches_de_24h = math.ceil(minutes / MINUTES_PAR_JOUR)
    plafond = PLAFOND_24H * tranches_de_24h

    return min(montant, plafond)