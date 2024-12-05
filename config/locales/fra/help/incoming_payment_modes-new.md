# Modes d'encaissement 

Vous devez choisir une trésorerie liée à votre mode d'encaissement.

## Remise en banque 

Si votre mode d'encaissement correspond a du **liquide** ou des **chéques**, vous pouvez utiliser un compte d'attente et un journal à part.

{:.alert .alert-warning}
En général, les comptes associés sont différents pour chaque mode :

* Espèces : _5111. Espèces à encaisser_
* Chèques : _5112. Chèques à encaisser_
* Carte bancaire : _5115. Cartes bancaires à encaisser_

## Commission

Si vous avez des commerciaux ou des intermédiaires qui prennent une commission sur vos ventes, vous pouvez paramétrer une commission automatique avec un **montant fixe** et/ou **un pourcentage** lors de chaque encaissement avec un compte particulier (généralement _622XXXXX_)

{:.alert .alert-success}

Lors de l'enregistrement de l'encaissement, le total va etre recalculé comme dans l'exemple ci-dessous.

Le mode de paiement a été paramétré avec un **montant fixe** de **0 €** et un **pourcentage** de **5 %**.

L'écriture comptable générée sera :

| Compte |   D   |   C   |
| 411XX  |       |  100  |
| 511XX  |   95  |       |
| 622XX  |   5   |       |
