# frozen_string_literal: true

# Les exchangers s'enregistrent par héritage : `ActiveExchanger::Base.find` ne
# retrouve que ceux qui ont été chargés. Il faut donc les charger tous.
#
# `eager_load_dir` laisse Zeitwerk résoudre les dépendances entre fichiers,
# là où le glob + `require_dependency` d'origine les chargeait dans l'ordre du
# système de fichiers — `Agroedi::DaplosExchanger::Input` hérite d'une classe
# soeur qui n'était alors pas encore définie.
#
# `to_prepare` parce que Rails 7 n'installe le chargeur principal que dans le
# *finisher*, après les initialiseurs.
Rails.application.config.to_prepare do
  Rails.autoloaders.main.eager_load_dir(Rails.root.join('app', 'exchangers'))
end
