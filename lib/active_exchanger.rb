module ActiveExchanger
  class Error < ::StandardError
  end

  class NotSupportedFormatError < Error
  end

  class NotWellFormedFileError < Error
  end

  class IncompatibleDataError < Error
  end

  class InvalidDataError < Error
  end
end

require 'active_exchanger/base'
require 'active_exchanger/supervisor'
require 'active_exchanger/csv_reader'
require 'active_exchanger/csv_parser'

# Le chargement de tous les exchangers — nécessaire pour que
# `ActiveExchanger::Base.find` les retrouve, puisqu'ils s'enregistrent par
# héritage — a lieu dans `config/initializers/exchangers.rb`.
#
# Il ne peut pas se faire ici : Zeitwerk résout la constante `ActiveExchanger`
# pendant son propre `setup`, en descendant `lib/active_exchanger/`, et tout
# chargement déclenché depuis ce fichier s'exécuterait donc avant que le
# chargeur soit prêt.
