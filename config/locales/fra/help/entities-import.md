# Comment importer des tiers ? 

Une importation permet d'**ajouter** de nouvelles fiches sans modifier les fiches existantes. Il est possible de récupérer seulement les informations de description des tiers (Il n'est pas possible de récupérer un historique de ventes, évènements...).
L'importation se passe en trois étapes.

## Sélection du fichier 
Avant de sélectionner votre fichier, pensez bien à utiliser le bon format :

* La première ligne du fichier ne sera jamais utilisée car elle contient les titres de colonnes.
* Une colonne correspondant au nom de la personne doit toujours être présente

{:.alert .alert-warning}
Le format CSV doit être un format _propre_. Pour cette raison, il est recommandé d'utiliser _OpenOffice_ qui permet de produire ce type de document.

## Correspondance des colonnes 
Cette étape permet de faire correspondre chaque colonne du tableau importé à une donnée dans _Ekylibre_.

## Validation et importation 
Une fois la correspondance effectuée, l'intégralité du fichier est testée avant d'être importée. À la suite un rapport est émis en cas d'erreur. Suivant les problèmes, vous serez amené à les corriger dans votre fichier et à recommencer la procédure.

{:.alert .alert-warning}
Cette opération peut être longue si votre fichier est important. Attendez avant de rafraichir la page trop vite.

