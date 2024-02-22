# Emprunt

{:.alert .alert-success}
<i />{:.icon .icon-book} [**emprunts**](https://doc.ekylibre.com/fr/chapitre5/#emprunts){:target="_blank"}

## Informations générales

**Activité** = Vous pouvez affecté cet emprunt à une activité si il concerne uniquement cette activité

{:.alert .alert-success}
Ex : Emprunt pour un robot de traite, un batiment vollaile...

**Trésorerie** = Le compte bancaire lié au versement et au remboursement de cet emprunt.

**Préteur** = Le tiers qui prete l'argent (le plus souvent la banque)

## Délai

**Date de déblocage des fonds** = La date où l'argent est versé sur votre compte.

**Date de la première échéance** = La date où l'emprunt commence.

## Comptabilité

**Compte comptable des emprunts** = En général, 164X.

**Compte comptable des intérêts** = En général, 661X.

**Compte comptable ADI** = Le compte utilisé pour l'assurance deces invalidité. En général, 616X ou 618X.

**Déblocage initial du montant emprunté** = Est ce que le montant de l'emprunt est débloqué, c-a-d, est ce que l'argent doit être versé sur le compte de trésorerie. Si votre emprunt est **dans le passé**, il ne faut **pas cocher cette case**.

{:.alert .alert-warning}
Si cette case **est cochée**, cela **generera une écriture comptable** entre le compte 154X et le compte de trésorerie 512X.

**Date de début de prise en compte des échéances** = Date à partir de laquelle, on va prendre en compte les échéances.

{:.alert .alert-warning}
Si votre **emprunt est dans le passé**, il faut mentionner une **date comprise** dans les **exercices comtpables ouverts**.

{:.alert .alert-success}
Ex : Emprunt pour un batiment fait le 15/05/2020. Exercice ouvert 01/01/2023 et 01/01/2024. Date de début de prise en compte des échéances = 01/01/2023

Ekylibre va calculer les échéances à partir du 15/05/2020 et va vérouiller les échéances entre le 15/05/2020 et 15/12/2022.
Ekylibre va laisser actives et modifiables les échéanes à partir du 15/01/2023 et pourra les passer en comptabilité.

## Garanties bancaires

Si vous utiliser une **caution bancaire**, vous pouvez mentionner le **compte comptable** utilisé (en général 275X) pour la caution avec le montant.