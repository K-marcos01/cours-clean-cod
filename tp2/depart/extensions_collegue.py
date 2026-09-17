# -*- coding: utf-8 -*-
"""Extensions ajoutees en 2023 par le remplacant de Kevin.

Ce fichier n'a jamais ete relu et n'a aucun test. Il est fourni tel quel.
Il est volontairement autonome : il ne depend pas de ton decoupage du TP2.

Le contrat de la classe de base est ecrit dans sa docstring. C'est ce contrat
que tes tests doivent verifier, sur la classe de base et sur chacun des
sous-types, avec la meme suite de tests.
"""


class QuantiteInvalide(ValueError):
    """La quantite demandee est nulle ou negative."""


class StockInsuffisant(ValueError):
    """Le retrait demande depasse le stock disponible."""


class OperationInterdite(RuntimeError):
    """L'operation n'est pas autorisee sur ce stock."""


class StockArticle:
    """Le stock d'un article et ses mouvements.

    Contrat de `retirer` :
      - retire exactement la quantite demandee
      - renvoie la quantite restante
      - leve QuantiteInvalide si la quantite est nulle ou negative
      - leve StockInsuffisant si la quantite demandee depasse le stock
      - ne leve aucune autre exception
      - toute quantite comprise entre 1 et le stock disponible est acceptee

    Contrat de `ajouter` :
      - ajoute exactement la quantite demandee
      - renvoie la quantite resultante
      - leve QuantiteInvalide si la quantite est nulle ou negative
      - ne leve aucune autre exception
    """

    def __init__(self, reference: str, quantite: int) -> None:
        self.reference = reference
        self._quantite = quantite

    @property
    def quantite(self) -> int:
        return self._quantite

    def retirer(self, quantite: int) -> int:
        if quantite <= 0:
            raise QuantiteInvalide(f"quantite invalide : {quantite}")
        if quantite > self._quantite:
            raise StockInsuffisant(
                f"{self.reference} : {quantite} demandes, {self._quantite} disponibles"
            )
        self._quantite -= quantite
        return self._quantite

    def ajouter(self, quantite: int) -> int:
        if quantite <= 0:
            raise QuantiteInvalide(f"quantite invalide : {quantite}")
        self._quantite += quantite
        return self._quantite


class StockAvecConsigne(StockArticle):
    """Stock d'un article dont l'emballage est consigne."""

    def __init__(self, reference: str, quantite: int, consigne_unitaire: float) -> None:
        super().__init__(reference, quantite)
        self.consigne_unitaire = consigne_unitaire

    def montant_de_consigne(self) -> float:
        return round(self.quantite * self.consigne_unitaire, 2)


class StockEnDepotVente(StockArticle):
    """Stock confie par un fournisseur.

    Regle du fournisseur : on ne sort jamais plus de la moitie du stock d'un coup.
    """

    def retirer(self, quantite: int) -> int:
        if quantite > self._quantite / 2:
            raise StockInsuffisant(
                f"{self.reference} : depot-vente, la moitie du stock au maximum"
            )
        return super().retirer(quantite)


class StockArchive(StockArticle):
    """Stock gele apres inventaire annuel. On consulte, on ne bouge plus rien."""

    def retirer(self, quantite: int) -> int:
        raise OperationInterdite(f"{self.reference} : stock archive")

    def ajouter(self, quantite: int) -> int:
        raise OperationInterdite(f"{self.reference} : stock archive")
