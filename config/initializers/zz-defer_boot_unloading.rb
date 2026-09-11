# frozen_string_literal: true

# Report explicite d'un changement de Rails 6.1 — ce n'est pas un correctif.
#
# Rails 6.1 a ajouté l'initialiseur `:warn_if_autoloaded` : si une constante
# autochargeable a été chargée pendant l'initialisation, il avertit et, en mode
# Zeitwerk, **décharge tout le lot**. L'intention est saine — du code chargé au
# démarrage ne se recharge pas, et garder l'objet périmé masque les
# modifications — mais Ekylibre charge beaucoup de bibliothèques applicatives
# au démarrage : `config/initializers/20-start.rb` pour `Userstamp`,
# `ActionIntegration`, `Measure`, `WorkingSet`, et chaque engine de plugin pour
# son intégration. Rails en dénombre environ soixante-dix.
#
# Celles que Zeitwerk gère reviennent d'elles-mêmes ; celles qui viennent d'un
# `require` ne reviennent jamais, `require` ne se rejouant pas. L'application ne
# démarre donc plus du tout en développement — en test, `cache_classes` étant
# vrai, l'initialiseur de Rails ne s'exécute pas et rien ne se voit.
#
# Vider la liste rétablit le comportement de Rails 6.0 : aucun déchargement,
# aucun avertissement. Le vrai travail — faire que l'initialisation n'autocharge
# plus de code applicatif, en déplaçant ce qui doit l'être dans
# `Rails.application.reloader.to_prepare` — reste à faire, et devra l'être avant
# Rails 7 : le message annonce une erreur dure dans une version future.
#
# Retirer ce fichier fait réapparaître le diagnostic complet de Rails, avec la
# liste nominative des constantes à traiter.
ActiveSupport::Dependencies.autoloaded_constants.clear unless Rails.env.test?
