# Gabarits ODT générés

Ces spécifications décrivent les gabarits `.odt` **provisoires** produits par
`bin/generate_odt_template.rb` lors de la sortie de Jasper (lot A.4).

Elles ne portent aucune mise en forme : uniquement les emplacements que la
classe `Printers::*` correspondante alimente. Le fichier `.odt` engendré est
destiné à être rouvert dans LibreOffice et mis en page par un designer.

Trois éléments doivent survivre à cette mise en page, sans quoi ODFReport ne
retrouve plus ses repères :

- un champ scalaire est le texte littéral `[NOM_DU_CHAMP]` ;
- un bloc répété est un tableau dont le `table:name` correspond à l'appel
  `add_table` du printer ;
- la première ligne de ce tableau est l'en-tête, la seconde porte les
  emplacements `[COLONNE]` et sera dupliquée par enregistrement.

Régénérer un gabarit (écrase la mise en page) :

    bundle exec ruby bin/generate_odt_template.rb \
      config/locales/fra/reporting/<nature>.odt \
      config/reporting/odt_specs/<nature>.json
