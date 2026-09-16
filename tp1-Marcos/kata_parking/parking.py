import math

PLAFOND_24H = 18


def calculer_montant(entree, sortie):
    duree = sortie - entree
    minutes = duree.total_seconds() / 60

    if minutes <= 30:
        return 0

    minutes_facturables = minutes - 30
    demi_heures = math.ceil(minutes_facturables / 30)
    montant = demi_heures * 1.50

    return min(montant, PLAFOND_24H)