# frozen_string_literal: true

module Ekylibre
  # Déprécieur de l'application.
  #
  # `Ekylibre.deprecator.warn` appelé sur la classe a disparu en Rails
  # 7.2 : chaque bibliothèque tient désormais son propre déprécieur, ce qui
  # permet de régler séparément le sort de ses avertissements — les taire, les
  # transformer en erreurs en test, les router ailleurs. Celui-ci est déclaré
  # dans `config.active_support.deprecators` par config/application.rb, d'où il
  # obéit à `config.active_support.report_deprecations` comme ceux du cadriciel.
  #
  # La version annoncée est celle où les API dépréciées seront retirées.
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new('7.0', 'Ekylibre')
  end
end
