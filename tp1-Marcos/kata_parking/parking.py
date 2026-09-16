import math


def calculer_montant(entree, sortie):
    duree = sortie - entree
    minutes = duree.total_seconds() / 60

    if minutes <= 30:
        return 0

    minutes_facturables = minutes - 30
    demi_heures = math.ceil(minutes_facturables / 30)
    return demi_heures * 1.50