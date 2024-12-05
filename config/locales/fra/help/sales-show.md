# Consultation d'une vente

## Impression

un modele de facture est disponible par défault mais vous pouvez [ajouter vos propres modèles](/backend/document-templates)

## Envoi par email au client

3 modèles sont [disponibles et modifiables](/backend/email-templates) (**envoi devis**, **envoie facture** et **envoie relance facture**)

La piece jointe à l'email correspond au **dernier document imprimé** sur la vente.Si aucun document n'a été imprimé, on imprimera le document coché **par défault** dans les [modèles de document](/backend/document-templates).

Si le délais de paiement (30 jours par défault) est dépassé, le systeme utilisera automatiquement le modèle d'email **envoie relance facture**.

## Dupliquer

Vous pouvez dupliquer une vente pour gagner du temps, il vous restera à modifier les lignes et la date.

## Faire un avoir

{:.alert .alert-warning}
Vous ne pouvez pas supprimer une vente avec le statut **facture**, il faut faire un avoir.

## Affaire

- Vous pouvez ajouter un encaissement (le montant du solde sera pré-remplie)

- Ajouter une autre vente dans la même **affaire** pour encaisser un réglement sur 2 ventes en même temps.

- Passer le solde en perte quand vous avez une différence de quelques centimes.

- Ajouter une régularisation (OD comptable)

