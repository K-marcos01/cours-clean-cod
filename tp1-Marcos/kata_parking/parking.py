import math

MINUTES_PAR_DEMI_HEURE = 30
TARIF_DEMI_HEURE = 1.50
PLAFOND_24H = 18
MINUTES_PAR_JOUR = 24 * 60
REMISE_ABONNE = 0.60
FRANCHISE_NORMALE = 30
FRANCHISE_ELECTRIQUE = 60


def calculer_montant(entree, sortie, abonne=False, electrique=False):
    duree = sortie - entree
    minutes = duree.total_seconds() / 60

    franchise = FRANCHISE_ELECTRIQUE if electrique else FRANCHISE_NORMALE

    if minutes <= franchise:
        return 0

    minutes_facturables = minutes - franchise
    demi_heures = math.ceil(minutes_facturables / MINUTES_PAR_DEMI_HEURE)
    montant = demi_heures * TARIF_DEMI_HEURE

    tranches_de_24h = math.ceil(minutes / MINUTES_PAR_JOUR)
    plafond = PLAFOND_24H * tranches_de_24h
    montant = min(montant, plafond)

    if abonne:
        montant = montant * REMISE_ABONNE

    return round(montant, 2)